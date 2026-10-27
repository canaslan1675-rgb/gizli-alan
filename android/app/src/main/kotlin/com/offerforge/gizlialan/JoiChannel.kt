package com.offerforge.gizlialan

import com.google.mlkit.genai.common.DownloadStatus
import com.google.mlkit.genai.common.FeatureStatus
import com.google.mlkit.genai.prompt.Generation
import com.google.mlkit.genai.prompt.GenerativeModel
import com.google.mlkit.genai.prompt.TextPart
import com.google.mlkit.genai.prompt.generateContentRequest
import io.flutter.plugin.common.BinaryMessenger
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
 * system AICore service ON THE DEVICE. This channel never opens a network
 * connection and has no cloud fallback: if Nano is not available the Dart
 * side shows a message and only offers the local keyword search over notes.
 * (Model download, when the user asks for it, is done by AICore / Google
 * Play services itself; no prompt or note text is part of that.)
 *
 * Methods: `status` -> "available" | "downloadable" | "downloading" |
 * "unavailable"; `download` -> starts the AICore download, returns bool;
 * `generate` {prompt} -> String.
 */
class JoiChannel private constructor(messenger: BinaryMessenger) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private var model: GenerativeModel? = null
    val channel = MethodChannel(messenger, NAME)

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
                else -> result.notImplemented()
            }
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        try { model?.close() } catch (_: Throwable) {}
        model = null
        scope.cancel()
    }

    companion object {
        const val NAME = "gizlialan/joi"
        fun attach(messenger: BinaryMessenger) = JoiChannel(messenger)
    }
}
