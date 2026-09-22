package com.mohalab.optimization

import android.app.Activity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import rikka.shizuku.Shizuku

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
 *   execShellCommand(command) → Map { success: Boolean, exitCode: Int, stdout: String, stderr: String }
 */
internal class ShizukuBridge(
    private val activity: Activity,
    flutterEngine: FlutterEngine,
) {
    companion object {
        const val CHANNEL = "com.mohalab.optimization/shizuku"
    }

    private val detector = ShizukuStateDetector(activity)
    private val permissionHandler = ShizukuPermissionHandler()
    private val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

    private val binderReceivedListener = Shizuku.OnBinderReceivedListener {
        // Binder connected
    }

    private val binderDeadListener = Shizuku.OnBinderDeadListener {
        // Binder died
    }

    fun isReady(): Boolean = detector.isReady()

    /**
     * Executes a shell command synchronously with Shizuku privileges.
     * Must be called from a background thread.
     */
    fun executeShell(command: String): Pair<Boolean, String> {
        if (!detector.isReady()) return Pair(false, "Shizuku not ready")
        return try {
            @Suppress("DEPRECATION")
            val process = Shizuku.newProcess(arrayOf("sh", "-c", command), null, null)
            val stdout = process.inputStream.bufferedReader().use { it.readText() }
            val exitCode = process.waitFor()
            process.destroy()
            Pair(exitCode == 0, stdout)
        } catch (e: Exception) {
            Pair(false, e.message ?: "Execution failed")
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
                "getStatus" -> {
                    result.success(detector.detectState())
                }

                "checkPermission" -> {
                    result.success(detector.hasPermission())
                }

                "isReady" -> {
                    result.success(detector.isReady())
                }

                "requestPermission" -> {
                    val binderAlive = try { Shizuku.pingBinder() } catch (e: Exception) { false }
                    if (!binderAlive) {
                        result.success(false)
                        return@setMethodCallHandler
                    }
                    permissionHandler.requestPermission { granted ->
                        activity.runOnUiThread {
                            try {
                                result.success(granted)
                            } catch (e: Exception) {
                                // result already resolved
                            }
                        }
                    }
                }

                "execShellCommand" -> {
                    val command = call.argument<String>("command")
                    if (command.isNullOrBlank()) {
                        result.error("INVALID_COMMAND", "Command cannot be empty", null)
                        return@setMethodCallHandler
                    }

                    if (!detector.isReady()) {
                        result.error(
                            "SHIZUKU_NOT_READY",
                            "Shizuku service is not active or permission not granted",
                            null
                        )
                        return@setMethodCallHandler
                    }

                    Thread {
                        try {
                            @Suppress("DEPRECATION")
                            val process = Shizuku.newProcess(
                                arrayOf("sh", "-c", command), null, null
                            )
                            val stdout = process.inputStream.bufferedReader().use { it.readText() }
                            val stderr = process.errorStream.bufferedReader().use { it.readText() }
                            val exitCode = process.waitFor()
                            process.destroy()

                            activity.runOnUiThread {
                                result.success(
                                    mapOf(
                                        "success" to (exitCode == 0),
                                        "exitCode" to exitCode,
                                        "stdout" to stdout,
                                        "stderr" to stderr,
                                    )
                                )
                            }
                        } catch (e: Exception) {
                            activity.runOnUiThread {
                                result.error("EXEC_FAILED", e.message, null)
                            }
                        }
                    }.start()
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
