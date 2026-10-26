package com.offerforge.gizlialan

import android.content.Context
import android.content.pm.ApplicationInfo
import android.util.Log
import com.tiktok.TikTokBusinessSdk
import com.tiktok.appevents.contents.TTContentsEventConstants
import com.tiktok.appevents.contents.TTPurchaseEvent
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * "gizlialan/tiktok" — TikTok Business (App Events) SDK bridge.
 *
 * - init(appSecret, ttAppId, debug, enabled): initialises the SDK. The App
 *   Secret comes from a build-time --dart-define (never in git). Install /
 *   launch / 2-day retention are tracked automatically by the SDK; auto IAP
 *   tracking is off (the Purchase event is sent once from Dart). Debug mode
 *   only when the Dart side is a debug build. No identify(): no user ids.
 * - setEnabled(enabled): Settings opt-out → stop / start tracking.
 * - logPurchase(currency, value, contentId): Pro purchase.
 */
object TikTokChannel {
    const val NAME = "gizlialan/tiktok"
    private const val TAG = "GizliAlanTT"

    fun attach(context: Context, messenger: BinaryMessenger): MethodChannel {
        val app = context.applicationContext
        val channel = MethodChannel(messenger, NAME)
        channel.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "init" -> result.success(init(app, call.argument("appSecret"),
                        call.argument("ttAppId"), call.argument<Boolean>("debug") == true,
                        call.argument<Boolean>("enabled") != false))
                    "setEnabled" -> {
                        if (TikTokBusinessSdk.isInitialized()) {
                            if (call.argument<Boolean>("enabled") != false) {
                                TikTokBusinessSdk.startTrack()
                            }
                            TikTokBusinessSdk.setSdkGlobalSwitch(call.argument<Boolean>("enabled") != false)
                        }
                        result.success(true)
                    }
                    "logPurchase" -> {
                        if (!TikTokBusinessSdk.isInitialized()) {
                            result.success(false)
                        } else {
                            val currency = runCatching {
                                TTContentsEventConstants.Currency.valueOf(
                                    call.argument<String>("currency") ?: "TRY",
                                )
                            }.getOrDefault(TTContentsEventConstants.Currency.TRY)
                            val b = TTPurchaseEvent.newBuilder()
                                .setCurrency(currency)
                                .setValue(call.argument<Number>("value")?.toDouble() ?: 0.0)
                                .setContentType("product")
                            call.argument<String>("contentId")?.let { b.setContentId(it) }
                            TikTokBusinessSdk.trackTTEvent(b.build())
                            result.success(true)
                        }
                    }
                    else -> result.notImplemented()
                }
            } catch (t: Throwable) {
                if (isDebuggable(app)) Log.w(TAG, "TikTok call failed: ${call.method}", t)
                result.success(false)
            }
        }
        return channel
    }

    private fun init(app: Context, secret: String?, ttAppId: String?, debug: Boolean, enabled: Boolean): Boolean {
        if (TikTokBusinessSdk.isInitialized()) return true
        if (secret.isNullOrEmpty() || ttAppId.isNullOrEmpty()) return false
        val config = TikTokBusinessSdk.TTConfig(app, secret)
            .setAppId(app.packageName)
            .setTTAppId(ttAppId)
            .disableAutoIapTrack()
        if (!enabled) config.disableAutoStart()
        if (debug && isDebuggable(app)) {
            config.openDebugMode().setLogLevel(TikTokBusinessSdk.LogLevel.INFO)
        }
        TikTokBusinessSdk.initializeSdk(config, object : TikTokBusinessSdk.TTInitCallback {
            override fun success() {}
            override fun fail(code: Int, msg: String?) {
                if (isDebuggable(app)) Log.w(TAG, "TikTok init failed: $code")
            }
        })
        if (enabled) TikTokBusinessSdk.startTrack() else TikTokBusinessSdk.setSdkGlobalSwitch(false)
        return true
    }

    private fun isDebuggable(app: Context): Boolean =
        (app.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
}
