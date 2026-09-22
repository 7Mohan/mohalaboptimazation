package com.mohalab.optimization

import android.app.ActivityManager
import android.app.NotificationManager
import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.wifi.WifiManager
import android.content.Intent
import android.content.IntentFilter
import android.provider.Settings
import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.BatteryManager
import android.os.Build
import android.os.Environment
import android.os.StatFs
import android.util.DisplayMetrics
import android.view.Display
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.security.MessageDigest
import java.util.regex.Pattern

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.mohalab.optimization/device_info"
        private const val GAME_CHANNEL = "com.mohalab.optimization/game_discovery"
        private const val OPTIMIZATION_CHANNEL = "com.mohalab.optimization/optimizations"
    }

    private var shizukuBridge: ShizukuBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register Shizuku bridge — must happen before other channels
        shizukuBridge = ShizukuBridge(this, flutterEngine).also { it.register() }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getBasicDeviceInfo" -> result.success(getBasicDeviceInfo())
                "getMemoryInfo"      -> result.success(getMemoryInfo())
                "getStorageInfo"     -> result.success(getStorageInfo())
                "getBatteryInfo"     -> result.success(getBatteryInfo())
                "getDisplayInfo"     -> result.success(getDisplayInfo())
                "getCpuInfo"         -> result.success(getCpuInfo())
                "getAllDeviceInfo"    -> result.success(getAllDeviceInfo())
                "getNetworkInfo"     -> result.success(getNetworkInfo())
                "checkAppIntegrity"  -> result.success(getAppIntegrityInfo())
                "openUrl"            -> {
                    val url = call.argument<String>("url")
                    if (url.isNullOrBlank()) {
                        result.success(false)
                    } else {
                        try {
                            val uri = android.net.Uri.parse(url)
                            val scheme = uri.scheme?.lowercase()
                            // Defense-in-depth: only allow web HTTP/HTTPS navigation
                            if (scheme != "http" && scheme != "https") {
                                result.success(false)
                            } else {
                                val intent = Intent(Intent.ACTION_VIEW, uri).apply {
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                startActivity(intent)
                                result.success(true)
                            }
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            GAME_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledApps" -> {
                    val includeIcons = call.argument<Boolean>("includeIcons") ?: true
                    result.success(getInstalledApps(includeIcons))
                }
                "getAppIcon" -> {
                    val packageName = call.argument<String>("packageName")
                    if (isValidPackageName(packageName)) {
                        result.success(getAppIcon(packageName!!))
                    } else {
                        result.error("INVALID_ARGUMENT", "Invalid package name format", null)
                    }
                }
                "launchApp" -> {
                    val packageName = call.argument<String>("packageName")
                    if (isValidPackageName(packageName)) {
                        result.success(launchApp(packageName!!))
                    } else {
                        result.error("INVALID_ARGUMENT", "Invalid package name format", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            OPTIMIZATION_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "trimMemory" -> {
                    Thread {
                        var success = false
                        if (shizukuBridge?.isReady() == true) {
                            shizukuBridge?.executeShell("am kill-all")
                            shizukuBridge?.executeShell("pm trim-caches 999G")
                            success = true
                        } else {
                            try {
                                val am = getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
                                val packages = packageManager.getInstalledApplications(0)
                                for (app in packages) {
                                    if ((app.flags and ApplicationInfo.FLAG_SYSTEM) == 0 && app.packageName != packageName) {
                                        am?.killBackgroundProcesses(app.packageName)
                                    }
                                }
                                success = true
                            } catch (e: Exception) {
                                success = false
                            }
                        }
                        System.gc()
                        runOnUiThread { result.success(success) }
                    }.start()
                }

                "cleanSystemCache" -> {
                    Thread {
                        var success = false
                        if (shizukuBridge?.isReady() == true) {
                            val res = shizukuBridge?.executeShell("pm trim-caches 999G")
                            success = res?.first ?: false
                        }
                        // Also clear internal cache
                        try {
                            cacheDir?.deleteRecursively()
                            externalCacheDir?.deleteRecursively()
                            success = true
                        } catch (e: Exception) {}
                        runOnUiThread { result.success(success) }
                    }.start()
                }

                "setPerformanceMode" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: true
                    Thread {
                        var success = false
                        if (shizukuBridge?.isReady() == true) {
                            shizukuBridge?.executeShell("cmd power set-fixed-performance-mode-enabled $enabled")
                            if (enabled) {
                                shizukuBridge?.executeShell("settings put global game_driver_all_apps 1")
                            }
                            success = true
                        }
                        runOnUiThread { result.success(success) }
                    }.start()
                }

                "getAnimationScales" -> {
                    val resolver = contentResolver
                    val window = try {
                        Settings.Global.getFloat(resolver, Settings.Global.WINDOW_ANIMATION_SCALE, 1.0f)
                    } catch (e: Exception) { 1.0f }
                    val transition = try {
                        Settings.Global.getFloat(resolver, Settings.Global.TRANSITION_ANIMATION_SCALE, 1.0f)
                    } catch (e: Exception) { 1.0f }
                    val animator = try {
                        Settings.Global.getFloat(resolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1.0f)
                    } catch (e: Exception) { 1.0f }

                    result.success(
                        mapOf(
                            "window" to window.toDouble(),
                            "transition" to transition.toDouble(),
                            "animator" to animator.toDouble()
                        )
                    )
                }

                "setAnimationScales" -> {
                    val scale = call.argument<Double>("scale")?.toFloat() ?: 1.0f
                    Thread {
                        var success = false
                        if (shizukuBridge?.isReady() == true) {
                            shizukuBridge?.executeShell("settings put global window_animation_scale $scale")
                            shizukuBridge?.executeShell("settings put global transition_animation_scale $scale")
                            shizukuBridge?.executeShell("settings put global animator_duration_scale $scale")
                            success = true
                        } else {
                            try {
                                val resolver = contentResolver
                                Settings.Global.putFloat(resolver, Settings.Global.WINDOW_ANIMATION_SCALE, scale)
                                Settings.Global.putFloat(resolver, Settings.Global.TRANSITION_ANIMATION_SCALE, scale)
                                Settings.Global.putFloat(resolver, Settings.Global.ANIMATOR_DURATION_SCALE, scale)
                                success = true
                            } catch (e: Exception) {
                                success = false
                            }
                        }
                        runOnUiThread { result.success(success) }
                    }.start()
                }

                "getDndInterruptionFilter" -> {
                    val nm = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                    val filter = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        nm?.currentInterruptionFilter ?: NotificationManager.INTERRUPTION_FILTER_ALL
                    } else {
                        1
                    }
                    result.success(filter)
                }

                "setDndInterruptionFilter" -> {
                    val filter = call.argument<Int>("filter") ?: 1
                    Thread {
                        var success = false
                        if (shizukuBridge?.isReady() == true) {
                            val zenMode = if (filter > 1) 1 else 0
                            shizukuBridge?.executeShell("settings put global zen_mode $zenMode")
                            success = true
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                            if (nm?.isNotificationPolicyAccessGranted == true) {
                                nm.setInterruptionFilter(filter)
                                success = true
                            }
                        }
                        runOnUiThread { result.success(success) }
                    }.start()
                }

                "getRefreshRates" -> {
                    val display = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        display
                    } else {
                        @Suppress("DEPRECATION")
                        (getSystemService(Context.WINDOW_SERVICE) as? WindowManager)?.defaultDisplay
                    }
                    val modes = display?.supportedModes
                    val peak = modes?.maxOfOrNull { it.refreshRate } ?: 60.0f
                    result.success(mapOf("min" to 60.0, "peak" to peak.toDouble()))
                }

                "setMinRefreshRate" -> {
                    val rate = call.argument<Double>("rate")?.toFloat() ?: 60.0f
                    Thread {
                        var success = false
                        if (shizukuBridge?.isReady() == true) {
                            shizukuBridge?.executeShell("settings put system min_refresh_rate $rate")
                            shizukuBridge?.executeShell("settings put system peak_refresh_rate $rate")
                            success = true
                        } else {
                            try {
                                Settings.System.putFloat(contentResolver, "min_refresh_rate", rate)
                                success = true
                            } catch (e: Exception) {
                                success = false
                            }
                        }
                        runOnUiThread { result.success(success) }
                    }.start()
                }

                "setFixedPerformanceMode" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: true
                    Thread {
                        var success = false
                        if (shizukuBridge?.isReady() == true) {
                            shizukuBridge?.executeShell("cmd power set-fixed-performance-mode-enabled $enabled")
                            if (enabled) {
                                shizukuBridge?.executeShell("settings put global game_driver_all_apps 1")
                            }
                            success = true
                        }
                        runOnUiThread { result.success(success) }
                    }.start()
                }

                "setAppGameMode" -> {
                    val pkg = call.argument<String>("packageName") ?: ""
                    val mode = call.argument<String>("mode") ?: "performance"
                    Thread {
                        var success = false
                        if (shizukuBridge?.isReady() == true && isValidPackageName(pkg)) {
                            val res = shizukuBridge?.executeShell("cmd game mode $mode $pkg")
                            success = res?.first ?: false
                        }
                        runOnUiThread { result.success(success) }
                    }.start()
                }

                "setAppDownscale" -> {
                    val pkg = call.argument<String>("packageName") ?: ""
                    val scale = call.argument<Double>("scale") ?: 1.0
                    Thread {
                        var success = false
                        if (shizukuBridge?.isReady() == true && isValidPackageName(pkg)) {
                            val res = shizukuBridge?.executeShell("cmd game downscale $scale $pkg")
                            success = res?.first ?: false
                        }
                        runOnUiThread { result.success(success) }
                    }.start()
                }

                "setTouchLatency" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: true
                    Thread {
                        var success = false
                        if (shizukuBridge?.isReady() == true) {
                            if (enabled) {
                                shizukuBridge?.executeShell("settings put secure tap_duration_threshold 0.0")
                                shizukuBridge?.executeShell("settings put secure touch_blocking_period 0.0")
                                shizukuBridge?.executeShell("settings put secure long_press_timeout 250")
                            } else {
                                shizukuBridge?.executeShell("settings put secure tap_duration_threshold 0.1")
                                shizukuBridge?.executeShell("settings put secure touch_blocking_period 0.1")
                                shizukuBridge?.executeShell("settings put secure long_press_timeout 400")
                            }
                            success = true
                        }
                        runOnUiThread { result.success(success) }
                    }.start()
                }

                "setBlurDisabled" -> {
                    val disabled = call.argument<Boolean>("disabled") ?: true
                    val v = if (disabled) 1 else 0
                    Thread {
                        var success = false
                        if (shizukuBridge?.isReady() == true) {
                            shizukuBridge?.executeShell("settings put global disable_window_blurs $v")
                            success = true
                        }
                        runOnUiThread { result.success(success) }
                    }.start()
                }

                "optimizeNetworkBuffers" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: true
                    Thread {
                        var success = false
                        if (shizukuBridge?.isReady() == true) {
                            if (enabled) {
                                shizukuBridge?.executeShell("setprop net.tcp.buffersize.wifi 4096,87380,524288,4096,16384,110208")
                                shizukuBridge?.executeShell("setprop net.tcp.buffersize.lte 524288,1048576,2097152,262144,524288,1048576")
                            }
                            success = true
                        }
                        runOnUiThread { result.success(success) }
                    }.start()
                }

                "setGpuRenderingProfile" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: true
                    val v = if (enabled) 1 else 0
                    Thread {
                        var success = false
                        if (shizukuBridge?.isReady() == true) {
                            shizukuBridge?.executeShell("setprop debug.hwc.force_gpu_vsync $v")
                            shizukuBridge?.executeShell("setprop debug.stagefright.omx_default_rank $v")
                            success = true
                        }
                        runOnUiThread { result.success(success) }
                    }.start()
                }

                "deepRamClean" -> {
                    Thread {
                        var success = false
                        if (shizukuBridge?.isReady() == true) {
                            shizukuBridge?.executeShell("am kill-all")
                            shizukuBridge?.executeShell("pm trim-caches 999G")
                            success = true
                        } else {
                            try {
                                val am = getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
                                val packages = packageManager.getInstalledApplications(0)
                                for (app in packages) {
                                    if ((app.flags and ApplicationInfo.FLAG_SYSTEM) == 0 && app.packageName != packageName) {
                                        am?.killBackgroundProcesses(app.packageName)
                                    }
                                }
                                success = true
                            } catch (e: Exception) {}
                        }
                        try {
                            cacheDir?.deleteRecursively()
                            externalCacheDir?.deleteRecursively()
                        } catch (e: Exception) {}
                        System.gc()
                        runOnUiThread { result.success(success) }
                    }.start()
                }

                "bypassRenderPipelineFpsCap" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: true
                    val targetArg = call.argument<Double>("targetHz")?.toFloat()
                    Thread {
                        var success = false
                        val display = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                            display
                        } else {
                            @Suppress("DEPRECATION")
                            (getSystemService(Context.WINDOW_SERVICE) as? WindowManager)?.defaultDisplay
                        }
                        val modes = display?.supportedModes
                        val peakHardwareHz = modes?.maxOfOrNull { it.refreshRate } ?: 144.0f
                        val targetHz = if (targetArg != null && targetArg > 60.0f) targetArg else peakHardwareHz

                        if (shizukuBridge?.isReady() == true) {
                            if (enabled) {
                                // 1. Lock system and global refresh rates to peak rate (144Hz/120Hz)
                                shizukuBridge?.executeShell("settings put system min_refresh_rate $targetHz")
                                shizukuBridge?.executeShell("settings put system peak_refresh_rate $targetHz")
                                shizukuBridge?.executeShell("settings put global min_refresh_rate $targetHz")
                                shizukuBridge?.executeShell("settings put global peak_refresh_rate $targetHz")
                                shizukuBridge?.executeShell("settings put global force_refresh_rate $targetHz")
                                shizukuBridge?.executeShell("settings put secure refresh_rate_mode 2")

                                // 2. Bypass DisplayManager content-matching frame rate downclocking
                                shizukuBridge?.executeShell("cmd display set-match-content-frame-rate-pref 0")
                                shizukuBridge?.executeShell("device_config put display_manager peak_refresh_rate_default $targetHz")
                                shizukuBridge?.executeShell("device_config put display_manager refresh_rate_in_high_zone $targetHz")
                                shizukuBridge?.executeShell("device_config put display_manager refresh_rate_in_zone $targetHz")

                                // 3. SurfaceFlinger Render Pipeline uncap: disable backpressure & fence waiting
                                shizukuBridge?.executeShell("setprop debug.sf.disable_backpressure 1")
                                shizukuBridge?.executeShell("setprop debug.sf.latch_unsignaled 1")
                                shizukuBridge?.executeShell("setprop debug.graphics.game_default_frame_rate $targetHz")
                                shizukuBridge?.executeShell("setprop ro.surface_flinger.use_content_detection_for_refresh_rate false")
                                shizukuBridge?.executeShell("setprop debug.sf.early_phase_offset_ns 500000")
                                shizukuBridge?.executeShell("setprop debug.sf.early_app_phase_offset_ns 500000")
                            } else {
                                // Restore adaptive frame pacing
                                shizukuBridge?.executeShell("settings put system min_refresh_rate 60.0")
                                shizukuBridge?.executeShell("settings put system peak_refresh_rate $targetHz")
                                shizukuBridge?.executeShell("settings put global min_refresh_rate 60.0")
                                shizukuBridge?.executeShell("settings put global peak_refresh_rate $targetHz")
                                shizukuBridge?.executeShell("cmd display set-match-content-frame-rate-pref 1")
                                shizukuBridge?.executeShell("setprop debug.sf.disable_backpressure 0")
                                shizukuBridge?.executeShell("setprop debug.sf.latch_unsignaled 0")
                                shizukuBridge?.executeShell("setprop ro.surface_flinger.use_content_detection_for_refresh_rate true")
                            }
                            success = true
                        } else {
                            try {
                                val rate = if (enabled) targetHz else 60.0f
                                Settings.System.putFloat(contentResolver, "min_refresh_rate", rate)
                                Settings.System.putFloat(contentResolver, "peak_refresh_rate", targetHz)
                                success = true
                            } catch (e: Exception) {
                                success = false
                            }
                        }
                        runOnUiThread { result.success(success) }
                    }.start()
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        shizukuBridge?.unregister()
        shizukuBridge = null
        super.onDestroy()
    }

    // ─────────────────────────────────────────────────────────────
    // Basic device identity
    // ─────────────────────────────────────────────────────────────
    private fun getBasicDeviceInfo(): Map<String, Any?> = mapOf(
        "manufacturer"   to Build.MANUFACTURER.capitalize(),
        "brand"          to Build.BRAND.capitalize(),
        "model"          to Build.MODEL,
        "device"         to Build.DEVICE,
        "product"        to Build.PRODUCT,
        "androidVersion" to Build.VERSION.RELEASE,
        "sdkInt"         to Build.VERSION.SDK_INT,
        "buildId"        to Build.ID,
        "buildType"      to Build.TYPE,
        "hardware"       to Build.HARDWARE,
        "cpuAbi"         to Build.SUPPORTED_ABIS.firstOrNull(),
        "supportedAbis"  to Build.SUPPORTED_ABIS.toList(),
    )

    // ─────────────────────────────────────────────────────────────
    // RAM
    // ─────────────────────────────────────────────────────────────
    private fun getMemoryInfo(): Map<String, Any?> {
        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val memInfo = ActivityManager.MemoryInfo()
        am.getMemoryInfo(memInfo)

        return mapOf(
            "totalRamBytes"     to memInfo.totalMem,
            "availableRamBytes" to memInfo.availMem,
            "lowMemory"         to memInfo.lowMemory,
            "lowMemThresholdBytes" to memInfo.threshold,
        )
    }

    // ─────────────────────────────────────────────────────────────
    // Storage
    // ─────────────────────────────────────────────────────────────
    private fun getStorageInfo(): Map<String, Any?> {
        val internalStat  = StatFs(Environment.getDataDirectory().path)
        val externalStat  = runCatching { StatFs(Environment.getExternalStorageDirectory().path) }.getOrNull()

        val intTotal     = internalStat.blockCountLong * internalStat.blockSizeLong
        val intAvailable = internalStat.availableBlocksLong * internalStat.blockSizeLong

        val extTotal     = externalStat?.let { it.blockCountLong * it.blockSizeLong }
        val extAvailable = externalStat?.let { it.availableBlocksLong * it.blockSizeLong }

        return mapOf(
            "internalTotalBytes"     to intTotal,
            "internalAvailableBytes" to intAvailable,
            "externalTotalBytes"     to extTotal,
            "externalAvailableBytes" to extAvailable,
        )
    }

    // ─────────────────────────────────────────────────────────────
    // Battery
    // ─────────────────────────────────────────────────────────────
    private fun getBatteryInfo(): Map<String, Any?> {
        val intent: Intent? = registerReceiver(
            null,
            IntentFilter(Intent.ACTION_BATTERY_CHANGED),
        )

        val level   = intent?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val scale   = intent?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
        val pct     = if (level >= 0 && scale > 0) (level * 100f / scale).toInt() else null

        val status  = when (intent?.getIntExtra(BatteryManager.EXTRA_STATUS, -1)) {
            BatteryManager.BATTERY_STATUS_CHARGING     -> "Charging"
            BatteryManager.BATTERY_STATUS_DISCHARGING  -> "Discharging"
            BatteryManager.BATTERY_STATUS_FULL         -> "Full"
            BatteryManager.BATTERY_STATUS_NOT_CHARGING -> "Not Charging"
            else                                        -> "Unknown"
        }

        val plugged = when (intent?.getIntExtra(BatteryManager.EXTRA_PLUGGED, -1)) {
            BatteryManager.BATTERY_PLUGGED_AC     -> "AC"
            BatteryManager.BATTERY_PLUGGED_USB    -> "USB"
            BatteryManager.BATTERY_PLUGGED_WIRELESS -> "Wireless"
            else                                   -> null
        }

        val health  = when (intent?.getIntExtra(BatteryManager.EXTRA_HEALTH, -1)) {
            BatteryManager.BATTERY_HEALTH_GOOD            -> "Good"
            BatteryManager.BATTERY_HEALTH_OVERHEAT        -> "Overheat"
            BatteryManager.BATTERY_HEALTH_DEAD            -> "Dead"
            BatteryManager.BATTERY_HEALTH_OVER_VOLTAGE    -> "Over Voltage"
            BatteryManager.BATTERY_HEALTH_COLD            -> "Cold"
            BatteryManager.BATTERY_HEALTH_UNSPECIFIED_FAILURE -> "Failure"
            else                                           -> "Unknown"
        }

        // Temperature in tenths of degrees Celsius → degrees
        val tempRaw  = intent?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, Int.MIN_VALUE) ?: Int.MIN_VALUE
        val tempC    = if (tempRaw != Int.MIN_VALUE) tempRaw / 10f else null

        val voltage  = intent?.getIntExtra(BatteryManager.EXTRA_VOLTAGE, -1)?.let {
            if (it > 0) it else null
        }

        val technology = intent?.getStringExtra(BatteryManager.EXTRA_TECHNOLOGY)

        // Capacity (mAh) — requires BATTERY_STATS permission on some OEMs
        val capacity = runCatching {
            val bm = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
            bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        }.getOrNull()

        return mapOf(
            "percentage"   to pct,
            "status"       to status,
            "plugged"      to plugged,
            "health"       to health,
            "temperatureC" to tempC,
            "voltageMv"    to voltage,
            "technology"   to technology,
            "capacity"     to capacity,
        )
    }

    // ─────────────────────────────────────────────────────────────
    // Display
    // ─────────────────────────────────────────────────────────────
    @Suppress("DEPRECATION")
    private fun getDisplayInfo(): Map<String, Any?> {
        val wm = getSystemService(Context.WINDOW_SERVICE) as WindowManager

        val (widthPx, heightPx, density, refreshRate, supportedRates) = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val metrics = wm.currentWindowMetrics
            val insets  = metrics.windowInsets
            val bounds  = metrics.bounds
            val display = display
            val dm      = DisplayMetrics().also { windowManager.defaultDisplay.getMetrics(it) }
            val rates   = display?.supportedModes?.map { it.refreshRate } ?: emptyList<Float>()
            arrayOf<Any?>(
                bounds.width(),
                bounds.height(),
                dm.density,
                display?.refreshRate,
                rates,
            )
        } else {
            val display = wm.defaultDisplay
            val dm = DisplayMetrics()
            display.getRealMetrics(dm)
            val rates = display.supportedModes?.map { it.refreshRate } ?: emptyList<Float>()
            arrayOf<Any?>(dm.widthPixels, dm.heightPixels, dm.density, display.refreshRate, rates)
        }

        return mapOf(
            "widthPx"           to widthPx,
            "heightPx"          to heightPx,
            "densityDpi"        to ((density as? Float)?.let { (it * 160).toInt() }),
            "density"           to density,
            "refreshRateHz"     to refreshRate,
            "supportedRatesHz"  to supportedRates,
        )
    }

    // ─────────────────────────────────────────────────────────────
    // CPU info (best-effort, reads /proc/cpuinfo)
    // ─────────────────────────────────────────────────────────────
    private fun getCpuInfo(): Map<String, Any?> {
        val numCores = Runtime.getRuntime().availableProcessors()

        // Try to read /proc/cpuinfo for hardware name
        val cpuHardware = runCatching {
            File("/proc/cpuinfo").readLines()
                .firstOrNull { it.startsWith("Hardware", ignoreCase = true) }
                ?.substringAfter(":")?.trim()
        }.getOrNull()

        val cpuModel = runCatching {
            File("/proc/cpuinfo").readLines()
                .firstOrNull { it.startsWith("model name", ignoreCase = true) || it.startsWith("Processor", ignoreCase = true) }
                ?.substringAfter(":")?.trim()
        }.getOrNull()

        // Read current CPU frequencies (best-effort, available on most devices)
        val freqs: List<Map<String, Any?>> = (0 until numCores).mapNotNull { core ->
            val curFreqFile   = File("/sys/devices/system/cpu/cpu$core/cpufreq/scaling_cur_freq")
            val maxFreqFile   = File("/sys/devices/system/cpu/cpu$core/cpufreq/cpuinfo_max_freq")
            val minFreqFile   = File("/sys/devices/system/cpu/cpu$core/cpufreq/cpuinfo_min_freq")
            if (curFreqFile.canRead()) {
                mapOf<String, Any?>(
                    "core"     to core,
                    "curKhz"   to curFreqFile.readText().trim().toLongOrNull(),
                    "maxKhz"   to maxFreqFile.runCatching { readText().trim().toLongOrNull() }.getOrNull(),
                    "minKhz"   to minFreqFile.runCatching { readText().trim().toLongOrNull() }.getOrNull(),
                )
            } else null
        }

        return mapOf(
            "numCores"    to numCores,
            "hardware"    to (cpuHardware ?: Build.HARDWARE),
            "model"       to cpuModel,
            "primaryAbi"  to Build.SUPPORTED_ABIS.firstOrNull(),
            "abis"        to Build.SUPPORTED_ABIS.toList(),
            "coreFreqs"   to freqs,
        )
    }

    // ─────────────────────────────────────────────────────────────
    // Convenience: fetch everything in one call
    // ─────────────────────────────────────────────────────────────
    private fun getAllDeviceInfo(): Map<String, Any?> = mapOf(
        "device"  to getBasicDeviceInfo(),
        "memory"  to getMemoryInfo(),
        "storage" to getStorageInfo(),
        "battery" to getBatteryInfo(),
        "display" to getDisplayInfo(),
        "cpu"     to getCpuInfo(),
    )

    // ─────────────────────────────────────────────────────────────
    // Game & Installed Application Discovery
    // ─────────────────────────────────────────────────────────────
    private fun getInstalledApps(includeIcons: Boolean): List<Map<String, Any?>> {
        val pm = packageManager
        val gameResolves = try {
            val gameIntent = Intent(Intent.ACTION_MAIN).apply {
                addCategory("android.intent.category.GAME")
            }
            pm.queryIntentActivities(gameIntent, 0).map { it.activityInfo.packageName }.toSet()
        } catch (e: Exception) {
            emptySet()
        }

        val launcherResolves = try {
            val launcherIntent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_LAUNCHER)
            }
            pm.queryIntentActivities(launcherIntent, 0).map { it.activityInfo.packageName }.toSet()
        } catch (e: Exception) {
            emptySet()
        }

        val flags = PackageManager.GET_META_DATA
        val packages: List<PackageInfo> = try {
            pm.getInstalledPackages(flags)
        } catch (e: Exception) {
            emptyList()
        }

        val results = mutableListOf<Map<String, Any?>>()
        val ownPackage = packageName

        for (pkg in packages) {
            val appInfo = pkg.applicationInfo ?: continue
            if (pkg.packageName == ownPackage) continue

            val pkgName = pkg.packageName
            val appLabel = runCatching { pm.getApplicationLabel(appInfo).toString() }.getOrNull() ?: pkgName
            val isSystem = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0

            val isGameCategory = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                appInfo.category == ApplicationInfo.CATEGORY_GAME
            } else {
                false
            }

            @Suppress("DEPRECATION")
            val isGameFlag = (appInfo.flags and ApplicationInfo.FLAG_IS_GAME) != 0
            val hasGameIntent = gameResolves.contains(pkgName)
            val hasLauncher = launcherResolves.contains(pkgName)

            val metaDataKeys = mutableListOf<String>()
            appInfo.metaData?.let { bundle ->
                for (key in bundle.keySet()) {
                    metaDataKeys.add(key)
                }
            }

            val iconBytes = if (includeIcons) {
                runCatching {
                    val drawable = pm.getApplicationIcon(appInfo)
                    drawableToByteArray(drawable, 96)
                }.getOrNull()
            } else null

            @Suppress("DEPRECATION")
            val versionCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                pkg.longVersionCode
            } else {
                pkg.versionCode.toLong()
            }

            val item = mapOf<String, Any?>(
                "packageName" to pkgName,
                "appName" to appLabel,
                "versionName" to pkg.versionName,
                "versionCode" to versionCode,
                "isSystemApp" to isSystem,
                "category" to if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) appInfo.category else -1,
                "isGameCategory" to isGameCategory,
                "isGameFlag" to isGameFlag,
                "hasGameIntent" to hasGameIntent,
                "hasLauncherIntent" to hasLauncher,
                "firstInstallTime" to pkg.firstInstallTime,
                "lastUpdateTime" to pkg.lastUpdateTime,
                "metaDataKeys" to metaDataKeys,
                "iconBytes" to iconBytes,
            )
            results.add(item)
        }

        return results
    }

    private fun getAppIcon(pkgName: String): ByteArray? {
        return try {
            val drawable = packageManager.getApplicationIcon(pkgName)
            drawableToByteArray(drawable, 96)
        } catch (e: Exception) {
            null
        }
    }

    private fun launchApp(pkgName: String): Boolean {
        return try {
            val intent = packageManager.getLaunchIntentForPackage(pkgName)
            if (intent != null) {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
                true
            } else {
                false
            }
        } catch (e: Exception) {
            false
        }
    }

    private fun drawableToByteArray(drawable: Drawable, size: Int = 96): ByteArray? {
        return try {
            val bitmap = if (drawable is BitmapDrawable && drawable.bitmap != null &&
                drawable.intrinsicWidth > 0 && drawable.intrinsicHeight > 0
            ) {
                Bitmap.createScaledBitmap(drawable.bitmap, size, size, true)
            } else {
                val bm = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
                val canvas = Canvas(bm)
                drawable.setBounds(0, 0, canvas.width, canvas.height)
                drawable.draw(canvas)
                bm
            }
            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 90, stream)
            stream.toByteArray()
        } catch (e: Exception) {
            null
        }
    }

    @Suppress("DEPRECATION")
    private fun String.capitalize() =
        replaceFirstChar { if (it.isLowerCase()) it.titlecase() else it.toString() }

    private fun getNetworkInfo(): Map<String, Any?> {
        return try {
            val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
            val activeNetwork = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                cm?.activeNetwork
            } else null

            val caps = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP && activeNetwork != null) {
                cm?.getNetworkCapabilities(activeNetwork)
            } else null

            val type = when {
                caps == null -> "offline"
                caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "wifi"
                caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "cellular"
                caps.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "ethernet"
                caps.hasTransport(NetworkCapabilities.TRANSPORT_VPN) -> "vpn"
                else -> "unknown"
            }

            var freqMhz: Int? = null
            var linkSpeedMbps: Int? = null
            if (type == "wifi") {
                val wm = applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
                val info = wm?.connectionInfo
                freqMhz = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    info?.frequency
                } else null
                linkSpeedMbps = info?.linkSpeed
            }

            val downSpeedKbps = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                caps?.linkDownstreamBandwidthKbps
            } else null
            val upSpeedKbps = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                caps?.linkUpstreamBandwidthKbps
            } else null

            mapOf(
                "type" to type,
                "wifiFrequencyMhz" to freqMhz,
                "wifiLinkSpeedMbps" to linkSpeedMbps,
                "downstreamKbps" to downSpeedKbps,
                "upstreamKbps" to upSpeedKbps,
            )
        } catch (e: Exception) {
            mapOf("type" to "unknown")
        }
    }

    // ── Security & Integrity Protections ──────────────────────────────────────────
    private val packageNameRegex = Pattern.compile("^[a-zA-Z][a-zA-Z0-9_]*(\\.[a-zA-Z][a-zA-Z0-9_]*)+$")

    private fun isValidPackageName(pkg: String?): Boolean {
        if (pkg.isNullOrBlank() || pkg.length > 128) return false
        return packageNameRegex.matcher(pkg).matches()
    }

    private fun getAppIntegrityInfo(): Map<String, Any?> {
        val appInfo = applicationInfo
        val isDebuggable = (appInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0

        val installerPackage = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            try {
                packageManager.getInstallSourceInfo(packageName).installingPackageName
            } catch (e: Exception) { null }
        } else {
            @Suppress("DEPRECATION")
            try {
                packageManager.getInstallerPackageName(packageName)
            } catch (e: Exception) { null }
        }

        val certSha256 = try {
            val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                val signingInfo = packageManager.getPackageInfo(
                    packageName,
                    PackageManager.GET_SIGNING_CERTIFICATES
                ).signingInfo
                if (signingInfo != null) {
                    if (signingInfo.hasMultipleSigners()) {
                        signingInfo.apkContentsSigners
                    } else {
                        signingInfo.signingCertificateHistory
                    }
                } else null
            } else {
                @Suppress("DEPRECATION")
                packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNATURES).signatures
            }

            val firstSig = signatures?.firstOrNull()
            if (firstSig != null) {
                val md = MessageDigest.getInstance("SHA-256")
                val digest = md.digest(firstSig.toByteArray())
                digest.joinToString(":") { "%02X".format(it) }
            } else null
        } catch (e: Exception) { null }

        return mapOf(
            "isDebuggable" to isDebuggable,
            "installerPackage" to installerPackage,
            "certificateSha256" to certSha256,
            "packageName" to packageName,
        )
    }
}
