package com.offerforge.gizlialan

import android.app.Activity
import io.flutter.plugin.common.BinaryMessenger

/**
 * `play` flavor: no Second phone. No device-admin receiver, no work-profile
 * code, no extra channel. The Dart side hides the feature (AppFlavor.play).
 */
object FlavorFeatures {
    @Suppress("UNUSED_PARAMETER")
    fun attach(activity: Activity, messenger: BinaryMessenger): FlavorFeature? = null
}
