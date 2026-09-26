package com.offerforge.gizlialan

import android.content.Intent
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * FlutterFragmentActivity is required by local_auth (BiometricPrompt).
 *
 * FLAG_SECURE is always on: blocks screenshots / screen recording and hides
 * the app content in the recent-apps preview. This only protects GizliAlan's
 * own window; it does not observe or affect any other app.
 *
 * Also hosts the flavor-specific native feature ([FlavorFeatures]): the
 * "second phone" (own work profile) channel in the `full` flavor, nothing in
 * the `play` flavor — and [SystemChannel] (open the privacy-policy URL in
 * the browser via ACTION_VIEW; wipe the in-vault browser's WebView data).
 */
class MainActivity : FlutterFragmentActivity() {
    private var flavorFeature: FlavorFeature? = null
    private var systemChannel: MethodChannel? = null
    private var importChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE,
        )
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        systemChannel = SystemChannel.attach(this, flutterEngine.dartExecutor.binaryMessenger)
        importChannel = ImportChannel.attach(this, flutterEngine.dartExecutor.binaryMessenger)
        flavorFeature = FlavorFeatures.attach(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        systemChannel?.setMethodCallHandler(null)
        systemChannel = null
        importChannel?.setMethodCallHandler(null)
        importChannel = null
        flavorFeature?.dispose()
        flavorFeature = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    @Deprecated("Needed to receive provisioning / cross-profile results")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (ImportChannel.onActivityResult(this, requestCode, resultCode, data)) return
        if (flavorFeature?.onActivityResult(requestCode, resultCode, data) == true) return
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
    }
}
