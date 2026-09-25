package com.offerforge.gizlialan.secondphone

import android.app.Activity
import android.os.Bundle

/**
 * Launched by Android inside the new work profile when provisioning succeeds
 * (ACTION_PROVISIONING_SUCCESSFUL). Finishes the profile setup; the system
 * provisioning UI completes once this returns.
 */
class ProvisioningDoneActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        ProfileSetup.finalize(this, intent)
        setResult(RESULT_OK)
        finish()
    }
}
