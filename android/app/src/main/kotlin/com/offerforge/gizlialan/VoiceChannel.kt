package com.offerforge.gizlialan

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

/**
 * Joi voice (0.6.2): Android's built-in SpeechRecognizer (speech → text,
 * on-device recogniser preferred) and TextToSpeech (answers read aloud).
 * Audio is handled by the system speech service; GizliAlan never records
 * or stores audio itself. RECORD_AUDIO is requested only when the user
 * first taps the mic.
 *
 * Methods: hasMicPermission, requestMicPermission -> bool,
 * listen {lang} -> String? (null = nothing heard / cancelled; error code on
 * failure), stopListening, speak {text, lang} -> bool (returns when done),
 * stopSpeaking. Partial transcripts are sent back as "partial" {text}.
 */
class VoiceChannel private constructor(
    private val activity: Activity,
    messenger: BinaryMessenger,
) {
    val channel = MethodChannel(messenger, NAME)
    private var recognizer: SpeechRecognizer? = null
    private var listenResult: MethodChannel.Result? = null
    private var permResult: MethodChannel.Result? = null
    private var tts: TextToSpeech? = null
    private var ttsReady = false
    private var speakResult: MethodChannel.Result? = null

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "hasMicPermission" -> result.success(hasMic())
                "requestMicPermission" -> {
                    if (hasMic()) {
                        result.success(true)
                    } else {
                        permResult?.success(false)
                        permResult = result
                        ActivityCompat.requestPermissions(
                            activity, arrayOf(Manifest.permission.RECORD_AUDIO), REQ_MIC,
                        )
                    }
                }
                "isRecognitionAvailable" ->
                    result.success(SpeechRecognizer.isRecognitionAvailable(activity))
                "listen" -> listen(call.argument<String>("lang") ?: "tr-TR", result)
                "stopListening" -> {
                    try { recognizer?.stopListening() } catch (_: Throwable) {}
                    result.success(null)
                }
                "speak" -> speak(
                    call.argument<String>("text") ?: "",
                    call.argument<String>("lang") ?: "tr-TR",
                    result,
                )
                "stopSpeaking" -> {
                    try { tts?.stop() } catch (_: Throwable) {}
                    finishSpeak(false)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun hasMic() = ContextCompat.checkSelfPermission(
        activity, Manifest.permission.RECORD_AUDIO,
    ) == PackageManager.PERMISSION_GRANTED

    fun onPermissionResult(requestCode: Int, grantResults: IntArray): Boolean {
        if (requestCode != REQ_MIC) return false
        val ok = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
        permResult?.success(ok)
        permResult = null
        return true
    }

    private fun listen(lang: String, result: MethodChannel.Result) {
        if (!hasMic()) { result.error("no_permission", null, null); return }
        if (!SpeechRecognizer.isRecognitionAvailable(activity)) {
            result.error("unavailable", null, null); return
        }
        listenResult?.success(null)
        listenResult = result
        try {
            recognizer?.destroy()
            // Prefer the on-device recogniser (Android 12+ when present).
            val r = if (Build.VERSION.SDK_INT >= 31 &&
                SpeechRecognizer.isOnDeviceRecognitionAvailable(activity)
            ) {
                SpeechRecognizer.createOnDeviceSpeechRecognizer(activity)
            } else {
                SpeechRecognizer.createSpeechRecognizer(activity)
            }
            recognizer = r
            r.setRecognitionListener(object : RecognitionListener {
                override fun onReadyForSpeech(p: Bundle?) {}
                override fun onBeginningOfSpeech() {}
                override fun onRmsChanged(v: Float) {}
                override fun onBufferReceived(b: ByteArray?) {}
                override fun onEndOfSpeech() {}
                override fun onEvent(t: Int, p: Bundle?) {}
                override fun onPartialResults(p: Bundle?) {
                    val s = p?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull()
                    if (!s.isNullOrBlank()) channel.invokeMethod("partial", mapOf("text" to s))
                }
                override fun onResults(p: Bundle?) {
                    val s = p?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull()
                    finishListen(s)
                }
                override fun onError(error: Int) {
                    when (error) {
                        SpeechRecognizer.ERROR_NO_MATCH,
                        SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> finishListen(null)
                        SpeechRecognizer.ERROR_NETWORK,
                        SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> finishListenError("offline")
                        SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> finishListenError("no_permission")
                        else -> finishListenError("error_$error")
                    }
                }
            })
            val i = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                putExtra(RecognizerIntent.EXTRA_LANGUAGE, lang)
                putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
                putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, true)
                putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
            }
            r.startListening(i)
        } catch (t: Throwable) {
            finishListenError("error")
        }
    }

    private fun finishListen(s: String?) {
        listenResult?.success(s)
        listenResult = null
    }

    private fun finishListenError(code: String) {
        listenResult?.error(code, null, null)
        listenResult = null
    }

    private fun speak(text: String, lang: String, result: MethodChannel.Result) {
        if (text.isBlank()) { result.success(false); return }
        finishSpeak(false)
        speakResult = result
        val go = {
            val t = tts
            if (t == null || !ttsReady) {
                finishSpeak(false)
            } else {
                val loc = Locale.forLanguageTag(lang)
                if (t.isLanguageAvailable(loc) >= TextToSpeech.LANG_AVAILABLE) t.language = loc
                t.speak(text.take(TextToSpeech.getMaxSpeechInputLength() - 1),
                    TextToSpeech.QUEUE_FLUSH, null, "joi")
            }
        }
        if (tts == null) {
            tts = TextToSpeech(activity.applicationContext) { st ->
                ttsReady = st == TextToSpeech.SUCCESS
                tts?.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                    override fun onStart(id: String?) {}
                    override fun onDone(id: String?) { activity.runOnUiThread { finishSpeak(true) } }
                    @Deprecated("Deprecated in Java")
                    override fun onError(id: String?) { activity.runOnUiThread { finishSpeak(false) } }
                    override fun onStop(id: String?, interrupted: Boolean) {
                        activity.runOnUiThread { finishSpeak(false) }
                    }
                })
                activity.runOnUiThread { go() }
            }
        } else {
            go()
        }
    }

    private fun finishSpeak(ok: Boolean) {
        speakResult?.success(ok)
        speakResult = null
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        try { recognizer?.destroy() } catch (_: Throwable) {}
        recognizer = null
        try { tts?.shutdown() } catch (_: Throwable) {}
        tts = null
        finishListen(null)
        finishSpeak(false)
        permResult?.success(false)
        permResult = null
    }

    companion object {
        const val NAME = "gizlialan/voice"
        private const val REQ_MIC = 7311
        fun attach(activity: Activity, messenger: BinaryMessenger) = VoiceChannel(activity, messenger)
    }
}
