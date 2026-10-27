package com.offerforge.gizlialan

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import com.google.android.play.core.appupdate.AppUpdateManager
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.appupdate.AppUpdateOptions
import com.google.android.play.core.install.InstallStateUpdatedListener
import com.google.android.play.core.install.model.AppUpdateType
import com.google.android.play.core.install.model.InstallStatus
import com.google.android.play.core.install.model.UpdateAvailability
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Google Play In-App Updates, flexible flow (0.6.2). Only does anything when
 * the app was installed by Google Play; sideloaded / test APKs report
 * "no update" silently. Methods: currentVersionCode, check ->
 * {available, versionCode}, start -> bool, complete, openPlay.
 * Events to Dart: "downloaded".
 */
class UpdateChannel private constructor(
    private val activity: Activity,
    messenger: BinaryMessenger,
) {
    val channel = MethodChannel(messenger, NAME)
    private val manager: AppUpdateManager? = try {
        AppUpdateManagerFactory.create(activity)
    } catch (_: Throwable) { null }
    private val listener = InstallStateUpdatedListener { st ->
        if (st.installStatus() == InstallStatus.DOWNLOADED) {
            activity.runOnUiThread { channel.invokeMethod("downloaded", null) }
        }
    }

    private fun fromPlay(): Boolean = try {
        val pm = activity.packageManager
        val src = if (Build.VERSION.SDK_INT >= 30) {
            pm.getInstallSourceInfo(activity.packageName).installingPackageName
        } else {
            @Suppress("DEPRECATION") pm.getInstallerPackageName(activity.packageName)
        }
        src == "com.android.vending"
    } catch (_: Throwable) { false }

    private fun versionCode(): Long = try {
        val pi = activity.packageManager.getPackageInfo(activity.packageName, 0)
        if (Build.VERSION.SDK_INT >= 28) pi.longVersionCode else @Suppress("DEPRECATION") pi.versionCode.toLong()
    } catch (_: Throwable) { 0L }

    init {
        try { manager?.registerListener(listener) } catch (_: Throwable) {}
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "currentVersionCode" -> result.success(versionCode())
                "check" -> {
                    val m = manager
                    if (m == null || !fromPlay()) {
                        result.success(mapOf("available" to false, "playInstall" to false))
                    } else {
                        try {
                            m.appUpdateInfo.addOnSuccessListener { info ->
                                val ok = info.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE &&
                                    info.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE)
                                result.success(
                                    mapOf(
                                        "available" to ok,
                                        "playInstall" to true,
                                        "versionCode" to info.availableVersionCode(),
                                        "downloaded" to (info.installStatus() == InstallStatus.DOWNLOADED),
                                    ),
                                )
                            }.addOnFailureListener {
                                result.success(mapOf("available" to false, "playInstall" to true))
                            }
                        } catch (_: Throwable) {
                            result.success(mapOf("available" to false))
                        }
                    }
                }
                "start" -> {
                    val m = manager
                    if (m == null) { result.success(false) } else {
                        m.appUpdateInfo.addOnSuccessListener { info ->
                            try {
                                @Suppress("DEPRECATION")
                                val ok = m.startUpdateFlowForResult(
                                    info, activity,
                                    AppUpdateOptions.defaultOptions(AppUpdateType.FLEXIBLE), REQ,
                                )
                                result.success(ok)
                            } catch (_: Throwable) { result.success(false) }
                        }.addOnFailureListener { result.success(false) }
                    }
                }
                "complete" -> {
                    try { manager?.completeUpdate() } catch (_: Throwable) {}
                    result.success(null)
                }
                "openPlay" -> {
                    try {
                        activity.startActivity(
                            Intent(Intent.ACTION_VIEW, Uri.parse("https://play.google.com/store/apps/details?id=" + activity.packageName))
                                .setPackage("com.android.vending"),
                        )
                    } catch (_: Throwable) {
                        try {
                            activity.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://play.google.com/store/apps/details?id=" + activity.packageName)))
                        } catch (_: Throwable) {}
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        try { manager?.unregisterListener(listener) } catch (_: Throwable) {}
    }

    companion object {
        const val NAME = "gizlialan/update"
        private const val REQ = 7312
        fun attach(activity: Activity, messenger: BinaryMessenger) = UpdateChannel(activity, messenger)
    }
}
