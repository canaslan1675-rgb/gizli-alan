package com.offerforge.gizlialan

import android.app.Activity
import com.offerforge.gizlialan.secondphone.SecondPhoneChannel
import io.flutter.plugin.common.BinaryMessenger

/** `full` flavor: hosts the Second phone (own work profile) channel. */
object FlavorFeatures {
    fun attach(activity: Activity, messenger: BinaryMessenger): FlavorFeature =
        SecondPhoneChannel(activity, messenger)
}
