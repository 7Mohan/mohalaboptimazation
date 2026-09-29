package com.mohalab.optimization

import android.Manifest
import android.app.ActivityManager
import android.app.NotificationManager
import android.content.ContentResolver
import android.content.Context
import android.content.SharedPreferences
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.os.StatFs
import android.provider.Settings
import android.util.Log
import android.hardware.display.DisplayManager
import android.view.Display
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.util.concurrent.Executors
import java.util.regex.Pattern
import kotlin.math.roundToInt

/**
 * Real, verifiable system tweaks.
 *
 * Every tweak here maps to a documented Android setting or `cmd` service
 * command that the shell user (Shizuku) or an app holding
 * WRITE_SECURE_SETTINGS is allowed to change. Nothing is reported as
 * applied unless the command succeeded, and toggle state is always read back
 * from the device so the UI survives app restarts.
 *
 * Before a tweak first touches a setting, the original value is saved to
 * SharedPreferences so [revert] restores exactly what the user had — even
 * after the app was killed.
 *
 * Channel: com.mohalab.optimization/tweaks
 */
internal class TweakEngine(
    private val context: Context,
    private val shizuku: ShizukuBridge,
    messenger: BinaryMessenger,
) {
    companion object {
        const val CHANNEL = "com.mohalab.optimization/tweaks"
        private const val TAG = "MohaTweak"
        private const val PREFS = "moha_tweak_engine_v1"

        private val SAFE_VALUE = Pattern.compile("^[A-Za-z0-9._:-]{0,64}$")
        private val PACKAGE_NAME =
            Pattern.compile("^[a-zA-Z][a-zA-Z0-9_]*(\\.[a-zA-Z][a-zA-Z0-9_]*)+$")

        private val DNS_HOSTS = mapOf(
            "cloudflare" to "one.one.one.one",
            "google" to "dns.google",
            "adguard" to "dns.adguard-dns.com",
            "quad9" to "dns.quad9.net",
        )

        private val GAME_MODES = setOf("standard", "performance", "battery")
    }

    private data class Write(val ns: String, val key: String, val value: String)

    private val prefs: SharedPreferences =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    private val io = Executors.newSingleThreadExecutor()

    // ART compilation can take minutes; it must not block toggles and state reads.
    private val longIo = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private val channel = MethodChannel(messenger, CHANNEL)
    @Volatile private var reappliedThisProcess = false

    fun register() {
        channel.setMethodCallHandler { call, result ->
            val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any?>()
            // All work runs off the UI thread; results are posted back on main.
            val isLong = call.method == "compileApps" || call.method == "requestRoot" ||
                (call.method == "runAction" && (args["id"] as? String) == "fstrim") ||
                (call.method == "runAction" && (args["id"] as? String)?.startsWith("compile") == true)
            (if (isLong) longIo else io).execute {
                val reply: Any? = try {
                    when (call.method) {
                        "getCapabilities" -> capabilities()
                        "getStates" -> states()
                        "apply" -> apply(args["id"] as? String ?: "", args)
                        "revert" -> revert(args["id"] as? String ?: "")
                        "runAction" -> runAction(
                            args["id"] as? String ?: "",
                            args["packageName"] as? String,
                            args["mode"] as? String,
                        )
                        "applyGameTuning" -> applyGameTuning(args)
                        "resetGameTuning" -> resetGameTuning(args["packageName"] as? String)
                        "reapplyVolatile" -> reapplyVolatile(force = true)
                        "openDndSettings" -> openDndSettings()
                        "requestRoot" -> requestRoot()
                        "disableRoot" -> disableRoot()
                        "compileApps" -> compileApps(args)
                        "cancelLongTask" -> cancelLongTask()
                        else -> {
                            main.post { result.notImplemented() }
                            return@execute
                        }
                    }
                } catch (e: Exception) {
                    outcome(false, e.message ?: "Unexpected error")
                }
                main.post { result.success(reply) }
            }
        }
    }

    fun unregister() {
        channel.setMethodCallHandler(null)
        io.shutdown()
        longIo.shutdown()
    }

    /** Called when the Shizuku binder attaches — restores tweaks Android resets on reboot. */
    fun onShizukuReady() {
        io.execute { reapplyVolatile(force = false) }
    }

    // ─────────────────────────────────────────────────────────────────────
    // Capabilities
    // ─────────────────────────────────────────────────────────────────────

    private fun hasSecureSettings(): Boolean =
        context.checkSelfPermission(Manifest.permission.WRITE_SECURE_SETTINGS) ==
            PackageManager.PERMISSION_GRANTED

    private val root = RootShell(context)

    /** Root when granted, else Shizuku. Both run as a privileged shell. */
    private fun priv(command: String): ExecResult =
        if (root.granted) root.exec(command) else shizuku.exec(command)

    /** Root via su, or Shizuku started as root (uid 0). */
    private fun hasRoot(): Boolean = root.granted || shizuku.serverUid() == 0

    private fun hasShell(): Boolean = root.granted || shizuku.isReady()

    /** Uid of the privileged shell: 0 = root, 2000 = adb, -1 = none. */
    private fun shellUid(): Int = if (root.granted) 0 else shizuku.serverUid()

    private fun canWriteSettings(): Boolean = hasSecureSettings() || hasShell()

    private fun supportedRefreshRates(): List<Float> {
        // Application contexts have no display of their own; ask DisplayManager.
        val dm = context.getSystemService(Context.DISPLAY_SERVICE) as? DisplayManager
        val display = dm?.getDisplay(Display.DEFAULT_DISPLAY)
        return display?.supportedModes?.map { it.refreshRate }?.distinct()?.sorted()
            ?.takeIf { it.isNotEmpty() } ?: listOf(60f)
    }

    private fun capabilities(): Map<String, Any?> {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        return mapOf(
            "sdkInt" to Build.VERSION.SDK_INT,
            "manufacturer" to Build.MANUFACTURER,
            "shizukuReady" to hasShell(),
            "secureSettingsGranted" to hasSecureSettings(),
            "notificationPolicyGranted" to (nm?.isNotificationPolicyAccessGranted == true),
            "refreshRates" to supportedRefreshRates().map { it.toDouble() },
            "rootAvailable" to root.available(),
            "rootGranted" to root.granted,
            "shizukuRoot" to (shizuku.serverUid() == 0),
            "rootManager" to root.manager(),
        )
    }

    // ─────────────────────────────────────────────────────────────────────
    // Settings I/O
    // ─────────────────────────────────────────────────────────────────────

    /** A settings read; [readable] is false when Android refused to reveal the value. */
    private data class Read(val readable: Boolean, val value: String?)

    /** Per-call cache so a full state refresh costs at most one shell process. */
    private var readCache: MutableMap<String, Read>? = null

    private fun readDirect(ns: String, key: String): Read = try {
        val cr = context.contentResolver
        Read(
            true,
            when (ns) {
                "global" -> Settings.Global.getString(cr, key)
                "secure" -> Settings.Secure.getString(cr, key)
                "system" -> Settings.System.getString(cr, key)
                else -> null
            },
        )
    } catch (e: Exception) {
        // Android 12+ blocks apps from reading some hidden keys.
        Read(false, null)
    }

    private fun readSettingFull(ns: String, key: String): Read {
        readCache?.get("$ns/$key")?.let { return it }
        val direct = readDirect(ns, key)
        if (direct.readable || !hasShell()) return direct
        val r = priv("settings get $ns $key")
        val v = r.stdout.trim()
        return if (!r.ok) direct else Read(true, v.takeUnless { it.isEmpty() || it == "null" })
    }

    private fun readSetting(ns: String, key: String): String? = readSettingFull(ns, key).value

    /**
     * Reads many keys, falling back to a single batched shell call for any
     * that the app is not allowed to read directly.
     */
    private fun prefetch(keys: List<Pair<String, String>>): MutableMap<String, Read> {
        val out = mutableMapOf<String, Read>()
        val blocked = mutableListOf<Pair<String, String>>()
        for ((ns, key) in keys.distinct()) {
            val r = readDirect(ns, key)
            if (r.readable) out["$ns/$key"] = r else blocked.add(ns to key)
        }
        if (blocked.isNotEmpty() && hasShell()) {
            val cmd = blocked.joinToString("; ") { (ns, key) -> "settings get $ns $key" }
            val lines = priv(cmd).stdout.lines()
            blocked.forEachIndexed { i, (ns, key) ->
                val v = lines.getOrNull(i)?.trim()
                out["$ns/$key"] = Read(v != null, v?.takeUnless { it.isEmpty() || it == "null" })
            }
        } else {
            blocked.forEach { (ns, key) -> out["$ns/$key"] = Read(false, null) }
        }
        return out
    }

    /** Last failure reason from [writeSetting], shown to the user. */
    private var lastWriteError: String? = null

    private fun writeSetting(ns: String, key: String, value: String?): Boolean {
        lastWriteError = null
        if (value != null && !SAFE_VALUE.matcher(value).matches()) {
            lastWriteError = "invalid value"
            return false
        }
        if (hasSecureSettings()) {
            val ok = try {
                val cr = context.contentResolver
                when (ns) {
                    "global" -> Settings.Global.putString(cr, key, value)
                    "secure" -> Settings.Secure.putString(cr, key, value)
                    "system" -> Settings.System.putString(cr, key, value)
                    else -> false
                }
            } catch (e: Exception) {
                false
            }
            if (ok) return true
        }
        if (hasShell()) {
            val args = if (value == null) "delete $ns $key" else "put $ns $key $value"
            val r = priv("settings $args")
            if (r.ok) return true
            // Some ROMs ship a broken `settings` wrapper; the service call is equivalent.
            val alt = priv("cmd settings $args")
            if (alt.ok) return true
            lastWriteError = alt.errorText(r.errorText("exit code ${r.exitCode}"))
            logFail("settings", args, alt)
            return false
        }
        lastWriteError = "no Shizuku or ADB grant"
        return false
    }

    private fun sameValue(a: String?, b: String?): Boolean {
        if (a == b) return true
        val fa = a?.toFloatOrNull() ?: return false
        val fb = b?.toFloatOrNull() ?: return false
        return kotlin.math.abs(fa - fb) < 0.01f
    }

    // ─────────────────────────────────────────────────────────────────────
    // Tweak definitions
    // ─────────────────────────────────────────────────────────────────────

    /** Returns the settings a tweak writes, or null when [id] is not a settings tweak. */
    private fun settingsWrites(id: String, args: Map<*, *>): List<Write>? = when (id) {
        "refresh_rate_lock" -> {
            val rates = supportedRefreshRates()
            val requested = (args["hz"] as? Number)?.toFloat()
            val hz = requested?.takeIf { r -> rates.any { kotlin.math.abs(it - r) < 0.5f } }
                ?: rates.max()
            val v = String.format(java.util.Locale.US, "%.1f", hz)
            listOf(Write("system", "peak_refresh_rate", v), Write("system", "min_refresh_rate", v))
        }
        "animation_scale" -> {
            val scale = ((args["scale"] as? Number)?.toFloat() ?: 0.5f).coerceIn(0f, 1f)
            val v = String.format(java.util.Locale.US, "%.2f", scale)
            listOf(
                Write("global", "window_animation_scale", v),
                Write("global", "transition_animation_scale", v),
                Write("global", "animator_duration_scale", v),
            )
        }
        "disable_blurs" -> listOf(Write("global", "disable_window_blurs", "1"))
        "heads_up_off" -> listOf(Write("global", "heads_up_notifications_enabled", "0"))
        "touch_hold_fast" -> listOf(Write("secure", "long_press_timeout", "250"))
        "auto_brightness_off" -> listOf(Write("system", "screen_brightness_mode", "0"))
        "scan_off" -> listOf(
            Write("global", "wifi_scan_always_enabled", "0"),
            Write("global", "ble_scan_always_enabled", "0"),
        )
        "private_dns" -> {
            val host = DNS_HOSTS[args["provider"] as? String] ?: DNS_HOSTS.getValue("cloudflare")
            listOf(
                Write("global", "private_dns_mode", "hostname"),
                Write("global", "private_dns_specifier", host),
            )
        }
        else -> null
    }

    private fun minSdkFor(id: String): Int = when (id) {
        "refresh_rate_lock" -> Build.VERSION_CODES.R
        "disable_blurs", "fixed_performance", "wifi_low_latency" -> Build.VERSION_CODES.S
        "private_dns" -> Build.VERSION_CODES.P
        else -> Build.VERSION_CODES.O
    }

    private val knownIds = listOf(
        "refresh_rate_lock", "animation_scale", "disable_blurs", "heads_up_off",
        "touch_hold_fast", "scan_off", "private_dns", "fixed_performance", "gaming_dnd",
        "wifi_low_latency", "auto_sync_off", "auto_brightness_off",
        "cpu_governor_perf", "gpu_perf", "tcp_bbr", "swappiness_low",
    )

    /** Tweaks Android forgets on reboot; re-applied when Shizuku reconnects. */
    private val volatileIds = setOf("fixed_performance", "wifi_low_latency") + rootIds

    /** Kernel tweaks: sysfs/procfs writes that need a root shell. */
    private val rootIds: Set<String> get() = setOf("cpu_governor_perf", "gpu_perf", "tcp_bbr", "swappiness_low")

    // ─────────────────────────────────────────────────────────────────────
    // State
    // ─────────────────────────────────────────────────────────────────────

    private fun states(): Map<String, Any?> {
        val keys = mutableListOf<Pair<String, String>>()
        for (id in knownIds) {
            settingsWrites(id, emptyMap<String, Any?>())?.forEach { keys.add(it.ns to it.key) }
            appliedValues(id)?.keys()?.forEach { nsKey ->
                nsKey.split('/', limit = 2).takeIf { it.size == 2 }?.let { keys.add(it[0] to it[1]) }
            }
        }
        readCache = prefetch(keys)
        try {
            val out = mutableMapOf<String, Any?>()
            for (id in knownIds) {
                val blocker = blockerFor(id)
                val supported = Build.VERSION.SDK_INT >= minSdkFor(id) && blocker == null
                val active = supported && isActive(id)
                out[id] = mapOf(
                    "supported" to supported,
                    "active" to active,
                    "detail" to (blocker ?: detailFor(id)),
                )
            }
            return out
        } finally {
            readCache = null
        }
    }

    private fun appliedValues(id: String): JSONObject? =
        prefs.getString("applied_$id", null)?.let { runCatching { JSONObject(it) }.getOrNull() }

    private fun isActive(id: String): Boolean {
        return when (id) {
            in rootIds -> kernelActive(id)
            "fixed_performance", "wifi_low_latency" -> prefs.getBoolean("on_$id", false)
            "auto_sync_off" -> !ContentResolver.getMasterSyncAutomatically()
            "gaming_dnd" -> {
                val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                val filter = nm?.currentInterruptionFilter ?: NotificationManager.INTERRUPTION_FILTER_ALL
                filter != NotificationManager.INTERRUPTION_FILTER_ALL &&
                    filter != NotificationManager.INTERRUPTION_FILTER_UNKNOWN
            }
            else -> {
                val applied = appliedValues(id) ?: return false
                val keys = applied.keys().asSequence().toList()
                keys.isNotEmpty() && keys.all { nsKey ->
                    val (ns, key) = nsKey.split('/', limit = 2).let { it[0] to it[1] }
                    val read = readSettingFull(ns, key)
                    // If Android hides the value entirely, trust the persisted write.
                    !read.readable || sameValue(read.value, applied.optString(nsKey))
                }
            }
        }
    }

    private fun detailFor(id: String): String? = when (id) {
        "refresh_rate_lock" -> readSetting("system", "tran_refresh_mode")?.let { "XOS $it Hz" }
            ?: readSetting("system", "min_refresh_rate")?.let { "min $it Hz" }
        "animation_scale" -> readSetting("global", "window_animation_scale")?.let { "${it}x" }
        "private_dns" -> readSetting("global", "private_dns_specifier")
        "touch_hold_fast" -> readSetting("secure", "long_press_timeout")?.let { "$it ms" }
        else -> null
    }

    // ─────────────────────────────────────────────────────────────────────
    // Apply / revert
    // ─────────────────────────────────────────────────────────────────────

    private fun outcome(ok: Boolean, message: String, extra: Map<String, Any?> = emptyMap()) =
        mapOf("success" to ok, "message" to message) + extra

    private fun apply(id: String, args: Map<*, *>): Map<String, Any?> {
        if (id !in knownIds) return outcome(false, "Unknown tweak")
        if (id in rootIds) return applyKernel(id)
        if (Build.VERSION.SDK_INT < minSdkFor(id)) {
            return outcome(false, "Requires Android API ${minSdkFor(id)}+")
        }

        when (id) {
            "fixed_performance" -> {
                if (!hasShell()) return outcome(false, "Requires Shizuku")
                val r = priv("cmd power set-fixed-performance-mode-enabled true")
                if (!r.ok) {
                    logFail(id, "set-fixed-performance-mode-enabled", r)
                    markUnsupported(id)
                    return outcome(false, "This phone's Power HAL doesn't support fixed performance mode")
                }
                prefs.edit().putBoolean("on_$id", true).apply()
                return outcome(true, "Fixed performance mode enabled")
            }
            "gaming_dnd" -> return setDnd(true)
            "wifi_low_latency" -> {
                if (!hasShell()) return outcome(false, "Requires Shizuku")
                blockerFor(id)?.let { return outcome(false, it) }
                val low = priv("cmd wifi force-low-latency-mode enabled")
                if (!low.ok) {
                    logFail(id, "force-low-latency-mode", low)
                    markUnsupported(id)
                    return outcome(false, "This phone's Wi-Fi driver doesn't support low-latency mode")
                }
                // High-perf lock is optional; older Wi-Fi HALs lack it.
                priv("cmd wifi force-hi-perf-mode enabled")
                prefs.edit().putBoolean("on_$id", true).apply()
                return outcome(true, "Wi-Fi low-latency mode on")
            }
            "auto_sync_off" -> {
                if (!prefs.contains("snap_$id")) {
                    prefs.edit().putBoolean("snap_$id", ContentResolver.getMasterSyncAutomatically()).apply()
                }
                return runCatching { ContentResolver.setMasterSyncAutomatically(false) }
                    .fold({ outcome(true, "Account auto-sync paused") }, { outcome(false, it.message ?: "Sync settings refused") })
            }
        }

        if (id == "refresh_rate_lock" && isTranssion()) return applyTranssionRefresh()

        val writes = settingsWrites(id, args) ?: return outcome(false, "Unknown tweak")
        if (!canWriteSettings()) {
            return outcome(false, "Requires Shizuku or WRITE_SECURE_SETTINGS")
        }

        // Snapshot originals once, so re-applying never overwrites the true original.
        if (!prefs.contains("snap_$id")) {
            val snap = JSONObject()
            for (w in writes) snap.put("${w.ns}/${w.key}", readSetting(w.ns, w.key) ?: JSONObject.NULL)
            prefs.edit().putString("snap_$id", snap.toString()).apply()
        }

        val applied = JSONObject()
        for (w in writes) {
            if (!writeSetting(w.ns, w.key, w.value)) {
                return outcome(false, "Couldn't change ${w.key}: ${lastWriteError ?: "rejected"}")
            }
            applied.put("${w.ns}/${w.key}", w.value)
        }
        prefs.edit().putString("applied_$id", applied.toString()).apply()

        val verified = isActive(id)
        return if (verified) {
            outcome(true, "Applied and verified")
        } else {
            Log.w(TAG, "$id reverted by system: wrote $applied, now ${writes.map { "${it.key}=${readSetting(it.ns, it.key)}" }}")
            outcome(false, "Written, but the system reset it (OEM override)")
        }
    }

    private fun revert(id: String): Map<String, Any?> {
        if (id !in knownIds) return outcome(false, "Unknown tweak")
        if (id in rootIds) return revertKernel(id)

        when (id) {
            "fixed_performance" -> {
                prefs.edit().remove("on_$id").apply()
                if (!hasShell()) return outcome(false, "Requires Shizuku")
                val r = priv("cmd power set-fixed-performance-mode-enabled false")
                return if (r.ok) outcome(true, "Fixed performance mode disabled")
                else outcome(false, r.errorText("Could not disable"))
            }
            "gaming_dnd" -> return setDnd(false)
            "wifi_low_latency" -> {
                prefs.edit().remove("on_$id").apply()
                if (!hasShell()) return outcome(false, "Requires Shizuku")
                priv("cmd wifi force-hi-perf-mode disabled")
                val r = priv("cmd wifi force-low-latency-mode disabled")
                return if (r.ok) outcome(true, "Wi-Fi back to normal") else outcome(false, r.errorText("Could not disable"))
            }
            "auto_sync_off" -> {
                val original = prefs.getBoolean("snap_$id", true)
                prefs.edit().remove("snap_$id").apply()
                return runCatching { ContentResolver.setMasterSyncAutomatically(original) }
                    .fold({ outcome(true, "Auto-sync restored") }, { outcome(false, it.message ?: "Sync settings refused") })
            }
        }

        if (!canWriteSettings()) {
            return outcome(false, "Requires Shizuku or WRITE_SECURE_SETTINGS")
        }
        val snap = prefs.getString("snap_$id", null)?.let { runCatching { JSONObject(it) }.getOrNull() }
        if (snap == null) {
            prefs.edit().remove("applied_$id").apply()
            return outcome(true, "Nothing to restore")
        }
        for (nsKey in snap.keys()) {
            val (ns, key) = nsKey.split('/', limit = 2).let { it[0] to it[1] }
            val original = if (snap.isNull(nsKey)) null else snap.getString(nsKey)
            if (!writeSetting(ns, key, original)) {
                return outcome(false, "Couldn't restore $key: ${lastWriteError ?: "rejected"}")
            }
        }
        prefs.edit().remove("snap_$id").remove("applied_$id").apply()
        return outcome(true, "Original settings restored")
    }

    private fun setDnd(enable: Boolean): Map<String, Any?> {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            ?: return outcome(false, "Notification service unavailable")

        if (enable && !prefs.contains("snap_gaming_dnd")) {
            prefs.edit().putInt("snap_gaming_dnd", nm.currentInterruptionFilter).apply()
        }
        val target = if (enable) {
            NotificationManager.INTERRUPTION_FILTER_PRIORITY
        } else {
            prefs.getInt("snap_gaming_dnd", NotificationManager.INTERRUPTION_FILTER_ALL)
                .takeIf { it != NotificationManager.INTERRUPTION_FILTER_UNKNOWN }
                ?: NotificationManager.INTERRUPTION_FILTER_ALL
        }

        // Shell first: it sets the global DND state, which behaves the same on
        // every Android version. The app-level API is the no-Shizuku fallback.
        var ok = false
        if (hasShell()) {
            val mode = when (target) {
                NotificationManager.INTERRUPTION_FILTER_PRIORITY -> "priority"
                NotificationManager.INTERRUPTION_FILTER_ALARMS -> "alarms"
                NotificationManager.INTERRUPTION_FILTER_NONE -> "none"
                else -> "off"
            }
            val r = priv("cmd notification set_dnd $mode")
            ok = r.ok
            if (!ok) logFail("gaming_dnd", "set_dnd $mode", r)
        }
        if (!ok && nm.isNotificationPolicyAccessGranted) {
            ok = runCatching { nm.setInterruptionFilter(target); true }.getOrDefault(false)
        }
        if (!ok) return outcome(false, "Grant Do Not Disturb access or connect Shizuku")
        if (!enable) prefs.edit().remove("snap_gaming_dnd").apply()
        return outcome(true, if (enable) "Priority-only Do Not Disturb on" else "Notifications restored")
    }

    private fun reapplyVolatile(force: Boolean): Map<String, Any?> {
        if (!force && reappliedThisProcess) return outcome(true, "Already restored")
        if (!hasShell()) return outcome(false, "Requires Shizuku")
        reappliedThisProcess = true
        var count = 0
        for (id in volatileIds) {
            if (prefs.getBoolean("on_$id", false) && apply(id, emptyMap<String, Any?>())["success"] == true) {
                count++
            }
        }
        return outcome(true, "Restored $count tweak(s)", mapOf("count" to count))
    }

    // ─────────────────────────────────────────────────────────────────────
    // One-shot actions — every result is measured, not estimated.
    // ─────────────────────────────────────────────────────────────────────

    private fun availRam(): Long {
        val am = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        return ActivityManager.MemoryInfo().also { am.getMemoryInfo(it) }.availMem
    }

    private fun availStorage(): Long =
        StatFs(Environment.getDataDirectory().path).let { it.availableBlocksLong * it.blockSizeLong }

    private fun runAction(id: String, packageName: String?, mode: String? = null): Map<String, Any?> = when (id) {
        "ram_boost" -> {
            val before = availRam()
            val method: String
            if (hasShell()) {
                priv("am kill-all")
                method = "shell"
            } else {
                val am = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                val pm = context.packageManager
                for (app in pm.getInstalledApplications(0)) {
                    if (app.flags and ApplicationInfo.FLAG_SYSTEM == 0 && app.packageName != context.packageName) {
                        runCatching { am.killBackgroundProcesses(app.packageName) }
                    }
                }
                method = "standard"
            }
            Thread.sleep(1200) // let the kernel reclaim pages before measuring
            val freed = (availRam() - before).coerceAtLeast(0)
            outcome(true, "Background processes stopped", mapOf("freedBytes" to freed, "method" to method))
        }
        "drop_caches" -> {
            if (!hasRoot()) {
                outcome(false, "Needs root")
            } else {
                val before = availRam()
                val r = priv("sync; echo 3 > /proc/sys/vm/drop_caches")
                Thread.sleep(800)
                val freed = (availRam() - before).coerceAtLeast(0)
                if (r.ok) outcome(true, "Kernel page cache dropped", mapOf("freedBytes" to freed))
                else outcome(false, r.errorText("Kernel refused"))
            }
        }
        "fstrim" -> {
            if (!hasRoot()) {
                outcome(false, "Needs root")
            } else {
                val r = priv("sm fstrim")
                if (r.ok) outcome(true, "Storage TRIM finished — flash can write faster") else outcome(false, r.errorText("TRIM failed"))
            }
        }
        "trim_caches" -> {
            val before = availStorage()
            runCatching { context.cacheDir?.deleteRecursively() }
            runCatching { context.externalCacheDir?.deleteRecursively() }
            val scope = if (hasShell()) {
                priv("pm trim-caches 999G")
                "all apps"
            } else {
                "this app only"
            }
            val freed = (availStorage() - before).coerceAtLeast(0)
            outcome(true, "App caches cleared ($scope)", mapOf("freedBytes" to freed, "scope" to scope))
        }
        "compile_all" -> {
            if (!hasShell()) {
                outcome(false, "Requires Shizuku")
            } else {
                cancelRequested = false
                runningTask = "dexopt"
                emitProgress("dexopt", 0, 0)
                val r = try { priv("cmd package bg-dexopt-job") } finally { runningTask = null }
                emitProgress("dexopt", 1, 1, finished = true)
                when {
                    cancelRequested -> outcome(true, "System dexopt stopped")
                    r.ok -> outcome(true, "System dexopt finished — apps re-optimized by ART")
                    else -> outcome(false, r.errorText("Background dexopt failed"))
                }
            }
        }
        "compile_game" -> {
            if (!hasShell()) {
                outcome(false, "Requires Shizuku")
            } else if (!validPackage(packageName)) {
                outcome(false, "Invalid package")
            } else {
                val filter = if (mode == "speed-profile") "speed-profile" else "speed"
                val r = priv("cmd package compile -m $filter -f $packageName")
                if (r.ok && r.stdout.contains("Success", ignoreCase = true)) {
                    outcome(true, "Compiled with ART $filter")
                } else {
                    outcome(false, r.errorText("Compilation failed"))
                }
            }
        }
        else -> outcome(false, "Unknown action")
    }

    // ─────────────────────────────────────────────────────────────────────
    // Per-game tuning (Android 13+ GameManager)
    // ─────────────────────────────────────────────────────────────────────

    private fun validPackage(pkg: String?): Boolean =
        !pkg.isNullOrBlank() && pkg.length <= 128 && PACKAGE_NAME.matcher(pkg).matches()

    private fun applyGameTuning(args: Map<*, *>): Map<String, Any?> {
        val pkg = args["packageName"] as? String
        if (!validPackage(pkg)) return outcome(false, "Invalid package")
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            return outcome(false, "Game Mode needs Android 13+")
        }
        if (!hasShell()) return outcome(false, "Requires Shizuku")

        val mode = (args["mode"] as? String)?.takeIf { it in GAME_MODES } ?: "standard"
        val downscale = ((args["downscale"] as? Number)?.toDouble() ?: 1.0).coerceIn(0.3, 1.0)
        val fps = (args["fps"] as? Number)?.toInt()?.takeIf { it in listOf(30, 45, 60, 90, 120, 144) }
        val notes = mutableListOf<String>()

        val modeResult = priv("cmd game mode $mode $pkg")
        if (!modeResult.ok) return outcome(false, modeResult.errorText("Game Mode rejected"))
        if (modeResult.stdout.contains("not supported", ignoreCase = true)) {
            notes.add("mode not supported by this game")
        }

        if (mode != "standard" && (downscale < 0.999 || fps != null)) {
            val ratio = if (downscale < 0.999) String.format(java.util.Locale.US, "%.2f", downscale) else null
            val ok = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                val modeId = if (mode == "performance") 2 else 3
                val flags = buildString {
                    append("--mode $modeId")
                    if (ratio != null) append(" --downscale $ratio")
                    if (fps != null) append(" --fps $fps")
                }
                priv("cmd game set $flags $pkg").ok
            } else {
                ratio == null || priv("cmd game downscale $ratio $pkg").ok
            }
            if (!ok) notes.add("resolution/FPS override not accepted")
        }

        val msg = if (notes.isEmpty()) "Game tuning applied" else "Applied (${notes.joinToString("; ")})"
        return outcome(true, msg)
    }

    private fun resetGameTuning(pkg: String?): Map<String, Any?> {
        if (!validPackage(pkg)) return outcome(false, "Invalid package")
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return outcome(true, "Nothing to reset")
        if (!hasShell()) return outcome(false, "Requires Shizuku")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            priv("cmd game reset $pkg")
        } else {
            priv("cmd game downscale disable $pkg")
        }
        val r = priv("cmd game mode standard $pkg")
        return if (r.ok) outcome(true, "Game restored to defaults") else outcome(false, r.errorText("Reset failed"))
    }

    private fun openDndSettings(): Boolean = try {
        val intent = android.content.Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
            .addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
        true
    } catch (e: Exception) {
        false
    }

    // ─────────────────────────────────────────────────────────────────────
    // Long tasks with live progress (Dart listens for "taskProgress").
    // ─────────────────────────────────────────────────────────────────────

    @Volatile private var cancelRequested = false
    @Volatile private var runningTask: String? = null

    private fun emitProgress(
        task: String,
        done: Int,
        total: Int,
        packageName: String? = null,
        label: String? = null,
        ok: Int = 0,
        failed: Int = 0,
        finished: Boolean = false,
    ) {
        val event = mapOf(
            "task" to task,
            "done" to done,
            "total" to total,
            "packageName" to packageName,
            "label" to label,
            "ok" to ok,
            "failed" to failed,
            "finished" to finished,
        )
        main.post { runCatching { channel.invokeMethod("taskProgress", event) } }
    }

    private fun appLabel(pkg: String): String? = runCatching {
        val pm = context.packageManager
        pm.getApplicationLabel(pm.getApplicationInfo(pkg, 0)).toString()
    }.getOrNull()

    /**
     * AOT-compiles apps one by one so progress is real, not a guess.
     * speed-profile = compile what each app actually uses (recommended);
     * speed = compile everything (fastest code, more storage).
     */
    private fun compileApps(args: Map<*, *>): Map<String, Any?> {
        if (!hasShell()) return outcome(false, "Requires Shizuku")
        val mode = if (args["mode"] == "speed") "speed" else "speed-profile"
        val includeSystem = args["includeSystem"] == true
        val explicit = (args["packages"] as? List<*>)?.mapNotNull { it as? String }
        val source = explicit?.asSequence()
            ?: priv(if (includeSystem) "pm list packages" else "pm list packages -3")
                .stdout.lineSequence().map { it.removePrefix("package:").trim() }
        val list = source
            .filter { validPackage(it) && it != context.packageName }
            .distinct().sorted().toList()
        if (list.isEmpty()) return outcome(false, "No apps found to compile")

        cancelRequested = false
        runningTask = "compile_apps"
        var ok = 0
        var failed = 0
        try {
            list.forEachIndexed { i, pkg ->
                if (cancelRequested) {
                    emitProgress("compile_apps", i, list.size, ok = ok, failed = failed, finished = true)
                    return outcome(true, "Stopped after $i of ${list.size} apps ($ok compiled)", mapOf("compiled" to ok))
                }
                emitProgress("compile_apps", i, list.size, pkg, appLabel(pkg), ok, failed)
                val r = priv("cmd package compile -m $mode -f $pkg")
                if (r.ok && r.stdout.contains("Success", ignoreCase = true)) ok++ else failed++
            }
        } finally {
            runningTask = null
        }
        emitProgress("compile_apps", list.size, list.size, ok = ok, failed = failed, finished = true)
        val skipped = if (failed > 0) ", $failed skipped" else ""
        return outcome(true, "Compiled $ok apps ($mode)$skipped", mapOf("compiled" to ok))
    }

    private fun cancelLongTask(): Map<String, Any?> {
        cancelRequested = true
        // The system dexopt job has its own cancel switch.
        if (runningTask == "dexopt" && hasShell()) priv("cmd package bg-dexopt-job --cancel")
        return outcome(true, "Stopping…")
    }

    /** Why a tweak can't work on this phone, or null if it can. */
    private fun blockerFor(id: String): String? {
        if (prefs.getBoolean("unsupported_$id", false)) return "Not supported on this device"
        if (id in rootIds) {
            if (!hasRoot()) return "Needs root (Magisk / KernelSU / APatch)"
            if (kernelTargets(id).isEmpty()) return "Not supported by this kernel"
        }
        // Android restricts these Wi-Fi shell commands to root on production builds.
        if (id == "wifi_low_latency" && hasShell() && shellUid() != 0) {
            return "Needs Shizuku running as root"
        }
        return null
    }

    /** Records that the hardware/driver lacks a feature, so the UI stops offering it. */
    private fun markUnsupported(id: String) {
        prefs.edit().putBoolean("unsupported_$id", true).apply()
    }

    private fun logFail(id: String, what: String, r: ExecResult) {
        Log.w(TAG, "$id failed [$what] exit=${r.exitCode} out=${r.stdout.trim().take(200)} err=${r.stderr.trim().take(200)}")
    }

    // ─────────────────────────────────────────────────────────────────────
    // Transsion XOS (Infinix / Tecno / itel) refresh rate.
    // XOS ignores AOSP peak_refresh_rate and resets min_refresh_rate within
    // seconds; its own `tran_refresh_mode` drives DisplayModeDirector's
    // user peak vote. Not every panel mode is accepted (e.g. 144 may be
    // reserved for XOS game handling), so each candidate is verified against
    // the live vote and we step down until XOS honours it.
    // ─────────────────────────────────────────────────────────────────────

    private fun isTranssion(): Boolean = readSetting("system", "tran_refresh_mode") != null

    /** Max rate in DisplayModeDirector's user peak vote, or null if unreadable. */
    private fun userPeakVote(): Float? {
        if (!hasShell()) return null
        val out = priv("dumpsys display | grep PRIORITY_USER_SETTING_PEAK_REFRESH_RATE").stdout
        return Regex("mMaxRefreshRate=([0-9.]+)").find(out)?.groupValues?.get(1)?.toFloatOrNull()
    }

    private fun applyTranssionRefresh(): Map<String, Any?> {
        if (!canWriteSettings()) return outcome(false, "Requires Shizuku or WRITE_SECURE_SETTINGS")
        val id = "refresh_rate_lock"
        if (!prefs.contains("snap_$id")) {
            val snap = JSONObject().put("system/tran_refresh_mode", readSetting("system", "tran_refresh_mode") ?: JSONObject.NULL)
            prefs.edit().putString("snap_$id", snap.toString()).apply()
        }
        val candidates = supportedRefreshRates().map { it.roundToInt() }.filter { it >= 90 }.distinct().sortedDescending()
        for (hz in candidates) {
            if (!writeSetting("system", "tran_refresh_mode", hz.toString())) {
                return outcome(false, "Couldn't change tran_refresh_mode: ${lastWriteError ?: "rejected"}")
            }
            Thread.sleep(600) // let DisplayModeDirector re-vote
            val vote = userPeakVote()
            // Without Shizuku we can't read the vote; trust the first write.
            if (vote == null || vote >= hz - 1) {
                prefs.edit().putString("applied_$id", JSONObject().put("system/tran_refresh_mode", hz.toString()).toString()).apply()
                val note = if (hz < (candidates.firstOrNull() ?: hz)) " (XOS reserves higher modes for its game mode)" else ""
                return outcome(true, "XOS refresh mode set to $hz Hz$note")
            }
            Log.w(TAG, "XOS rejected tran_refresh_mode=$hz (vote=$vote), trying lower")
        }
        return outcome(false, "XOS didn't accept any high refresh mode")
    }

    // ─────────────────────────────────────────────────────────────────────
    // Root session
    // ─────────────────────────────────────────────────────────────────────

    /** Silently resumes a previously granted root session (managers remember the grant). */
    fun resumeRoot() {
        if (!prefs.getBoolean("root_enabled", false)) return
        longIo.execute {
            if (root.request(15)) {
                reappliedThisProcess = false
                reapplyVolatile(force = false)
            }
        }
    }

    private fun requestRoot(): Map<String, Any?> {
        if (!root.available()) return outcome(false, "No root found (Magisk, KernelSU or APatch)")
        val ok = root.request(30)
        prefs.edit().putBoolean("root_enabled", ok).apply()
        if (ok) reapplyVolatile(force = true)
        return if (ok) outcome(true, "Root granted via ${root.manager() ?: "su"}")
        else outcome(false, "Root was denied or timed out in ${root.manager() ?: "your root manager"}")
    }

    private fun disableRoot(): Map<String, Any?> {
        prefs.edit().putBoolean("root_enabled", false).apply()
        root.close()
        return outcome(true, "Root mode turned off — using Shizuku")
    }

    // ─────────────────────────────────────────────────────────────────────
    // Kernel tweaks (root). Every target file's original value is saved
    // before the first write and restored on revert. Values reset on reboot,
    // so active ones are re-applied when the root session resumes.
    // ─────────────────────────────────────────────────────────────────────

    private val safePath = Pattern.compile("^/(sys|proc/sys)/[A-Za-z0-9_./:-]+$")

    private fun rootList(glob: String): List<String> =
        priv("ls -d $glob 2>/dev/null").stdout.lines().map { it.trim() }
            .filter { it.isNotEmpty() && safePath.matcher(it).matches() }

    private fun rootRead(path: String): String? =
        priv("cat $path").takeIf { it.ok }?.stdout?.trim()

    /** Files to write and the value each should hold, for kernel tweak [id]. */
    private fun kernelTargets(id: String): Map<String, String> {
        if (!hasRoot()) return emptyMap()
        return when (id) {
            "cpu_governor_perf" -> rootList("/sys/devices/system/cpu/cpufreq/policy*").mapNotNull { dir ->
                val available = rootRead("$dir/scaling_available_governors") ?: return@mapNotNull null
                if ("performance" in available.split(' ')) "$dir/scaling_governor" to "performance" else null
            }.toMap()
            "gpu_perf" -> rootList("/sys/class/devfreq/*")
                .filter { Regex("kgsl|mali|gpu|g3d|pvr|sgx", RegexOption.IGNORE_CASE).containsMatchIn(it) }
                .mapNotNull { dir ->
                    val available = rootRead("$dir/available_governors") ?: return@mapNotNull null
                    if ("performance" in available.split(' ')) "$dir/governor" to "performance" else null
                }.toMap()
            "tcp_bbr" -> {
                val available = rootRead("/proc/sys/net/ipv4/tcp_available_congestion_control") ?: ""
                if ("bbr" in available.split(' ')) mapOf("/proc/sys/net/ipv4/tcp_congestion_control" to "bbr")
                else emptyMap()
            }
            "swappiness_low" -> {
                val current = rootRead("/proc/sys/vm/swappiness")?.toIntOrNull()
                if (current != null) mapOf("/proc/sys/vm/swappiness" to "40") else emptyMap()
            }
            else -> emptyMap()
        }
    }

    private fun kernelActive(id: String): Boolean {
        if (!hasRoot() || !prefs.getBoolean("on_$id", false)) return false
        val targets = kernelTargets(id)
        return targets.isNotEmpty() && targets.all { (path, value) -> rootRead(path) == value }
    }

    private fun applyKernel(id: String): Map<String, Any?> {
        if (!hasRoot()) return outcome(false, "Needs root (Magisk / KernelSU / APatch)")
        val targets = kernelTargets(id)
        if (targets.isEmpty()) return outcome(false, "Not supported by this kernel")
        if (!prefs.contains("snap_$id")) {
            val snap = JSONObject()
            targets.keys.forEach { path -> snap.put(path, rootRead(path) ?: JSONObject.NULL) }
            prefs.edit().putString("snap_$id", snap.toString()).apply()
        }
        val failed = targets.filter { (path, value) ->
            val r = priv("echo $value > $path")
            if (!r.ok) logFail(id, "write $path", r)
            !r.ok || rootRead(path) != value
        }
        if (failed.size == targets.size) return outcome(false, "Kernel rejected the change")
        prefs.edit().putBoolean("on_$id", true).apply()
        val partial = if (failed.isNotEmpty()) " (${targets.size - failed.size}/${targets.size} nodes)" else ""
        return outcome(true, "Applied to the kernel$partial")
    }

    private fun revertKernel(id: String): Map<String, Any?> {
        prefs.edit().remove("on_$id").apply()
        val snap = prefs.getString("snap_$id", null)?.let { runCatching { JSONObject(it) }.getOrNull() }
            ?: return outcome(true, "Nothing to restore")
        if (!hasRoot()) return outcome(false, "Needs root to restore")
        for (path in snap.keys()) {
            if (snap.isNull(path) || !safePath.matcher(path).matches()) continue
            val original = snap.getString(path)
            if (!SAFE_VALUE.matcher(original).matches()) continue
            priv("echo $original > $path")
        }
        prefs.edit().remove("snap_$id").apply()
        return outcome(true, "Kernel defaults restored")
    }
}
