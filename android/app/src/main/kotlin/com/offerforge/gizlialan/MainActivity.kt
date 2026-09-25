package com.offerforge.gizlialan

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity

/**
 * FlutterFragmentActivity is required by local_auth (BiometricPrompt).
 *
 * FLAG_SECURE is always on: blocks screenshots / screen recording and hides
 * the app content in the recent-apps preview. This only protects GizliAlan's
 * own window; it does not observe or affect any other app.
 */
class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE,
        )
        super.onCreate(savedInstanceState)
    }
}
