package com.offerforge.gizlialan.secondphone

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import java.security.MessageDigest
import java.security.SecureRandom
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

/**
 * Shared constants + request signing for the "second phone" (managed work
 * profile) feature.
 *
 * The app runs as two instances: the normal one in the owner's main profile
 * (UI, no admin powers) and a headless one inside the work profile it created,
 * where it is the profile owner. The main instance asks the profile instance
 * to do something (freeze apps, clone an app, remove the profile) by starting
 * [ProfileActionActivity] across the profile boundary, which Android routes
 * through its system IntentForwarderActivity.
 *
 * Because any app in the main profile could send the same implicit intent,
 * every request is HMAC-signed with a 256-bit secret that the main instance
 * generated and handed to the profile instance inside the provisioning intent
 * (EXTRA_PROVISIONING_ADMIN_EXTRAS_BUNDLE). No trust-on-first-use.
 */
object SecondPhoneContract {
    const val ACTION = "com.offerforge.gizlialan.secondphone.PROFILE_ACTION"

    const val EXTRA_OP = "op"
    const val EXTRA_PACKAGE = "pkg"
    const val EXTRA_IS_SYSTEM = "is_system"
    const val EXTRA_OPEN_STORE_FALLBACK = "open_store_fallback"
    const val EXTRA_TS = "ts"
    const val EXTRA_SIG = "sig"
    const val EXTRA_SECRET = "gizlialan_secret"

    const val RESULT_STATUS = "status"
    const val RESULT_COUNT = "count"

    const val OP_PING = "ping"
    const val OP_FREEZE = "freeze"
    const val OP_UNFREEZE = "unfreeze"
    const val OP_CLONE = "clone"
    const val OP_OPEN_STORE = "open_store"
    const val OP_REMOVE = "remove"

    const val PLAY_STORE = "com.android.vending"

    private const val PREFS = "second_phone"
    private const val KEY_SECRET = "secret"
    private const val MAX_AGE_MS = 2 * 60 * 1000L

    fun admin(context: Context) = ComponentName(context, ProfileAdminReceiver::class.java)

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun secret(context: Context): String? = prefs(context).getString(KEY_SECRET, null)

    fun storeSecret(context: Context, secret: String) {
        prefs(context).edit().putString(KEY_SECRET, secret).apply()
    }

    fun clearSecret(context: Context) {
        prefs(context).edit().remove(KEY_SECRET).apply()
    }

    fun newSecret(): String {
        val b = ByteArray(32)
        SecureRandom().nextBytes(b)
        return b.joinToString("") { "%02x".format(it) }
    }

    private fun payload(intent: Intent, ts: Long) = listOf(
        intent.getStringExtra(EXTRA_OP) ?: "",
        intent.getStringExtra(EXTRA_PACKAGE) ?: "",
        intent.getBooleanExtra(EXTRA_IS_SYSTEM, false).toString(),
        intent.getBooleanExtra(EXTRA_OPEN_STORE_FALLBACK, false).toString(),
        ts.toString(),
    ).joinToString("|")

    private fun hmac(secret: String, data: String): String {
        val mac = Mac.getInstance("HmacSHA256")
        mac.init(SecretKeySpec(secret.toByteArray(), "HmacSHA256"))
        return mac.doFinal(data.toByteArray()).joinToString("") { "%02x".format(it) }
    }

    fun sign(intent: Intent, secret: String) {
        val ts = System.currentTimeMillis()
        intent.putExtra(EXTRA_TS, ts)
        intent.putExtra(EXTRA_SIG, hmac(secret, payload(intent, ts)))
    }

    fun verify(intent: Intent, secret: String?): Boolean {
        if (secret.isNullOrEmpty()) return false
        val ts = intent.getLongExtra(EXTRA_TS, 0L)
        if (Math.abs(System.currentTimeMillis() - ts) > MAX_AGE_MS) return false
        val sig = intent.getStringExtra(EXTRA_SIG) ?: return false
        return MessageDigest.isEqual(
            sig.toByteArray(),
            hmac(secret, payload(intent, ts)).toByteArray(),
        )
    }
}
