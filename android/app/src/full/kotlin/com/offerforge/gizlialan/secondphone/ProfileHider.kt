package com.offerforge.gizlialan.secondphone

import android.app.admin.DevicePolicyManager
import android.app.job.JobInfo
import android.app.job.JobScheduler
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager

/**
 * Runs INSIDE the work profile (profile owner). Hides / unhides the profile's
 * launchable apps for "hide work apps while locked" (#30, #45). Shared by
 * [ProfileActionActivity] (lock/unlock requests from the vault) and
 * [HideSweepJob] (periodic re-check while locked, catches apps that appear
 * while the vault is locked).
 *
 * Persisted in the profile's own prefs:
 *  - `frozen`: packages WE hid (only those are unhidden on unlock);
 *  - `suspended`: packages we could not hide and suspended instead;
 *  - `locked`: whether the vault last told us it is locked.
 */
class ProfileHider(private val ctx: Context) {
    private val dpm = ctx.getSystemService(DevicePolicyManager::class.java)
    private val admin = SecondPhoneContract.admin(ctx)
    private val prefs = ctx.getSharedPreferences("second_phone_profile", Context.MODE_PRIVATE)

    fun frozen(): Set<String> = prefs.getStringSet("frozen", emptySet())?.toSet() ?: emptySet()
    fun setFrozen(s: Set<String>) = prefs.edit().putStringSet("frozen", s).apply()
    private fun suspended(): Set<String> = prefs.getStringSet("suspended", emptySet())?.toSet() ?: emptySet()
    private fun setSuspended(s: Set<String>) = prefs.edit().putStringSet("suspended", s).apply()
    fun isLocked(): Boolean = prefs.getBoolean("locked", false)
    private fun setLocked(v: Boolean) = prefs.edit().putBoolean("locked", v).apply()

    /** Every package in this profile with a launcher entry (= shown in the Work tab). */
    private fun launchablePackages(): Set<String> {
        val i = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        return ctx.packageManager.queryIntentActivities(i, PackageManager.MATCH_ALL)
            .map { it.activityInfo.packageName }
            .toSet()
    }

    private fun isHidden(pkg: String): Boolean = try {
        dpm.isApplicationHidden(admin, pkg)
    } catch (_: Exception) {
        false
    }

    private fun installedEvenIfHidden(pkg: String): Boolean = try {
        ctx.packageManager.getApplicationInfo(pkg, PackageManager.MATCH_UNINSTALLED_PACKAGES)
        true
    } catch (_: PackageManager.NameNotFoundException) {
        false
    }

    /** Hide all hideable launchable apps; returns the size of our hidden set. */
    fun hideAll(): Int {
        setLocked(true)
        val before = frozen()
        val ok = mutableListOf<String>()
        val failed = mutableListOf<String>()
        val targets = HidePolicy.lockTargets(launchablePackages(), ::isInstalledVisible)
        for (pkg in HidePolicy.toHide(targets, ctx.packageName)) {
            val hidden = try {
                dpm.setApplicationHidden(admin, pkg, true) || isHidden(pkg)
            } catch (_: Exception) {
                false
            }
            if (hidden) ok.add(pkg) else failed.add(pkg)
        }
        setFrozen(HidePolicy.afterHide(before, ok))
        // Fallback: suspend what could not be hidden (still visible, but greyed out).
        val toSuspend = HidePolicy.toSuspend(failed, ctx.packageName, suspended())
        if (toSuspend.isNotEmpty()) {
            val notSuspended = try {
                dpm.setPackagesSuspended(admin, toSuspend.toTypedArray(), true).toSet()
            } catch (_: Exception) {
                toSuspend.toSet()
            }
            setSuspended(suspended() + (toSuspend - notSuspended))
        }
        applyLockPolicies(true)
        scheduleSweep()
        return frozen().size
    }

    /** Unhide/unsuspend exactly what we recorded (+ Play Store safety net). */
    fun unhideAll(): Pair<Int, Boolean> {
        setLocked(false)
        cancelSweep()
        applyLockPolicies(false)
        val recorded = frozen()
        val failed = mutableListOf<String>()
        var n = 0
        for (pkg in HidePolicy.unhideCandidates(recorded)) {
            val wasOurs = pkg in recorded
            try {
                dpm.setApplicationHidden(admin, pkg, false)
            } catch (_: Exception) {
            }
            if (isHidden(pkg)) {
                if (wasOurs) failed.add(pkg)
            } else if (wasOurs) {
                n++
            }
        }
        setFrozen(HidePolicy.afterUnhide(failed, ::installedEvenIfHidden))
        val susp = suspended()
        if (susp.isNotEmpty()) {
            val still = try {
                dpm.setPackagesSuspended(admin, susp.toTypedArray(), false).toList()
            } catch (_: Exception) {
                susp.toList()
            }
            setSuspended(HidePolicy.afterUnhide(still, ::installedEvenIfHidden))
        }
        return n to failed.isEmpty()
    }

    private fun isInstalledVisible(pkg: String): Boolean = try {
        ctx.packageManager.getApplicationInfo(pkg, 0)
        true
    } catch (_: PackageManager.NameNotFoundException) {
        false
    }

    /**
     * While locked: no clipboard / sharing between the profiles, no work
     * contacts in personal caller-ID, contact search or Bluetooth (#45).
     * Every call is best-effort (some OEMs refuse individual policies).
     */
    private fun applyLockPolicies(locked: Boolean) {
        for (r in HidePolicy.LOCK_RESTRICTIONS) {
            try {
                if (locked) dpm.addUserRestriction(admin, r) else dpm.clearUserRestriction(admin, r)
            } catch (_: Exception) {
            }
        }
        try { dpm.setCrossProfileCallerIdDisabled(admin, locked) } catch (_: Exception) {}
        try { dpm.setCrossProfileContactsSearchDisabled(admin, locked) } catch (_: Exception) {}
        try { dpm.setBluetoothContactSharingDisabled(admin, locked) } catch (_: Exception) {}
        // Neutral profile name (Settings / system dialogs show it).
        try { dpm.setProfileName(admin, ctx.getString(com.offerforge.gizlialan.R.string.profile_name)) } catch (_: Exception) {}
    }

    private fun scheduleSweep() {
        try {
            val js = ctx.getSystemService(JobScheduler::class.java)
            val job = JobInfo.Builder(HideSweepJob.JOB_ID, ComponentName(ctx, HideSweepJob::class.java))
                .setPeriodic(JobInfo.getMinPeriodMillis())
                .build()
            js.schedule(job)
        } catch (_: Exception) {
        }
    }

    private fun cancelSweep() {
        try {
            ctx.getSystemService(JobScheduler::class.java).cancel(HideSweepJob.JOB_ID)
        } catch (_: Exception) {
        }
    }
}
