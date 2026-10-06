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
 *
 * Settings rows added in v0.5.1 (tester feedback), all plain system intents,
 * no SDK and no network access of our own:
 *  - `shareApp`: ACTION_SEND text/plain chooser. Dart passes a short neutral
 *    message; it must contain our Play listing link (nothing about the vault).
 *  - `openStore`: our Play listing via market:// (Play Store app), falling
 *    back to the https listing in a browser.
 *  - `sendFeedback`: ACTION_SENDTO mailto: our support address only; the
 *    subject carries the app version (no body, logs, device data or files).
 */
object SystemChannel {
    const val NAME = "gizlialan/system"
    private const val SUPPORT_SUBJECT = "GizliAlan destek"
    private const val SUPPORT_MAILTO =
        "mailto:delibaltabaris5@gmail.com?subject=GizliAlan%20destek"
    private const val FEEDBACK_ADDRESS = "delibaltabaris5@gmail.com"
    private const val PACKAGE = "com.offerforge.gizlialan"
    private const val STORE_HTTPS = "https://play.google.com/store/apps/details?id=$PACKAGE"
    private const val STORE_MARKET = "market://details?id=$PACKAGE"

    fun attach(activity: Activity, messenger: BinaryMessenger): MethodChannel {
        val channel = MethodChannel(messenger, NAME)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "openUrl" -> {
                    val url = call.argument<String>("url")
                    val uri = url?.let { Uri.parse(it) }
                    if (uri != null && uri.scheme == "mailto" && url == SUPPORT_MAILTO) {
                        // Support row (Settings): only our own address, fixed
                        // subject; no body, logs, device data or attachments.
                        // startActivity needs no <queries> entry (package
                        // visibility only limits queryIntentActivities /
                        // resolveActivity); no mail app -> caught below.
                        try {
                            activity.startActivity(
                                Intent(Intent.ACTION_SENDTO, uri)
                                    .putExtra(Intent.EXTRA_SUBJECT, SUPPORT_SUBJECT),
                            )
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                        return@setMethodCallHandler
                    }
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
                "shareApp" -> {
                    val text = call.argument<String>("text")
                    if (text == null || !text.contains(STORE_HTTPS) || text.length > 500) {
                        result.success(false)
                        return@setMethodCallHandler
                    }
                    result.success(
                        start(
                            activity,
                            Intent.createChooser(
                                Intent(Intent.ACTION_SEND)
                                    .setType("text/plain")
                                    .putExtra(Intent.EXTRA_TEXT, text),
                                call.argument<String>("title"),
                            ),
                        ),
                    )
                }
                "openStore" -> {
                    val market = Intent(Intent.ACTION_VIEW, Uri.parse(STORE_MARKET))
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_DOCUMENT or Intent.FLAG_ACTIVITY_MULTIPLE_TASK)
                    val ok = start(activity, market) ||
                        start(
                            activity,
                            Intent(Intent.ACTION_VIEW, Uri.parse(STORE_HTTPS))
                                .addCategory(Intent.CATEGORY_BROWSABLE),
                        )
                    result.success(ok)
                }
                "sendFeedback" -> {
                    val subject = call.argument<String>("subject")
                    if (subject == null || subject.length > 120) {
                        result.success(false)
                        return@setMethodCallHandler
                    }
                    result.success(
                        start(
                            activity,
                            Intent(Intent.ACTION_SENDTO, Uri.parse("mailto:$FEEDBACK_ADDRESS"))
                                .putExtra(Intent.EXTRA_EMAIL, arrayOf(FEEDBACK_ADDRESS))
                                .putExtra(Intent.EXTRA_SUBJECT, subject),
                        ),
                    )
                }
                "wipeWebData" -> result.success(wipeWebData(activity))
                "appInfo" -> result.success(appInfo(activity))
                else -> result.notImplemented()
            }
        }
        return channel
    }

    /** startActivity; false when no app can handle [intent]. Needs no <queries>. */
    private fun start(activity: Activity, intent: Intent): Boolean = try {
        activity.startActivity(intent)
        true
    } catch (e: ActivityNotFoundException) {
        false
    } catch (e: SecurityException) {
        false
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
