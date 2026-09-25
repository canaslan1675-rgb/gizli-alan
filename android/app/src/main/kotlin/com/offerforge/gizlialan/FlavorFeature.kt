package com.offerforge.gizlialan

import android.content.Intent

/**
 * Optional, flavor-specific native feature attached to [MainActivity].
 * `full` flavor: the "second phone" channel (src/full). `play` flavor: none
 * (src/play) — the Second phone code and components are not in that APK.
 */
interface FlavorFeature {
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean
    fun dispose()
}
