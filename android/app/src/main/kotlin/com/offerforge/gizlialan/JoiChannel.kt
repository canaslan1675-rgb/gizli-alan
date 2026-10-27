package com.offerforge.gizlialan

import com.google.mlkit.genai.common.DownloadStatus
import com.google.mlkit.genai.common.FeatureStatus
import com.google.mlkit.genai.prompt.Generation
import com.google.mlkit.genai.prompt.GenerativeModel
import com.google.mlkit.genai.prompt.TextPart
import com.google.mlkit.genai.prompt.generateContentRequest
import android.content.Context
import com.google.firebase.Firebase
import com.google.firebase.FirebaseApp
import com.google.firebase.FirebaseOptions
import com.google.firebase.ai.GenerativeModel as OnlineModel
import com.google.firebase.ai.ai
import com.google.firebase.ai.type.GenerativeBackend
import com.google.firebase.ai.type.QuotaExceededException
import com.google.firebase.ai.type.ServerException
import com.google.firebase.ai.type.content
import com.google.firebase.ai.type.generationConfig
import com.google.firebase.appcheck.FirebaseAppCheck
import com.google.firebase.appcheck.debug.DebugAppCheckProviderFactory
import com.google.firebase.appcheck.playintegrity.PlayIntegrityAppCheckProviderFactory
import io.flutter.plugin.common.BinaryMessenger
import java.io.IOException
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeout
import kotlinx.coroutines.TimeoutCancellationException

/**
 * "Joi" — GizliAlan's on-device assistant (0.6.2).
 *
 * Gemini Nano through the ML Kit GenAI Prompt API, which runs inside the
 * system AICore service ON THE DEVICE (`status`/`download`/`generate`).
 *
 * `onlineGenerate` {apiKey, appId, projectId, model, system, question}:
 * opt-in online fallback for GENERAL questions on phones without Nano —
 * Gemini via Firebase AI Logic (Gemini Developer API). Dart only calls it
 * after the user's consent and never with note content (joi_service.dart).
 * Firebase is initialised lazily here from build-time values (no
 * google-services.json), as a named app, with App Check (Play Integrity).
 * Streams partial text on `gizlialan/joi_stream`; primary + fallback model.
 * Errors: see [errorCode]; PlatformException.message = debug detail.
 */
