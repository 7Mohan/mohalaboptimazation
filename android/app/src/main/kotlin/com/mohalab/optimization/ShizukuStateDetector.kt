package com.mohalab.optimization

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import rikka.shizuku.Shizuku

/**
 * Pure state-detection logic for Shizuku.
 *
 * This class has NO side effects — it only reads state.
 * It does not request permissions, bind services, or make callbacks.
 *
 * State machine (evaluated in order):
 *   notInstalled      → rikka.shizuku package not present on device
 *   notRunning        → package present but Shizuku.pingBinder() == false
 *   binderConnected   → binder attached to our process
 *   permissionDenied  → binder connected, PERMISSION_USE_SERVICE denied
 *   permissionGranted → permission granted, service considered usable
 *   ready             → all checks pass
 *
 * Note: "serviceRunning" (binder alive, not yet bound) is a transient state
 * that resolves quickly after the binder callback fires. We represent it here
 * as "notRunning" until the binder attaches, then directly as "binderConnected".
 */
internal class ShizukuStateDetector(private val context: Context) {

    companion object {
        // String codes sent over MethodChannel — must match Dart ShizukuStatus enum
        const val STATE_NOT_INSTALLED      = "notInstalled"
        const val STATE_NOT_RUNNING        = "notRunning"
        const val STATE_BINDER_CONNECTED   = "binderConnected"
        const val STATE_PERMISSION_DENIED  = "permissionDenied"
        const val STATE_PERMISSION_GRANTED = "permissionGranted"
        const val STATE_READY              = "ready"

        val SHIZUKU_PACKAGES = listOf(
            "moe.shizuku.privileged.api",
            "rikka.shizuku",
            "rikka.sui"
        )
    }

    /**
     * Returns the current Shizuku state code string.
     * Safe to call from any thread.
     */
    fun detectState(): String {
        // 1. If the Shizuku service binder is alive, evaluate connection & permission
        val binderAlive = try {
            Shizuku.pingBinder()
        } catch (e: Throwable) {
            false
        }

        if (binderAlive) {
            val permissionResult = try {
                Shizuku.checkSelfPermission()
            } catch (e: Exception) {
                return STATE_BINDER_CONNECTED
            }

            return when (permissionResult) {
                PackageManager.PERMISSION_GRANTED -> STATE_READY
                PackageManager.PERMISSION_DENIED  -> STATE_PERMISSION_DENIED
                else                               -> STATE_BINDER_CONNECTED
            }
        }

        // 2. If binder is not alive, check if Shizuku is installed on the device
        if (isShizukuInstalled()) {
            return STATE_NOT_RUNNING
        }

        return STATE_NOT_INSTALLED
    }

    /** Returns true if any Shizuku / Sui manager package is installed on the device. */
    fun isShizukuInstalled(): Boolean {
        for (pkg in SHIZUKU_PACKAGES) {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    context.packageManager.getPackageInfo(
                        pkg,
                        PackageManager.PackageInfoFlags.of(0),
                    )
                } else {
                    @Suppress("DEPRECATION")
                    context.packageManager.getPackageInfo(pkg, 0)
                }
                return true
            } catch (e: PackageManager.NameNotFoundException) {
                // Check next package
            } catch (e: Exception) {
                // Continue
            }
        }
        return false
    }

    /** Returns true only when permission is granted AND binder is alive. */
    fun isReady(): Boolean = detectState() == STATE_READY

    /** Returns true when permission is granted (regardless of final readiness check). */
    fun hasPermission(): Boolean {
        return try {
            Shizuku.checkSelfPermission() == PackageManager.PERMISSION_GRANTED
        } catch (e: Exception) {
            false
        }
    }
}
