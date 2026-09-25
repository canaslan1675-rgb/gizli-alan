package com.offerforge.gizlialan.secondphone

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class HidePolicyTest {
    private val self = "com.offerforge.gizlialan.full"

    @Test
    fun neverHidesItselfOrEssentials() {
        assertFalse(HidePolicy.canHide(self, self))
        assertFalse(HidePolicy.canHide("", self))
        for (p in HidePolicy.NEVER_HIDE) assertFalse(p, HidePolicy.canHide(p, self))
        assertTrue(HidePolicy.canHide("com.whatsapp", self))
        assertTrue(HidePolicy.canHide(HidePolicy.PLAY_STORE, self))
    }

    @Test
    fun toHideFiltersSortsAndSkipsAlreadyHidden() {
        val launchable = listOf(
            "com.whatsapp", self, "com.google.android.gms", HidePolicy.PLAY_STORE,
            "com.android.chrome", "com.whatsapp", "com.android.settings",
        )
        assertEquals(
            listOf("com.android.chrome", HidePolicy.PLAY_STORE, "com.whatsapp"),
            HidePolicy.toHide(launchable, self, emptySet()),
        )
        assertEquals(
            listOf(HidePolicy.PLAY_STORE),
            HidePolicy.toHide(launchable, self, setOf("com.whatsapp", "com.android.chrome")),
        )
    }

    @Test
    fun persistedSetOnlyGrowsWithSuccessfulHides() {
        val s = HidePolicy.afterHide(setOf("a"), listOf("b"))
        assertEquals(setOf("a", "b"), s)
    }

    @Test
    fun unhideOnlyRecordedPlusPlayStoreSafetyNet() {
        assertEquals(listOf(HidePolicy.PLAY_STORE), HidePolicy.unhideCandidates(emptySet()))
        assertEquals(
            listOf("com.android.chrome", HidePolicy.PLAY_STORE),
            HidePolicy.unhideCandidates(setOf("com.android.chrome", HidePolicy.PLAY_STORE)),
        )
    }

    @Test
    fun failedUnhidesAreRetriedOnlyIfStillInstalled() {
        val left = HidePolicy.afterUnhide(listOf("gone", "stuck")) { it == "stuck" }
        assertEquals(setOf("stuck"), left)
        assertEquals(emptySet<String>(), HidePolicy.afterUnhide(emptyList()) { true })
    }
}
