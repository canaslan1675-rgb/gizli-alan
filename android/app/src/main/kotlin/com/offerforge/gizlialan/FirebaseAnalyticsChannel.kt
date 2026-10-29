package com.offerforge.gizlialan

import android.content.Context
import android.os.Bundle
import android.util.Log
import com.google.firebase.FirebaseApp
import com.google.firebase.FirebaseOptions
import com.google.firebase.analytics.FirebaseAnalytics
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * "gizlialan/fa" — Google Analytics for Firebase (0.6.5): near real-time
 * active users + a few key events. No google-services.json: the DEFAULT
 * FirebaseApp is initialised at runtime from the same --dart-define values
 * Joi online uses. Without them (tests/local builds) nothing is touched.
 * Only event names + small enum/number params are sent; never user text.
 * Settings opt-out → setAnalyticsCollectionEnabled(false).
 */
object FirebaseAnalyticsChannel {
    const val NAME = "gizlialan/fa"
    private const val TAG = "GizliAlanFA"
    private var fa: FirebaseAnalytics? = null

    fun attach(context: Context, messenger: BinaryMessenger): MethodChannel {
        val app = context.applicationContext
        val channel = MethodChannel(messenger, NAME)
        channel.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "init" -> result.success(init(app, call.argument("apiKey"), call.argument("appId"),
                        call.argument("projectId"), call.argument<Boolean>("enabled") != false))
                    "setEnabled" -> {
                        fa?.setAnalyticsCollectionEnabled(call.argument<Boolean>("enabled") != false)
                        result.success(fa != null)
                    }
                    "logEvent" -> {
                        val f = fa
                        if (f == null) { result.success(false); return@setMethodCallHandler }
                        val b = Bundle()
                        (call.argument<Map<String, Any?>>("params") ?: emptyMap()).forEach { (k, v) ->
                            when (v) {
                                is String -> b.putString(k, v.take(100))
                                is Int -> b.putLong(k, v.toLong())
                                is Long -> b.putLong(k, v)
                                is Double -> b.putDouble(k, v)
                                is Boolean -> b.putLong(k, if (v) 1L else 0L)
                            }
                        }
                        f.logEvent(call.argument<String>("name") ?: "unknown", b)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            } catch (t: Throwable) {
                Log.w(TAG, "fa ${call.method} failed: ${t.javaClass.simpleName}")
                result.success(false)
            }
        }
        return channel
    }

    private fun init(app: Context, apiKey: String?, appId: String?, projectId: String?, enabled: Boolean): Boolean {
        if (apiKey.isNullOrBlank() || appId.isNullOrBlank() || projectId.isNullOrBlank()) return false
        if (FirebaseApp.getApps(app).none { it.name == FirebaseApp.DEFAULT_APP_NAME }) {
            FirebaseApp.initializeApp(
                app,
                FirebaseOptions.Builder()
                    .setApiKey(apiKey)
                    .setApplicationId(appId)
                    .setProjectId(projectId)
                    .setGcmSenderId(appId.split(":").getOrNull(1).orEmpty())
                    .build(),
            )
        }
        val f = FirebaseAnalytics.getInstance(app)
        f.setAnalyticsCollectionEnabled(enabled)
        fa = f
        return true
    }
}
