package com.mohalab.optimization

import android.content.pm.PackageManager
import rikka.shizuku.Shizuku

/**
 * Handles Shizuku permission requests and their results.
 *
 * Shizuku permission is NOT an Android system permission — it is managed
 * by the Shizuku service itself via a custom binder callback.
 *
 * Usage:
 *   1. Call requestPermission(requestCode) to show the Shizuku permission dialog.
 *   2. The result arrives in onRequestPermissionsResult — forward it via [setResultCallback].
 *   3. Clean up by calling [unregister] when the Activity is destroyed.
 */
internal class ShizukuPermissionHandler {

    /** Callback invoked when the permission request resolves. */
    private var pendingResultCallback: ((granted: Boolean) -> Unit)? = null

    /**
     * The listener Shizuku calls with the permission result.
     * Must be registered with Shizuku and kept alive (no anonymous lambdas).
     */
    private val permissionResultListener =
        Shizuku.OnRequestPermissionResultListener { requestCode, grantResult ->
            if (requestCode == SHIZUKU_PERMISSION_REQUEST_CODE) {
                val granted = grantResult == PackageManager.PERMISSION_GRANTED
                pendingResultCallback?.invoke(granted)
                pendingResultCallback = null
            }
        }

    /** Register the listener. Call once when the bridge is created. */
    fun register() {
        try {
            Shizuku.addRequestPermissionResultListener(permissionResultListener)
        } catch (e: Exception) {
            // Shizuku might not be available — fail silently; state detection will
            // return notInstalled / notRunning rather than crash.
        }
    }

    /** Unregister the listener. Call in Activity onDestroy. */
    fun unregister() {
        try {
            Shizuku.removeRequestPermissionResultListener(permissionResultListener)
        } catch (e: Exception) {
            // Ignored — may already be detached
        }
        pendingResultCallback = null
    }

    /**
     * Issues a Shizuku permission request dialog.
     *
     * @param onResult Called on the calling thread with true if granted, false otherwise.
     */
    fun requestPermission(onResult: (Boolean) -> Unit) {
        // If permission already granted, resolve immediately
        val alreadyGranted = try {
            Shizuku.checkSelfPermission() == PackageManager.PERMISSION_GRANTED
        } catch (e: Exception) {
            false
        }

        if (alreadyGranted) {
            onResult(true)
            return
        }

        // Queue the callback and issue the request
        pendingResultCallback = onResult
        try {
            Shizuku.requestPermission(SHIZUKU_PERMISSION_REQUEST_CODE)
        } catch (e: Exception) {
            // Binder is dead or not connected — resolve as denied
            pendingResultCallback = null
            onResult(false)
        }
    }

    companion object {
        // Arbitrary stable request code — must not collide with Android system codes
        private const val SHIZUKU_PERMISSION_REQUEST_CODE = 1001
    }
}
