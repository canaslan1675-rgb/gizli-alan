package com.offerforge.gizlialan

import android.content.Intent
import android.os.Bundle
import android.view.WindowManager
import com.offerforge.gizlialan.secondphone.SecondPhoneChannel
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * FlutterFragmentActivity is required by local_auth (BiometricPrompt).
 *
 * FLAG_SECURE is always on: blocks screenshots / screen recording and hides
 * the app content in the recent-apps preview. This only protects GizliAlan's
 * own window; it does not observe or affect any other app.
 *
 * Also hosts the "second phone" (own work profile) platform channel.
 */
class MainActivity : FlutterFragmentActivity() {
    private var secondPhone: SecondPhoneChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE,
        )
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        secondPhone = SecondPhoneChannel(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        secondPhone?.dispose()
        secondPhone = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    @Deprecated("Needed to receive provisioning / cross-profile results")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (secondPhone?.onActivityResult(requestCode, resultCode, data) == true) return
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
    }
}
