package com.offerforge.gizlialan

import android.os.Handler
import android.os.Looper
import android.os.Message
import android.webkit.CookieManager
import android.webkit.WebView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.webviewflutter.WebViewFlutterAndroidExternalApi

/**
 * In-vault browser hooks (#45) on the native android.webkit.WebView created
 * by webview_flutter (looked up via its public external API):
 *
 *  - DownloadListener: every download the page starts is handed to Dart
 *    (`download`), which fetches it into memory and stores it encrypted in
 *    the vault (Photos / Files). Nothing is written to public storage and the
 *    system DownloadManager is never used.
 *  - Long-press on an image (HitTestResult IMAGE_TYPE / SRC_IMAGE_ANCHOR_TYPE)
 *    → `imageLongPress` so Dart can offer "Save image to vault".
 *
 * Cookies for the URL (from the WebView's own private CookieManager), the
 * WebView user agent and the page URL (Referer) are passed along so the
 * download is fetched like the page would.
 */
object BrowserChannel {
    const val NAME = "gizlialan/browser"

    fun attach(engine: FlutterEngine): MethodChannel {
        val channel = MethodChannel(engine.dartExecutor.binaryMessenger, NAME)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "attach" -> {
                    val id = (call.argument<Number>("id"))?.toLong()
                    val wv = id?.let {
                        try { WebViewFlutterAndroidExternalApi.getWebView(engine, it) } catch (_: Exception) { null }
                    }
                    if (wv == null) {
                        result.success(false)
                    } else {
                        hook(wv, channel)
                        result.success(true)
                    }
                }
                else -> result.notImplemented()
            }
        }
        return channel
    }

    private fun info(wv: WebView, url: String): HashMap<String, Any?> = hashMapOf<String, Any?>(
        "url" to url,
        "userAgent" to wv.settings.userAgentString,
        "cookies" to try { CookieManager.getInstance().getCookie(url) } catch (_: Exception) { null },
        "referer" to wv.url,
    )

    private fun hook(wv: WebView, channel: MethodChannel) {
        wv.setDownloadListener { url, userAgent, contentDisposition, mimeType, contentLength ->
            val m = info(wv, url)
            if (!userAgent.isNullOrEmpty()) m["userAgent"] = userAgent
            m["contentDisposition"] = contentDisposition
            m["mimeType"] = mimeType
            m["contentLength"] = contentLength
            channel.invokeMethod("download", m)
        }
        wv.setOnLongClickListener {
            val hit = wv.hitTestResult
            when (hit.type) {
                WebView.HitTestResult.IMAGE_TYPE -> {
                    val src = hit.extra
                    if (src.isNullOrEmpty()) return@setOnLongClickListener false
                    channel.invokeMethod("imageLongPress", info(wv, src))
                    true
                }
                WebView.HitTestResult.SRC_IMAGE_ANCHOR_TYPE -> {
                    // extra is the link; ask the WebView for the image's src.
                    val h = Handler(Looper.getMainLooper()) { msg: Message ->
                        val src = msg.data.getString("src")?.takeIf { it.isNotEmpty() } ?: hit.extra
                        if (!src.isNullOrEmpty()) channel.invokeMethod("imageLongPress", info(wv, src))
                        true
                    }
                    wv.requestImageRef(h.obtainMessage())
                    true
                }
                else -> false
            }
        }
    }
}
