package com.offerforge.gizlialan

/**
 * Pure decision logic for Joi voice (unit-tested, no Android types).
 *
 * Attempts, in order, until one actually listens:
 *  1. DEFAULT  – system default recogniser, requested language (tr-TR)
 *  2. GOOGLE   – Google's recognition service by explicit component
 *                (Google app / Speech Recognition & Synthesis), if installed
 *  3. NO_LANG  – default recogniser without EXTRA_LANGUAGE (device default)
 *  4. ON_DEVICE– createOnDeviceSpeechRecognizer (API 31+, only if available)
 *  5. DIALOG   – the system speech dialog (ACTION_RECOGNIZE_SPEECH)
 */
object VoicePlan {
    enum class Attempt { DEFAULT, GOOGLE, NO_LANG, ON_DEVICE, DIALOG }

    // SpeechRecognizer.ERROR_* (constants inlined for JVM unit tests).
    const val NETWORK_TIMEOUT = 1
    const val NETWORK = 2
    const val AUDIO = 3
    const val SERVER = 4
    const val CLIENT = 5
    const val SPEECH_TIMEOUT = 6
    const val NO_MATCH = 7
    const val BUSY = 8
    const val PERMISSIONS = 9
    const val TOO_MANY_REQUESTS = 10
    const val SERVER_DISCONNECTED = 11
    const val LANGUAGE_NOT_SUPPORTED = 12
    const val LANGUAGE_UNAVAILABLE = 13
    const val CANNOT_CHECK_SUPPORT = 14
    const val CANNOT_LISTEN_TO_DOWNLOAD_EVENTS = 15

    /** An error this soon after start, before any speech, is a start failure. */
    const val INSTANT_MS = 1500L

    fun attempts(hasGoogle: Boolean, hasOnDevice: Boolean, hasDialog: Boolean): List<Attempt> =
        buildList {
            add(Attempt.DEFAULT)
            if (hasGoogle) add(Attempt.GOOGLE)
            add(Attempt.NO_LANG)
            if (hasOnDevice) add(Attempt.ON_DEVICE)
            if (hasDialog) add(Attempt.DIALOG)
        }

    /**
     * Should we move on to the next attempt? Everything except a genuine
     * "nothing understood" after the user really spoke (or after the
     * recogniser listened for a while) counts as "this recogniser failed".
     */
    fun shouldFallback(error: Int, speechBegan: Boolean, elapsedMs: Long): Boolean {
        val genuineNoSpeech = (error == NO_MATCH || error == SPEECH_TIMEOUT) &&
            (speechBegan || elapsedMs >= INSTANT_MS)
        return !genuineNoSpeech
    }

    /** Code sent to Dart: "e<N>" (Dart maps it to a Turkish message + "(kod N)"). */
    fun code(error: Int) = "e$error"

    /** Short exception description for the attempts trail: "x_Class(msg)". */
    fun exc(cls: String, msg: String?): String {
        val m = msg?.replace(Regex("\\s+"), " ")?.trim()?.take(60)
        return if (m.isNullOrEmpty()) "x_$cls" else "x_$cls($m)"
    }

    /**
     * Final code when every attempt failed, from the last trail entry
     * ("tag:e7" → "e7", "tag:x_SecurityException(...)" → "x:SecurityException").
     * Never the bare string "error".
     */
    fun finalCode(lastWhy: String): String {
        val v = lastWhy.substringAfter(':')
        Regex("^e\\d+$").find(v)?.let { return it.value }
        Regex("^x_([A-Za-z0-9_$]+)").find(v)?.let { return "x:${it.groupValues[1]}" }
        return "x:unknown"
    }
}
