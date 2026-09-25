package com.offerforge.gizlialan.secondphone

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.os.PersistableBundle
import com.offerforge.gizlialan.MainActivity
import com.offerforge.gizlialan.R

/**
 * Runs inside the work profile after provisioning. Only touches the work
 * profile itself: names it, enables it, hides the app's own launcher entry
 * there and allows exactly one cross-profile intent (our signed action) from
 * the main profile into the profile. No user restrictions or device-wide
 * policies are set.
 */
object ProfileSetup {
    fun finalize(context: Context, intent: Intent?) {
        val dpm = context.getSystemService(DevicePolicyManager::class.java)
        if (!dpm.isProfileOwnerApp(context.packageName)) return
        val admin = SecondPhoneContract.admin(context)

        adminExtras(intent)?.getString(SecondPhoneContract.EXTRA_SECRET)?.let {
            if (it.isNotEmpty()) SecondPhoneContract.storeSecret(context, it)
        }

        val pm = context.packageManager
        // The trampoline only exists inside the profile.
        pm.setComponentEnabledSetting(
            ComponentName(context, ProfileActionActivity::class.java),
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
            PackageManager.DONT_KILL_APP,
        )
        // No second vault/calculator icon in the work tab: the vault lives in
        // the main profile only.
        pm.setComponentEnabledSetting(
            ComponentName(context, MainActivity::class.java),
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
            PackageManager.DONT_KILL_APP,
        )

        dpm.clearCrossProfileIntentFilters(admin)
        dpm.addCrossProfileIntentFilter(
            admin,
            IntentFilter(SecondPhoneContract.ACTION),
            DevicePolicyManager.FLAG_PARENT_CAN_ACCESS_MANAGED,
        )
        dpm.setProfileName(admin, context.getString(R.string.profile_name))
        dpm.setProfileEnabled(admin)
    }

    private fun adminExtras(intent: Intent?): PersistableBundle? {
        if (intent == null) return null
        return if (Build.VERSION.SDK_INT >= 33) {
            intent.getParcelableExtra(
                DevicePolicyManager.EXTRA_PROVISIONING_ADMIN_EXTRAS_BUNDLE,
                PersistableBundle::class.java,
            )
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(DevicePolicyManager.EXTRA_PROVISIONING_ADMIN_EXTRAS_BUNDLE)
        }
    }
}
