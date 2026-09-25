package com.offerforge.gizlialan.secondphone

import android.app.Activity
import android.app.admin.DevicePolicyManager
import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.LauncherApps
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PersistableBundle
import android.os.UserHandle
import android.os.UserManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors
import com.offerforge.gizlialan.secondphone.SecondPhoneContract as C

/**
 * Main-profile side of the "second phone" feature (MethodChannel
 * `gizlialan/second_phone`). Only called from vault screens, i.e. after the
 * vault PIN/biometric unlock (gated in Dart).
 *
 * Reads only: whether a work profile exists, the launcher entries
 * (LauncherApps) of the owner's own profiles, and launchable apps of the main
 * profile for the "add app" picker. It never reads other apps' data.
 */
class SecondPhoneChannel(private val activity: Activity, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, "gizlialan/second_phone")
    private val pending = HashMap<Int, MethodChannel.Result>()
    private var nextCode = REQ_BASE
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    private val ctx: Context get() = activity
    private val dpm get() = ctx.getSystemService(DevicePolicyManager::class.java)
    private val um get() = ctx.getSystemService(UserManager::class.java)
    private val launcherApps get() = ctx.getSystemService(LauncherApps::class.java)

    init {
        channel.setMethodCallHandler(this)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        io.shutdown()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "status" -> result.success(status())
                "provision" -> provision(result)
                "listApps" -> background(result) { listProfileApps() }
                "launchApp" -> result.success(
                    launch(call.argument<String>("package"), call.argument<String>("activity")),
                )
                "cloneCandidates" -> background(result) { cloneCandidates() }
                "clone" -> {
                    val intent = Intent(C.ACTION)
                        .putExtra(C.EXTRA_OP, C.OP_CLONE)
                        .putExtra(C.EXTRA_PACKAGE, call.argument<String>("package"))
                        .putExtra(C.EXTRA_IS_SYSTEM, call.argument<Boolean>("isSystem") ?: false)
                        .putExtra(C.EXTRA_OPEN_STORE_FALLBACK, call.argument<Boolean>("openStoreFallback") ?: true)
                    sendToProfile(intent, result)
                }
                "openStore" -> openStore(result)
                "freeze" -> sendToProfile(Intent(C.ACTION).putExtra(C.EXTRA_OP, C.OP_FREEZE), result)
                "unfreeze" -> sendToProfile(Intent(C.ACTION).putExtra(C.EXTRA_OP, C.OP_UNFREEZE), result)
                "ping" -> sendToProfile(Intent(C.ACTION).putExtra(C.EXTRA_OP, C.OP_PING), result)
                "setQuietMode" -> result.success(setQuietMode(call.argument<Boolean>("enabled") ?: true))
                "remove" -> sendToProfile(Intent(C.ACTION).putExtra(C.EXTRA_OP, C.OP_REMOVE), result)
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("second_phone", e.toString(), null)
        }
    }

    // ------------------------------------------------------------------ status

    private fun profile(): UserHandle? = try {
        // Profiles of this user where GizliAlan is installed = our work profile.
        ctx.getSystemService(android.content.pm.CrossProfileApps::class.java)
            .targetUserProfiles.firstOrNull()
    } catch (_: Exception) {
        null
    }

    private fun isXiaomiFamily(): Boolean {
        val s = "${Build.MANUFACTURER} ${Build.BRAND}".lowercase()
        return listOf("xiaomi", "redmi", "poco").any { s.contains(it) }
    }

    private fun status(): Map<String, Any?> {
        val pm = ctx.packageManager
        val feature = pm.hasSystemFeature(PackageManager.FEATURE_MANAGED_USERS) &&
            pm.hasSystemFeature(PackageManager.FEATURE_DEVICE_ADMIN)
        val allowed = feature && try {
            dpm.isProvisioningAllowed(DevicePolicyManager.ACTION_PROVISION_MANAGED_PROFILE)
        } catch (_: Exception) {
            false
        }
        val p = profile()
        val quiet = p?.let { try { um.isQuietModeEnabled(it) } catch (_: Exception) { false } } ?: false
        return mapOf(
            "featureSupported" to feature,
            "provisioningAllowed" to allowed,
            "exists" to (p != null),
            "linked" to (C.secret(ctx) != null),
            "quietMode" to quiet,
            "manufacturer" to Build.MANUFACTURER,
            "brand" to Build.BRAND,
            "isXiaomi" to isXiaomiFamily(),
            "sdkInt" to Build.VERSION.SDK_INT,
            "insideProfile" to dpm.isProfileOwnerApp(ctx.packageName),
        )
    }

    // ------------------------------------------------------------ provisioning

    private fun provision(result: MethodChannel.Result) {
        val secret = C.newSecret()
        val extras = PersistableBundle().apply { putString(C.EXTRA_SECRET, secret) }
        val intent = Intent(DevicePolicyManager.ACTION_PROVISION_MANAGED_PROFILE)
            .putExtra(DevicePolicyManager.EXTRA_PROVISIONING_DEVICE_ADMIN_COMPONENT_NAME, C.admin(ctx))
            .putExtra(DevicePolicyManager.EXTRA_PROVISIONING_ADMIN_EXTRAS_BUNDLE, extras)
        if (intent.resolveActivity(ctx.packageManager) == null) {
            result.success(mapOf("status" to "unavailable"))
            return
        }
        C.storeSecret(ctx, secret)
        val code = register(result)
        try {
            activity.startActivityForResult(intent, code)
        } catch (e: ActivityNotFoundException) {
            pending.remove(code)
            result.success(mapOf("status" to "unavailable"))
        } catch (e: SecurityException) {
            pending.remove(code)
            result.success(mapOf("status" to "blocked"))
        }
    }

    // ---------------------------------------------------- cross-profile calls

    private fun register(result: MethodChannel.Result): Int {
        val code = nextCode
        nextCode = if (nextCode >= REQ_BASE + 500) REQ_BASE else nextCode + 1
        pending[code] = result
        return code
    }

    private fun sendToProfile(intent: Intent, result: MethodChannel.Result) {
        val secret = C.secret(ctx)
        if (profile() == null || secret == null) {
            result.success(mapOf("status" to "no_profile"))
            return
        }
        C.sign(intent, secret)
        val code = register(result)
        try {
            activity.startActivityForResult(intent, code)
        } catch (e: ActivityNotFoundException) {
            pending.remove(code)
            result.success(mapOf("status" to "unreachable"))
        }
    }

    /** Returns true if [requestCode] belonged to this channel. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        val result = pending.remove(requestCode) ?: return false
        if (data?.hasExtra(C.RESULT_STATUS) == true) {
            result.success(
                mapOf(
                    "status" to data.getStringExtra(C.RESULT_STATUS),
                    "count" to data.getIntExtra(C.RESULT_COUNT, 0),
                ),
            )
        } else {
            // Provisioning returns plain OK / CANCELED.
            result.success(mapOf("status" to if (resultCode == Activity.RESULT_OK) "ok" else "canceled"))
        }
        return true
    }

    // ----------------------------------------------------------- quiet mode

    private fun setQuietMode(enabled: Boolean): Map<String, Any?> {
        val p = profile() ?: return mapOf("status" to "no_profile")
        return try {
            um.requestQuietModeEnabled(enabled, p)
            mapOf("status" to "ok")
        } catch (e: SecurityException) {
            // Android lets only the default launcher (or system apps) do this.
            mapOf("status" to "not_permitted")
        }
    }

    // --------------------------------------------------------------- apps

    private fun <T> background(result: MethodChannel.Result, work: () -> T) {
        io.execute {
            val r = try {
                Result.success(work())
            } catch (e: Exception) {
                Result.failure(e)
            }
            main.post {
                r.fold(
                    { result.success(it) },
                    { result.error("second_phone", it.toString(), null) },
                )
            }
        }
    }

    private fun listProfileApps(): List<Map<String, Any?>> {
        val p = profile() ?: return emptyList()
        return launcherApps.getActivityList(null, p)
            .filter { it.componentName.packageName != ctx.packageName }
            .sortedBy { it.label.toString().lowercase() }
            .map {
                mapOf(
                    "label" to it.label.toString(),
                    "package" to it.componentName.packageName,
                    "activity" to it.componentName.className,
                    "icon" to png(it.getBadgedIcon(0)),
                )
            }
    }

    private fun launch(pkg: String?, cls: String?): Map<String, Any?> {
        val p = profile() ?: return mapOf("status" to "no_profile")
        if (pkg == null || cls == null) return mapOf("status" to "error")
        return try {
            launcherApps.startMainActivity(ComponentName(pkg, cls), p, null, null)
            mapOf("status" to "ok")
        } catch (e: Exception) {
            mapOf("status" to "error")
        }
    }

    private fun openStore(result: MethodChannel.Result) {
        val p = profile()
        if (p == null) {
            result.success(mapOf("status" to "no_profile"))
            return
        }
        val store = try {
            launcherApps.getActivityList(C.PLAY_STORE, p).firstOrNull()
        } catch (_: Exception) {
            null
        }
        if (store != null) {
            try {
                launcherApps.startMainActivity(store.componentName, p, null, null)
                result.success(mapOf("status" to "store_opened"))
                return
            } catch (_: Exception) {
            }
        }
        // Hidden (frozen) or not enabled yet: ask the profile to enable + open it.
        sendToProfile(Intent(C.ACTION).putExtra(C.EXTRA_OP, C.OP_OPEN_STORE), result)
    }

    private fun cloneCandidates(): List<Map<String, Any?>> {
        val p = profile()
        val inProfile = if (p == null) emptySet() else
            launcherApps.getActivityList(null, p).map { it.componentName.packageName }.toSet()
        val pm = ctx.packageManager
        val i = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        return pm.queryIntentActivities(i, 0)
            .map { it.activityInfo }
            .distinctBy { it.packageName }
            .filter { it.packageName != ctx.packageName && it.packageName !in inProfile }
            .map {
                val app = it.applicationInfo
                mapOf(
                    "label" to it.loadLabel(pm).toString(),
                    "package" to it.packageName,
                    "isSystem" to ((app.flags and ApplicationInfo.FLAG_SYSTEM) != 0),
                    "icon" to png(it.loadIcon(pm)),
                )
            }
            .sortedBy { (it["label"] as String).lowercase() }
    }

    private fun png(d: Drawable): ByteArray {
        val size = 96
        val bmp = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val c = Canvas(bmp)
        d.setBounds(0, 0, size, size)
        d.draw(c)
        val out = ByteArrayOutputStream()
        bmp.compress(Bitmap.CompressFormat.PNG, 100, out)
        bmp.recycle()
        return out.toByteArray()
    }

    companion object {
        private const val REQ_BASE = 7300
    }
}
