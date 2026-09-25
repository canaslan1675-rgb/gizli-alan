package com.offerforge.gizlialan

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Small platform helpers shared by both flavors.
 *
 * `openUrl`: hands an https URL (the hosted privacy policy, see
 * lib/services/privacy_link.dart) to the user's browser with a plain
 * ACTION_VIEW intent. GizliAlan itself does no networking and keeps having no
 * INTERNET permission; starting an activity needs no <queries> entry.
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
                else -> result.notImplemented()
            }
        }
        return channel
    }
}
