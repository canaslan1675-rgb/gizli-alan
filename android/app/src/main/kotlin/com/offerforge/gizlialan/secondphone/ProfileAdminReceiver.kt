package com.offerforge.gizlialan.secondphone

import android.app.admin.DeviceAdminReceiver
import android.app.admin.DevicePolicyManager
import android.content.Context
import android.content.Intent

/**
 * Admin component used ONLY as the profile owner of the owner's own work
 * profile ("second phone"). It declares no device-admin policies.
 *
 * If someone activates it as a classic device admin in the main profile
 * (Settings → Device admin apps), it immediately deactivates itself: the app
 * never holds admin powers over the main profile or the device.
 */
class ProfileAdminReceiver : DeviceAdminReceiver() {
    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        val dpm = context.getSystemService(DevicePolicyManager::class.java)
        if (!dpm.isProfileOwnerApp(context.packageName)) {
            dpm.removeActiveAdmin(SecondPhoneContract.admin(context))
        }
    }

    override fun onProfileProvisioningComplete(context: Context, intent: Intent) {
        super.onProfileProvisioningComplete(context, intent)
        // On Android 8+ ProvisioningDoneActivity usually runs first; finalize()
        // is idempotent so running it twice is harmless.
        ProfileSetup.finalize(context, intent)
    }
}
