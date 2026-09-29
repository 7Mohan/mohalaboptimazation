package com.mohalab.optimization

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader
import java.io.OutputStreamWriter
import java.util.concurrent.TimeUnit

/**
 * Root access through Magisk, KernelSU or APatch.
 *
 * The first `su` call makes the root manager show its grant prompt. After
 * that one persistent root shell is reused for every command, so managers
 * don't pop a toast for each tweak. Commands are built only by [TweakEngine]
 * from fixed templates — nothing user-typed ever reaches this shell.
 */
internal class RootShell(private val context: Context) {

    private var process: Process? = null
    private var writer: OutputStreamWriter? = null
    private var reader: BufferedReader? = null
    private val lock = Any()

    @Volatile var granted: Boolean = false
        private set

    // ── Detection ──────────────────────────────────────────────────────────

    private val suPaths = listOf(
        "/system/bin/su", "/system/xbin/su", "/sbin/su", "/su/bin/su",
        "/debug_ramdisk/su", "/data/adb/ksu/bin/su", "/data/adb/ap/bin/su",
    )

    private fun installed(pkg: String): Boolean = try {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.packageManager.getPackageInfo(pkg, PackageManager.PackageInfoFlags.of(0))
        } else {
            @Suppress("DEPRECATION")
            context.packageManager.getPackageInfo(pkg, 0)
        }
        true
    } catch (e: Exception) {
        false
    }

    /** Root manager app on the device, or null. */
    fun manager(): String? = when {
        installed("me.weishu.kernelsu") -> "KernelSU"
        installed("com.rifsxd.ksunext") -> "KernelSU Next"
        installed("me.bmax.apatch") -> "APatch"
        installed("com.topjohnwu.magisk") -> "Magisk"
        installed("io.github.huskydg.magisk") -> "Kitsune Magisk"
        else -> null
    }

    /** True when an `su` binary is reachable (the manager may still deny). */
    fun available(): Boolean {
        if (suPaths.any { File(it).exists() }) return true
        val path = System.getenv("PATH") ?: return manager() != null
        return path.split(':').any { File(it, "su").exists() } || manager() != null
    }

    // ── Session ────────────────────────────────────────────────────────────

    /**
     * Opens the root shell. Shows the manager's grant dialog the first time;
     * blocks (off the UI thread) until the user answers or [timeoutSec] passes.
     */
    fun request(timeoutSec: Long = 30): Boolean = synchronized(lock) {
        if (granted && process?.isAlive == true) return true
        close()
        try {
            val p = ProcessBuilder("su").redirectErrorStream(true).start()
            process = p
            writer = OutputStreamWriter(p.outputStream)
            reader = BufferedReader(InputStreamReader(p.inputStream))
            val probe = runLocked("id -u", timeoutSec)
            granted = probe?.first == 0 && probe.second.trim().lines().lastOrNull()?.trim() == "0"
            if (!granted) close()
        } catch (e: Exception) {
            granted = false
            close()
        }
        granted
    }

    /** Runs [command] as root; exit code -1 when root isn't available. */
    fun exec(command: String, timeoutSec: Long = 600): ExecResult = synchronized(lock) {
        if (!granted || process?.isAlive != true) {
            if (!request()) return ExecResult(-1, "", "Root not granted")
        }
        val r = runLocked(command, timeoutSec) ?: return ExecResult(-1, "", "Root shell timed out")
        ExecResult(r.first, r.second, if (r.first == 0) "" else r.second)
    }

    private val marker = "__MOHA_END__"

    /** Writes a command and reads output up to our end marker. Caller holds [lock]. */
    private fun runLocked(command: String, timeoutSec: Long): Pair<Int, String>? {
        val w = writer ?: return null
        val r = reader ?: return null
        return try {
            w.write("$command 2>&1\necho \"$marker\$?\"\n")
            w.flush()
            val out = StringBuilder()
            val deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(timeoutSec)
            while (System.nanoTime() < deadline) {
                val line = r.readLine() ?: return null
                val idx = line.indexOf(marker)
                if (idx >= 0) {
                    if (idx > 0) out.append(line, 0, idx).append('\n')
                    val code = line.substring(idx + marker.length).trim().toIntOrNull() ?: -1
                    return code to out.toString()
                }
                out.append(line).append('\n')
            }
            null
        } catch (e: Exception) {
            granted = false
            null
        }
    }

    fun close() {
        runCatching { writer?.write("exit\n"); writer?.flush() }
        runCatching { process?.destroy() }
        process = null
        writer = null
        reader = null
    }
}
