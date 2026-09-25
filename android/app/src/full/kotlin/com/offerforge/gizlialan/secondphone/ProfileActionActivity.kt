package com.offerforge.gizlialan.secondphone

import android.app.Activity
import android.app.admin.DevicePolicyManager
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import com.offerforge.gizlialan.secondphone.SecondPhoneContract as C

/**
 * Headless trampoline that runs INSIDE the work profile (disabled in the main
 * profile). Executes one signed request from the main-profile vault and
 * returns a result. All operations only affect the work profile:
 *
 *  - freeze / unfreeze: hide or unhide the profile's launchable apps
 *    (DevicePolicyManager.setApplicationHidden) so the second phone is
 *    "closed" while the vault is locked;
 *  - clone: make a main-profile app available in the profile
 *    (installExistingPackage, or enableSystemApp for system apps). If Android
 *    does not allow that, optionally open the profile's Play Store page;
 *  - open_store: open (and if needed re-enable) the profile's Play Store;
 *  - remove: delete the work profile and everything in it (wipeData on a
 *    profile owner removes only the profile).
 */
class ProfileActionActivity : Activity() {
    private val dpm by lazy { getSystemService(DevicePolicyManager::class.java) }
    private val admin by lazy { C.admin(this) }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val req = intent
        val caller = callingPackage
        val trusted = dpm.isProfileOwnerApp(packageName) &&
            (caller == null || caller == packageName) &&
            C.verify(req, C.secret(this))
        if (!trusted) {
            reply(RESULT_CANCELED, "denied")
            return
        }
        try {
            when (req.getStringExtra(C.EXTRA_OP)) {
                C.OP_PING -> reply(RESULT_OK, "ok", frozen().size)
                C.OP_FREEZE -> freeze()
                C.OP_UNFREEZE -> unfreeze()
                C.OP_CLONE -> clone(req)
                C.OP_OPEN_STORE -> reply(RESULT_OK, openStore(req.getStringExtra(C.EXTRA_PACKAGE)))
                C.OP_REMOVE -> {
                    reply(RESULT_OK, "removed")
                    C.clearSecret(this)
                    dpm.wipeData(0)
                }
                else -> reply(RESULT_CANCELED, "unknown_op")
            }
        } catch (e: SecurityException) {
            reply(RESULT_CANCELED, "not_permitted")
        } catch (e: Exception) {
            reply(RESULT_CANCELED, "error")
        }
    }

    private fun reply(code: Int, status: String, count: Int = 0) {
        setResult(code, Intent().putExtra(C.RESULT_STATUS, status).putExtra(C.RESULT_COUNT, count))
        finish()
    }

    private val prefs by lazy { getSharedPreferences("second_phone_profile", MODE_PRIVATE) }

    private fun frozen(): Set<String> = prefs.getStringSet("frozen", emptySet()) ?: emptySet()

    private fun setFrozen(s: Set<String>) = prefs.edit().putStringSet("frozen", s).apply()

    private fun launchablePackages(): Set<String> {
        val i = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        return packageManager.queryIntentActivities(i, 0)
            .map { it.activityInfo.packageName }
            .filter { it != packageName }
            .toSet()
    }

    private fun freeze() {
        val done = frozen().toMutableSet()
        for (pkg in launchablePackages()) {
            if (dpm.setApplicationHidden(admin, pkg, true)) done.add(pkg)
        }
        setFrozen(done)
        reply(RESULT_OK, "frozen", done.size)
    }

    private fun unfreeze() {
        var n = 0
        for (pkg in frozen()) {
            try {
                dpm.setApplicationHidden(admin, pkg, false)
                n++
            } catch (_: Exception) {
                // package may have been uninstalled meanwhile
            }
        }
        setFrozen(emptySet())
        reply(RESULT_OK, "unfrozen", n)
    }

    private fun isInstalledHere(pkg: String): Boolean = try {
        packageManager.getApplicationInfo(pkg, 0)
        true
    } catch (_: PackageManager.NameNotFoundException) {
        false
    }

    private fun clone(req: Intent) {
        val pkg = req.getStringExtra(C.EXTRA_PACKAGE)
        if (pkg.isNullOrEmpty() || pkg == packageName) {
            reply(RESULT_CANCELED, "error")
            return
        }
        var ok = false
        try {
            // Android only allows this for affiliated profiles; on personal
            // devices it usually throws, so we fall through.
            ok = dpm.installExistingPackage(admin, pkg)
        } catch (_: SecurityException) {
        } catch (_: UnsupportedOperationException) {
        }
        if (!ok && req.getBooleanExtra(C.EXTRA_IS_SYSTEM, false)) {
            try {
                dpm.enableSystemApp(admin, pkg)
            } catch (_: Exception) {
            }
            ok = isInstalledHere(pkg)
        }
        if (ok) {
            try {
                dpm.setApplicationHidden(admin, pkg, false)
            } catch (_: Exception) {
            }
            setFrozen(frozen() - pkg)
            reply(RESULT_OK, "cloned")
            return
        }
        if (req.getBooleanExtra(C.EXTRA_OPEN_STORE_FALLBACK, false)) {
            reply(RESULT_OK, if (openStore(pkg) == "store_opened") "store_opened" else "needs_store")
        } else {
            reply(RESULT_OK, "needs_store")
        }
    }

    /** Opens the work profile's Play Store (optionally on an app's page). */
    private fun openStore(pkg: String?): String {
        try {
            dpm.setApplicationHidden(admin, C.PLAY_STORE, false)
        } catch (_: Exception) {
        }
        if (!isInstalledHere(C.PLAY_STORE)) {
            try {
                dpm.enableSystemApp(admin, C.PLAY_STORE)
            } catch (_: Exception) {
            }
        }
        if (!isInstalledHere(C.PLAY_STORE)) return "no_store"
        setFrozen(frozen() - C.PLAY_STORE)
        val intent = if (pkg.isNullOrEmpty()) {
            packageManager.getLaunchIntentForPackage(C.PLAY_STORE)
        } else {
            Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=$pkg"))
                .setPackage(C.PLAY_STORE)
        } ?: return "no_store"
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return try {
            startActivity(intent)
            "store_opened"
        } catch (_: Exception) {
            "no_store"
        }
    }
}