class JoiChannel private constructor(
    private val context: Context,
    messenger: BinaryMessenger,
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private var model: GenerativeModel? = null
    val channel = MethodChannel(messenger, NAME)

    private val online = HashMap<String, OnlineModel>()
    private val stream = MethodChannel(messenger, STREAM_NAME)

    private fun onlineModel(apiKey: String, appId: String, projectId: String, name: String, system: String, debugToken: String): OnlineModel {
        val key = "$appId|$name|${system.hashCode()}"
        online[key]?.let { return it }
        val app = FirebaseApp.getApps(context).firstOrNull { it.name == APP_NAME }
            ?: FirebaseApp.initializeApp(
                context,
                FirebaseOptions.Builder()
                    .setApiKey(apiKey)
                    .setApplicationId(appId)
                    .setProjectId(projectId)
                    .build(),
                APP_NAME,
            ).also { a ->
                // App Check: Play Integrity (Play installs). Test builds made
                // with --dart-define=JOI_APPCHECK_DEBUG_TOKEN=<token registered
                // in Firebase console → App Check → Manage debug tokens> use
                // the debug provider instead, so sideloaded APKs pass after
                // enforcement. If the token can't be obtained the SDK still
                // sends the request; an enforced backend then rejects it and
                // Dart shows "Joi şu an yoğun" (no crash).
                try {
                    val ac = FirebaseAppCheck.getInstance(a)
                    if (debugToken.isNotBlank()) {
                        context.getSharedPreferences(
                            "com.google.firebase.appcheck.debug.store." + a.persistenceKey,
                            Context.MODE_PRIVATE,
                        ).edit().putString(
                            "com.google.firebase.appcheck.debug.DEBUG_SECRET",
                            debugToken,
                        ).apply()
                        ac.installAppCheckProviderFactory(DebugAppCheckProviderFactory.getInstance())
                    } else {
                        ac.installAppCheckProviderFactory(
                            PlayIntegrityAppCheckProviderFactory.getInstance(),
                        )
                    }
                    ac.setTokenAutoRefreshEnabled(false)
                } catch (_: Throwable) {}
            }
        val m = Firebase.ai(app, GenerativeBackend.googleAI()).generativeModel(
            modelName = name,
            generationConfig = generationConfig {
                // Natural, less repetitive answers; room for recipes/poems.
                temperature = 0.7f
                topP = 0.95f
                maxOutputTokens = 1024
                // flash-lite models don't think by default; an explicit
                // thinkingBudget=0 is rejected (400) by them, so none is set.
            },
            systemInstruction = content { text(system) },
        )
        online[key] = m
        return m
    }

    /**
     * Error class for Dart (distinct Turkish message per class):
     * timeout | quota (429) | auth (401/403: App Check, API key restriction,
     * missing SHA, AI Logic API disabled) | model (400/404: model name or
     * config) | server (5xx) | offline | failed.
     */
    private fun errorCode(t: Throwable): String {
        var c: Throwable? = t
        while (c != null) {
            if (c is TimeoutCancellationException || c is FirstTokenTimeout) return "timeout"
            if (c is QuotaExceededException) return "quota"
            if (c is IOException) return "offline"
            val msg = (c.javaClass.simpleName + " " + (c.message ?: ""))
            if (msg.contains("429") || msg.contains("RESOURCE_EXHAUSTED") || msg.contains("Quota")) return "quota"
            if (msg.contains("403") || msg.contains("401") ||
                msg.contains("PERMISSION_DENIED") || msg.contains("UNAUTHENTICATED") ||
                msg.contains("App Check", ignoreCase = true) || msg.contains("AppCheck") ||
                msg.contains("InvalidAPIKey") || msg.contains("ServiceDisabled") ||
                msg.contains("API_KEY")
            ) return "auth"
            if (msg.contains("404") || msg.contains("NOT_FOUND") || msg.contains("400") ||
                msg.contains("INVALID_ARGUMENT")
            ) return "model"
            if (msg.contains("UnknownHost") || msg.contains("Unable to resolve host") ||
                msg.contains("ConnectException") || msg.contains("SocketTimeout")
            ) return "offline"
            if (c is ServerException) return "server"
            c = c.cause
        }
        return "failed"
    }

    private fun detail(t: Throwable): String {
        val root = generateSequence(t) { it.cause }.last()
        return (t.javaClass.simpleName + ": " + (t.message ?: root.message ?: ""))
            .replace(Regex("AIza[0-9A-Za-z_-]+"), "AIza…").take(160)
    }

    /**
     * Streams one answer: primary model, then the fallback model if the
     * first fails or gives no first token within [FIRST_TOKEN_MS]. Partial
     * text goes to Dart over [STREAM_NAME] ("chunk" {id, text}).
     */
    private suspend fun streamAnswer(
        id: Int, models: List<String>, apiKey: String, appId: String,
        projectId: String, system: String, debugToken: String, question: String,
        history: List<Map<String, String>> = emptyList(),
    ): String {
        var last: Throwable? = null
        val tried = ArrayList<String>()
        for (name in models.filter { it.isNotBlank() }.distinct()) {
            val sb = StringBuilder()
            try {
                val m = onlineModel(apiKey, appId, projectId, name, system, debugToken)
                withTimeout(TOTAL_MS) {
                    coroutineScope {
                        var gotFirst = false
                        // A non-cancellation exception here fails the scope
                        // and so stops the stream.
                        val guard = launch {
                            delay(FIRST_TOKEN_MS)
                            if (!gotFirst) throw FirstTokenTimeout()
                        }
                        val contents = history.map { h ->
                            content(role = if (h["role"] == "model") "model" else "user") {
                                text(h["text"] ?: "")
                            }
                        } + content(role = "user") { text(question) }
                        m.generateContentStream(contents).collect { r ->
                            val piece = r.text ?: ""
                            if (piece.isNotEmpty()) {
                                gotFirst = true
                                guard.cancel()
                                sb.append(piece)
                                stream.invokeMethod(
                                    "chunk",
                                    mapOf("id" to id, "text" to sb.toString(), "model" to name),
                                )
                            }
                        }
                        guard.cancel()
                    }
                }
                if (sb.isNotBlank()) return sb.toString()
                tried.add("$name:empty")
            } catch (t: Throwable) {
                // Got part of an answer already: keep it rather than retry.
                if (sb.isNotBlank()) return sb.toString()
                last = t
                tried.add("$name:${errorCode(t)}")
            }
        }
        throw JoiOnlineFailure(last?.let { errorCode(it) } ?: "failed",
            tried.joinToString(" → ") + (last?.let { " | " + detail(it) } ?: ""))
    }

    private fun model(): GenerativeModel = model ?: Generation.getClient().also { model = it }

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "status" -> scope.launch {
                    val s = try {
                        when (model().checkStatus()) {
                            FeatureStatus.AVAILABLE -> "available"
                            FeatureStatus.DOWNLOADABLE -> "downloadable"
                            FeatureStatus.DOWNLOADING -> "downloading"
                            else -> "unavailable"
                        }
                    } catch (t: Throwable) {
                        "unavailable"
                    }
                    result.success(s)
                }
                "download" -> scope.launch {
                    var ok = false
                    try {
                        model().download().collect { st ->
                            if (st is DownloadStatus.DownloadCompleted) ok = true
                        }
                    } catch (t: Throwable) {
                        ok = false
                    }
                    result.success(ok)
                }
                "generate" -> {
                    val prompt = call.argument<String>("prompt") ?: ""
                    scope.launch {
                        try {
                            val resp = model().generateContent(
                                generateContentRequest(TextPart(prompt)) {
                                    temperature = 0.3f
                                    topK = 16
                                    maxOutputTokens = 512
                                },
                            )
                            result.success(resp.candidates.firstOrNull()?.text ?: "")
                        } catch (t: Throwable) {
                            result.error("joi_failed", t.javaClass.simpleName, null)
                        }
                    }
                }
                "canSaveToPictures" -> result.success(android.os.Build.VERSION.SDK_INT >= 29)
                "saveToPictures" -> {
                    // MediaStore, Pictures/GizliAlan/Joi. Android 10+ only (no
                    // storage permission needed); older versions: vault only.
                    val bytes = call.argument<ByteArray>("bytes")
                    val name = call.argument<String>("name") ?: "joi.jpg"
                    val mime = call.argument<String>("mime") ?: "image/jpeg"
                    val desc = call.argument<String>("description") ?: ""
                    if (android.os.Build.VERSION.SDK_INT < 29 || bytes == null) {
                        result.error("unsupported", null, null)
                    } else {
                        try {
                            val cr = context.contentResolver
                            val v = android.content.ContentValues().apply {
                                put(android.provider.MediaStore.Images.Media.DISPLAY_NAME, name)
                                put(android.provider.MediaStore.Images.Media.MIME_TYPE, mime)
                                put(android.provider.MediaStore.Images.Media.DESCRIPTION, desc.take(1000))
                                put(android.provider.MediaStore.Images.Media.RELATIVE_PATH, "Pictures/GizliAlan/Joi")
                                put(android.provider.MediaStore.Images.Media.IS_PENDING, 1)
                            }
                            val uri = cr.insert(
                                android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI, v,
                            ) ?: throw IOException("insert failed")
                            cr.openOutputStream(uri)?.use { it.write(bytes) }
                                ?: throw IOException("open failed")
                            v.clear()
                            v.put(android.provider.MediaStore.Images.Media.IS_PENDING, 0)
                            cr.update(uri, v, null, null)
                            result.success(uri.toString())
                        } catch (t: Throwable) {
                            result.error("failed", t.javaClass.simpleName, null)
                        }
                    }
                }
                "onlineGenerate" -> {
                    val apiKey = call.argument<String>("apiKey") ?: ""
                    val appId = call.argument<String>("appId") ?: ""
                    val projectId = call.argument<String>("projectId") ?: ""
                    val models = listOf(
                        call.argument<String>("model") ?: "gemini-3.5-flash-lite",
                        call.argument<String>("fallbackModel") ?: "gemini-flash-lite-latest",
                    )
                    val debugToken = call.argument<String>("appCheckDebugToken") ?: ""
                    val system = call.argument<String>("system") ?: ""
                    val question = (call.argument<String>("question") ?: "").take(1000)
                    val history = (call.argument<List<Map<String, String>>>("history") ?: emptyList())
                        .takeLast(20)
                    val id = call.argument<Int>("id") ?: 0
                    if (apiKey.isEmpty() || appId.isEmpty() || projectId.isEmpty() || question.isBlank()) {
                        result.error("failed", "not_configured", null)
                    } else {
                        scope.launch {
                            try {
                                result.success(
                                    streamAnswer(id, models, apiKey, appId, projectId, system, debugToken, question, history),
                                )
                            } catch (f: JoiOnlineFailure) {
                                result.error(f.code, f.detail, null)
                            } catch (t: Throwable) {
                                result.error(errorCode(t), detail(t), null)
                            }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        try { model?.close() } catch (_: Throwable) {}
        model = null
        online.clear()
        scope.cancel()
    }

    companion object {
        const val NAME = "gizlialan/joi"
        const val STREAM_NAME = "gizlialan/joi_stream"
        private const val APP_NAME = "joi"
        private const val FIRST_TOKEN_MS = 12_000L
        private const val TOTAL_MS = 30_000L
        fun attach(context: Context, messenger: BinaryMessenger) = JoiChannel(context, messenger)
    }
}

private class JoiOnlineFailure(val code: String, val detail: String) : Exception(detail)

/** No first token within FIRST_TOKEN_MS (fails the stream scope). */
private class FirstTokenTimeout : Exception("first_token_timeout")
