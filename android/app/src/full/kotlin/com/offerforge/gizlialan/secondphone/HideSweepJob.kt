package com.offerforge.gizlialan.secondphone

import android.app.admin.DevicePolicyManager
import android.app.job.JobParameters
import android.app.job.JobService

/**
 * Work-profile periodic job (scheduled on lock, cancelled on unlock): while
 * the vault is locked, re-hides any launchable app that appeared in the
 * profile since the last pass (#45). Android does not deliver
 * ACTION_PACKAGE_ADDED to manifest receivers (API 26+), so this is the
 * reliable in-profile catch-up; the vault also re-sweeps each time GizliAlan
 * comes to the foreground while locked.
 */
class HideSweepJob : JobService() {
    override fun onStartJob(params: JobParameters?): Boolean {
        try {
            val dpm = getSystemService(DevicePolicyManager::class.java)
            val hider = ProfileHider(this)
            if (dpm.isProfileOwnerApp(packageName) && hider.isLocked()) hider.hideAll()
        } catch (_: Exception) {
        }
        return false
    }

    override fun onStopJob(params: JobParameters?): Boolean = false

    companion object {
        const val JOB_ID = 4501
    }
}
