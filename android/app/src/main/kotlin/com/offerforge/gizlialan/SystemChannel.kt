package com.offerforge.gizlialan

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.webkit.CookieManager
import android.webkit.GeolocationPermissions
import android.webkit.WebStorage
import android.webkit.WebView
import android.webkit.WebViewDatabase
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Small platform helpers shared by both flavors.
 *
 * `openUrl`: hands an https URL (the hosted privacy policy, see
 * lib/services/privacy_link.dart) to the user's browser with a plain
 * ACTION_VIEW intent (the user's own browser app, not the in-vault one);
 * starting an activity needs no <queries> entry.
 *
 * `wipeWebData`: deletes everything the in-vault private browser (#32,
 * Android System WebView) stored in the app-private WebView directory —
 * cookies, cache, DOM/local storage, IndexedDB, geolocation grants, form and
 * HTTP-auth data. Called on vault lock ("Kilitlenince temizle").
 */
object SystemChannel {
    const val NAME = "gizlialan/system"

    fun attach(activity: Activity, messenger: BinaryMessenger): MethodChannel {
        val channel = MethodChannel(messenger, NAME)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "openUrl" -> {
                    val url = call.argument<String>("url")
                    val uri = url?.let { Uri.parse(it) }
                    if (uri == null || uri.scheme != "https" || uri.host.isNullOrEmpty()) {
                        result.success(false)
                        return@setMethodCallHandler
                    }
                    try {
                        activity.startActivity(
                            Intent(Intent.ACTION_VIEW, uri).addCategory(Intent.CATEGORY_BROWSABLE),
                        )
                        result.success(true)
                    } catch (e: ActivityNotFoundException) {
                        result.success(false)
                    }
                }
                "wipeWebData" -> result.success(wipeWebData(activity))
                "appInfo" -> result.success(appInfo(activity))
                else -> result.notImplemented()
            }
        }
        return channel
    }

    /** versionName / versionCode of the installed APK (vault home watermark). */
    private fun appInfo(activity: Activity): Map<String, Any?>? = try {
        val info = activity.packageManager.getPackageInfo(activity.packageName, 0)
        mapOf("versionName" to info.versionName, "versionCode" to info.longVersionCode)
    } catch (e: Exception) {
        null
    }

    private fun wipeWebData(activity: Activity): Boolean = try {
        CookieManager.getInstance().apply {
            removeAllCookies(null)
            removeSessionCookies(null)
            flush()
        }
        WebStorage.getInstance().deleteAllData()
        GeolocationPermissions.getInstance().clearAll()
        @Suppress("DEPRECATION")
        WebViewDatabase.getInstance(activity).apply {
            clearHttpAuthUsernamePassword()
            clearFormData()
        }
        WebView(activity).apply {
            clearCache(true)
            clearFormData()
            clearHistory()
            destroy()
        }
        true
    } catch (e: Exception) {
        false
    }
}
