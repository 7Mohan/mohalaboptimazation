package com.mohalab.optimization

import android.app.Activity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import rikka.shizuku.Shizuku
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/** Result of a privileged shell command. */
internal data class ExecResult(val exitCode: Int, val stdout: String, val stderr: String) {
    val ok: Boolean get() = exitCode == 0

    /** Best human-readable failure reason, falling back to [default]. */
    fun errorText(default: String): String =
        stderr.trim().ifEmpty { stdout.trim() }.lineSequence().firstOrNull()?.take(160)
            ?.takeIf { it.isNotBlank() } ?: default
}

/**
 * MethodChannel bridge between Flutter and the Shizuku native layer.
 *
 * Channel name: com.mohalab.optimization/shizuku
 *
 * Exposed methods (Flutter → Android):
 *   getStatus()          → String  (one of ShizukuStateDetector constants)
 *   checkPermission()    → Boolean
 *   isReady()            → Boolean
 *   requestPermission()  → Boolean (resolves after user interacts with dialog)
 *
 * There is deliberately no "run arbitrary command" method on the channel.
 * Privileged commands are built only inside [TweakEngine] from whitelisted
 * templates and validated arguments.
 */
internal class ShizukuBridge(
    private val activity: Activity,
    flutterEngine: FlutterEngine,
) {
    companion object {
        const val CHANNEL = "com.mohalab.optimization/shizuku"
        private const val TIMEOUT_MINUTES = 10L
    }

    private val detector = ShizukuStateDetector(activity)
    private val permissionHandler = ShizukuPermissionHandler()
    private val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

    /** Invoked (on a binder thread) whenever Shizuku becomes usable. */
    var onReady: (() -> Unit)? = null

    private val binderReceivedListener = Shizuku.OnBinderReceivedListener {
        if (detector.isReady()) onReady?.invoke()
    }

    private val binderDeadListener = Shizuku.OnBinderDeadListener {
        // State is re-queried by Flutter on resume; nothing to cache here.
    }

    fun isReady(): Boolean = detector.isReady()

    /** Uid the Shizuku server runs as: 0 = root, 2000 = adb shell, -1 = unknown. */
    fun serverUid(): Int = if (isReady()) runCatching { Shizuku.getUid() }.getOrDefault(-1) else -1

    /**
     * Executes a shell command synchronously with Shizuku privileges.
     * Must be called from a background thread. stdout and stderr are drained
     * concurrently so a chatty command can never dead-lock on a full pipe.
     */
    fun exec(command: String): ExecResult {
        if (!detector.isReady()) return ExecResult(-1, "", "Shizuku not ready")
        return try {
            @Suppress("DEPRECATION")
            val process = Shizuku.newProcess(arrayOf("sh", "-c", command), null, null)
            // Shizuku's remote process only reliably supports the blocking
            // waitFor() — waitFor(timeout)/exitValue() can misreport success
            // as failure. A watchdog enforces the timeout instead.
            val finished = CountDownLatch(1)
            var timedOut = false
            Thread {
                if (!finished.await(TIMEOUT_MINUTES, TimeUnit.MINUTES)) {
                    timedOut = true
                    runCatching { process.destroy() }
                }
            }.apply { isDaemon = true }.start()

            var stderr = ""
            val errThread = Thread { stderr = runCatching { process.errorStream.bufferedReader().use { it.readText() } }.getOrDefault("") }
            errThread.start()
            val stdout = runCatching { process.inputStream.bufferedReader().use { it.readText() } }.getOrDefault("")
            val code = process.waitFor()
            finished.countDown()
            errThread.join(2000)
            if (timedOut) ExecResult(-1, stdout, "Timed out") else ExecResult(code, stdout, stderr)
        } catch (e: Exception) {
            ExecResult(-1, "", e.message ?: "Execution failed")
        }
    }

    /** Call once when FlutterEngine is configured. */
    fun register() {
        permissionHandler.register()

        try {
            Shizuku.addBinderReceivedListenerSticky(binderReceivedListener)
            Shizuku.addBinderDeadListener(binderDeadListener)
        } catch (e: Exception) {
            // Shizuku not available — safe to ignore
        }

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getStatus" -> result.success(detector.detectState())
                "checkPermission" -> result.success(detector.hasPermission())
                "isReady" -> result.success(detector.isReady())
                "requestPermission" -> {
                    val binderAlive = try { Shizuku.pingBinder() } catch (e: Exception) { false }
                    if (!binderAlive) {
                        result.success(false)
                        return@setMethodCallHandler
                    }
                    permissionHandler.requestPermission { granted ->
                        if (granted) onReady?.invoke()
                        activity.runOnUiThread {
                            try {
                                result.success(granted)
                            } catch (e: Exception) {
                                // result already resolved
                            }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    /** Call in Activity onDestroy to prevent listener leaks. */
    fun unregister() {
        permissionHandler.unregister()

        try {
            Shizuku.removeBinderReceivedListener(binderReceivedListener)
            Shizuku.removeBinderDeadListener(binderDeadListener)
        } catch (e: Exception) {
            // Already detached
        }

        channel.setMethodCallHandler(null)
    }
}
