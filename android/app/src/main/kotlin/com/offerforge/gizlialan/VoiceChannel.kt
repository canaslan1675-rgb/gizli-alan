package com.offerforge.gizlialan

import android.Manifest
import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.speech.RecognitionListener
import android.speech.RecognitionService
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
    private var lastPartial: String? = null
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
                "listen" -> startSession(call.argument<String>("lang") ?: "tr-TR", result)
                "stopListening" -> {
                    userStopped = true
                    try { recognizer?.stopListening() } catch (_: Throwable) {}
                    result.success(null)
                }
                "openStore" -> {
                    val pkg = call.argument<String>("package") ?: "com.google.android.googlequicksearchbox"
                    result.success(openStore(pkg))
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
        if (requestCode == REQ_MIC_NATIVE) {
            val ok = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            val then = pendingAfterPermission
            pendingAfterPermission = null
            if (ok) then?.invoke() else finishListenError("no_permission", (trail + "mic:denied").joinToString(" > "))
            return true
        }
        if (requestCode != REQ_MIC) return false
        val ok = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
        permResult?.success(ok)
        permResult = null
        return true
    }

    // ------------------------------------------------------------ listening
    private var attempts: List<VoicePlan.Attempt> = emptyList()
    private var attemptIdx = 0
    private var lang = "tr-TR"
    private var trail = mutableListOf<String>()
    private var startedAt = 0L
    private var speechBegan = false
    private var userStopped = false
    private var session = 0
    private val main = Handler(Looper.getMainLooper())

    private fun googleComponent(): ComponentName? = try {
        val def = Settings.Secure.getString(activity.contentResolver, "voice_recognition_service")
            ?.let { ComponentName.unflattenFromString(it) }
        @Suppress("DEPRECATION")
        val services = activity.packageManager.queryIntentServices(
            Intent(RecognitionService.SERVICE_INTERFACE), 0,
        )
        services.map { ComponentName(it.serviceInfo.packageName, it.serviceInfo.name) }
            .filter { it.packageName in GOOGLE_PACKAGES }
            .sortedBy { GOOGLE_PACKAGES.indexOf(it.packageName) }
            .firstOrNull()
    } catch (_: Throwable) { null }

    private fun dialogIntent(lang: String) = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
        putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
        putExtra(RecognizerIntent.EXTRA_LANGUAGE, lang)
        putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
        putExtra(RecognizerIntent.EXTRA_PROMPT, "Joi")
    }

    private fun hasDialog() = try {
        dialogIntent(lang).resolveActivity(activity.packageManager) != null
    } catch (_: Throwable) { false }

    /** Context for bug reports: profile type, default service, Google service. */
    private fun environmentTrail(google: ComponentName?) {
        try {
            val um = activity.getSystemService(android.content.Context.USER_SERVICE) as android.os.UserManager
            if (Build.VERSION.SDK_INT >= 30 && um.isManagedProfile) trail.add("profile:managed")
        } catch (_: Throwable) {}
        try {
            val def = Settings.Secure.getString(activity.contentResolver, "voice_recognition_service")
            trail.add("svc:" + (def?.substringBefore('/')?.substringAfterLast('.') ?: "none"))
        } catch (_: Throwable) {}
        trail.add("g:" + (google?.packageName?.substringAfterLast('.') ?: "none"))
    }

    /** RECORD_AUDIO re-checked natively right before binding the recogniser. */
    private var pendingAfterPermission: (() -> Unit)? = null

    private fun withMic(then: () -> Unit) {
        if (hasMic()) { then(); return }
        trail.add("mic:recheck")
        pendingAfterPermission = then
        ActivityCompat.requestPermissions(activity, arrayOf(Manifest.permission.RECORD_AUDIO), REQ_MIC_NATIVE)
    }

    /** The speech service rejects background callers: wait until resumed. */
    private fun whenForeground(tries: Int = 0, then: () -> Unit) {
        val resumed = (activity as? androidx.lifecycle.LifecycleOwner)?.lifecycle?.currentState
            ?.isAtLeast(androidx.lifecycle.Lifecycle.State.RESUMED) ?: true
        if (resumed || tries >= 10) {
            if (!resumed) trail.add("bg")
            then()
        } else {
            main.postDelayed({ whenForeground(tries + 1, then) }, 100)
        }
    }

    /** Starts a voice session: tries the recognisers in [VoicePlan] order. */
    private fun startSession(lang: String, result: MethodChannel.Result) {
        // TTS holds audio focus: stop it before listening.
        try { tts?.stop() } catch (_: Throwable) {}
        finishSpeak(false)
        if (listenResult !== result) listenResult?.success(null)
        listenResult = result
        this.lang = lang
        session++
        trail = mutableListOf()
        val hasDefault = SpeechRecognizer.isRecognitionAvailable(activity)
        val onDevice = Build.VERSION.SDK_INT >= 31 &&
            try { SpeechRecognizer.isOnDeviceRecognitionAvailable(activity) } catch (_: Throwable) { false }
        val google = googleComponent()
        // The system dialog is ALWAYS the last attempt (even if resolveActivity
        // says no: package visibility can hide it; launching tells the truth).
        val dialogResolves = hasDialog()
        if (!dialogResolves) trail.add("dialog?unresolved")
        environmentTrail(google)
        attempts = VoicePlan.attempts(google != null, onDevice, hasDialog = true)
            .filter { hasDefault || it == VoicePlan.Attempt.GOOGLE || it == VoicePlan.Attempt.ON_DEVICE || it == VoicePlan.Attempt.DIALOG }
        attemptIdx = 0
        if (attempts.isEmpty()) {
            listenResult = null
            result.error("no_service", "no recogniser, no dialog", null)
            return
        }
        val my = session
        try {
            whenForeground {
                withMic {
                    if (my != session || listenResult == null) return@withMic
                    try {
                        runAttempt(google)
                    } catch (t: Throwable) {
                        Log.w(TAG, "first attempt crashed", t)
                        nextAttempt(google, "crash:${VoicePlan.exc(t.javaClass.simpleName, t.message)}")
                    }
                }
            }
        } catch (t: Throwable) {
            Log.w(TAG, "first attempt crashed", t)
            nextAttempt(google, "crash:${VoicePlan.exc(t.javaClass.simpleName, t.message)}")
        }
    }

    private fun nextAttempt(google: ComponentName?, why: String) {
        trail.add(why)
        attemptIdx++
        val my = session
        try { recognizer?.destroy() } catch (_: Throwable) {}
        recognizer = null
        if (attemptIdx >= attempts.size) {
            finishListenError(VoicePlan.finalCode(why), trail.joinToString(" > "))
            return
        }
        // Give the speech service a moment after destroy() before recreating.
        main.postDelayed({
            if (my == session && listenResult != null) {
                try {
                    runAttempt(google)
                } catch (t: Throwable) {
                    Log.w(TAG, "attempt crashed", t)
                    nextAttempt(google, "crash:${VoicePlan.exc(t.javaClass.simpleName, t.message)}")
                }
            }
        }, 250)
    }

    private fun runAttempt(google: ComponentName?) {
        val a = attempts[attemptIdx]
        val tag = a.name.lowercase()
        if (a == VoicePlan.Attempt.DIALOG) {
            try {
                @Suppress("DEPRECATION")
                activity.startActivityForResult(dialogIntent(lang), REQ_DIALOG)
                trail.add("dialog")
            } catch (t: Throwable) {
                Log.w(TAG, "speech dialog failed", t)
                trail.add("dialog:${VoicePlan.exc(t.javaClass.simpleName, t.message)}")
                finishListenError(
                    if (t is ActivityNotFoundException) "no_service"
                    else "x:${t.javaClass.simpleName}",
                    trail.joinToString(" > "),
                )
            }
            return
        }
        if (!hasMic()) {
            // Permission lost between attempts: the dialog does not need it.
            nextAttempt(google, "$tag:x_NoRecordAudio")
            return
        }
        speechBegan = false
        userStopped = false
        lastPartial = null
        try {
            try { recognizer?.destroy() } catch (_: Throwable) {}
            val r = when (a) {
                VoicePlan.Attempt.GOOGLE -> SpeechRecognizer.createSpeechRecognizer(activity, google)
                VoicePlan.Attempt.ON_DEVICE -> SpeechRecognizer.createOnDeviceSpeechRecognizer(activity)
                else -> SpeechRecognizer.createSpeechRecognizer(activity)
            }
            recognizer = r
            r.setRecognitionListener(object : RecognitionListener {
                override fun onReadyForSpeech(p: Bundle?) {}
                override fun onBeginningOfSpeech() { speechBegan = true }
                override fun onRmsChanged(v: Float) {}
                override fun onBufferReceived(b: ByteArray?) {}
                override fun onEndOfSpeech() {}
                override fun onEvent(t: Int, p: Bundle?) {}
                override fun onPartialResults(p: Bundle?) {
                    val s = p?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull()
                    if (!s.isNullOrBlank()) {
                        lastPartial = s
                        speechBegan = true
                        channel.invokeMethod("partial", mapOf("text" to s))
                    }
                }
                override fun onResults(p: Bundle?) {
                    if (recognizer !== r) return
                    val s = p?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull()
                    finishListen(if (s.isNullOrBlank()) lastPartial else s)
                }
                override fun onError(error: Int) {
                    if (recognizer !== r) return
                    val heard = lastPartial
                    if (!heard.isNullOrBlank()) { finishListen(heard); return }
                    val elapsed = System.currentTimeMillis() - startedAt
                    if (userStopped) {
                        // Released / tapped again before anything was heard.
                        finishListenError(VoicePlan.code(error), (trail + "$tag:${VoicePlan.code(error)}").joinToString(" > "))
                        return
                    }
                    if (VoicePlan.shouldFallback(error, speechBegan, elapsed)) {
                        nextAttempt(google, "$tag:${VoicePlan.code(error)}")
                    } else {
                        trail.add("$tag:${VoicePlan.code(error)}")
                        finishListenError(VoicePlan.code(error), trail.joinToString(" > "))
                    }
                }
            })
            val i = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                if (a != VoicePlan.Attempt.NO_LANG) {
                    putExtra(RecognizerIntent.EXTRA_LANGUAGE, lang)
                    putExtra(RecognizerIntent.EXTRA_LANGUAGE_PREFERENCE, lang)
                }
                putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
                putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
                putExtra(RecognizerIntent.EXTRA_CALLING_PACKAGE, activity.packageName)
                // No EXTRA_PREFER_OFFLINE and no silence-length extras: some
                // recognisers reject them and fail instantly.
            }
            startedAt = System.currentTimeMillis()
            r.startListening(i)
        } catch (t: Throwable) {
            // e.g. SecurityException / IllegalArgumentException for an
            // explicit component, UnsupportedOperationException on-device:
            // log and continue with the next fallback.
            Log.w(TAG, "recogniser attempt $tag failed", t)
            nextAttempt(google, "$tag:${VoicePlan.exc(t.javaClass.simpleName, t.message)}")
        }
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQ_DIALOG) return false
        val s = try {
            data?.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)?.firstOrNull()
        } catch (t: Throwable) {
            Log.w(TAG, "dialog result unreadable", t)
            trail.add("dialog_result:${t.javaClass.simpleName}")
            null
        }
        trail.add("dialog_result:$resultCode")
        if (resultCode == Activity.RESULT_OK && !s.isNullOrBlank()) {
            finishListen(s)
        } else {
            finishListenError("dialog_cancel", trail.joinToString(" > "))
        }
        return true
    }

    private fun finishListen(s: String?) {
        listenResult?.success(s)
        listenResult = null
        session++
    }

    private fun finishListenError(code: String, detail: String? = null) {
        listenResult?.error(code, detail, null)
        listenResult = null
        session++
    }

    private fun openStore(pkg: String): Boolean {
        for (u in listOf("market://details?id=$pkg", "https://play.google.com/store/apps/details?id=$pkg")) {
            try {
                activity.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(u)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                return true
            } catch (_: Throwable) {}
        }
        return false
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
        session++
        main.removeCallbacksAndMessages(null)
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
        private const val REQ_DIALOG = 7312
        private const val REQ_MIC_NATIVE = 7313
        private const val TAG = "GizliAlanVoice"
        /** Google's recognition services, preferred order. */
        private val GOOGLE_PACKAGES = listOf(
            "com.google.android.googlequicksearchbox",
            "com.google.android.tts",
            "com.google.android.as",
        )
        fun attach(activity: Activity, messenger: BinaryMessenger) = VoiceChannel(activity, messenger)
    }
}
