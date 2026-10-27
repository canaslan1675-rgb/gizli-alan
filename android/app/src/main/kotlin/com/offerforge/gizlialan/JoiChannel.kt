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
import com.google.firebase.appcheck.playintegrity.PlayIntegrityAppCheckProviderFactory
import io.flutter.plugin.common.BinaryMessenger
import java.io.IOException
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

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
 * Errors: "busy" (quota/429/5xx), "offline" (network), "failed".
 */
class JoiChannel private constructor(
    private val context: Context,
    messenger: BinaryMessenger,
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private var model: GenerativeModel? = null
    val channel = MethodChannel(messenger, NAME)

    private var online: OnlineModel? = null
    private var onlineKey: String? = null

    private fun onlineModel(apiKey: String, appId: String, projectId: String, name: String, system: String): OnlineModel {
        val key = "$appId|$name|${system.hashCode()}"
        online?.let { if (onlineKey == key) return it }
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
                try {
                    FirebaseAppCheck.getInstance(a).installAppCheckProviderFactory(
                        PlayIntegrityAppCheckProviderFactory.getInstance(),
                    )
                } catch (_: Throwable) {}
            }
        val m = Firebase.ai(app, GenerativeBackend.googleAI()).generativeModel(
            modelName = name,
            generationConfig = generationConfig {
                temperature = 0.4f
                maxOutputTokens = 400
            },
            systemInstruction = content { text(system) },
        )
        online = m
        onlineKey = key
        return m
    }

    private fun errorCode(t: Throwable): String {
        var c: Throwable? = t
        while (c != null) {
            if (c is QuotaExceededException) return "busy"
            if (c is ServerException) return "busy"
            if (c is IOException) return "offline"
            val msg = c.message ?: ""
            if (msg.contains("429") || msg.contains("RESOURCE_EXHAUSTED")) return "busy"
            if (msg.contains("UnknownHost") || msg.contains("Unable to resolve host")) return "offline"
            c = c.cause
        }
        return "failed"
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
                "onlineGenerate" -> {
                    val apiKey = call.argument<String>("apiKey") ?: ""
                    val appId = call.argument<String>("appId") ?: ""
                    val projectId = call.argument<String>("projectId") ?: ""
                    val name = call.argument<String>("model") ?: "gemini-2.5-flash"
                    val system = call.argument<String>("system") ?: ""
                    val question = (call.argument<String>("question") ?: "").take(500)
                    if (apiKey.isEmpty() || appId.isEmpty() || projectId.isEmpty() || question.isBlank()) {
                        result.error("failed", "not_configured", null)
                    } else {
                        scope.launch {
                            try {
                                val m = onlineModel(apiKey, appId, projectId, name, system)
                                result.success(m.generateContent(question).text ?: "")
                            } catch (t: Throwable) {
                                result.error(errorCode(t), t.javaClass.simpleName, null)
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
        online = null
        scope.cancel()
    }

    companion object {
        const val NAME = "gizlialan/joi"
        private const val APP_NAME = "joi"
        fun attach(context: Context, messenger: BinaryMessenger) = JoiChannel(context, messenger)
    }
}
