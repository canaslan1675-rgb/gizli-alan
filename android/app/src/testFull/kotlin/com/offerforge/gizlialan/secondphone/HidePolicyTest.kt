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
    fun toHideTakesEveryLaunchableHideableApp() {
        val launchable = listOf(
            "com.whatsapp", self, "com.google.android.gms", HidePolicy.PLAY_STORE,
            "com.android.chrome", "com.whatsapp", "com.android.settings",
            "com.miui.securitycenter", "org.telegram.messenger",
        )
        assertEquals(
            listOf("com.android.chrome", HidePolicy.PLAY_STORE, "com.whatsapp", "org.telegram.messenger"),
            HidePolicy.toHide(launchable, self),
        )
    }

    @Test
    fun recordedButVisibleAppsAreHiddenAgain() {
        // #45: an app we recorded earlier that is launchable again (e.g. Play
        // re-installed it) must be hidden again, and stays recorded once.
        val recorded = setOf("com.whatsapp")
        val now = HidePolicy.toHide(listOf("com.whatsapp", "com.newapp"), self)
        assertEquals(listOf("com.newapp", "com.whatsapp"), now)
        assertEquals(setOf("com.whatsapp", "com.newapp"), HidePolicy.afterHide(recorded, now))
    }

    @Test
    fun appInstalledBetweenLocksIsPickedUpAndRestored() {
        var recorded = HidePolicy.afterHide(emptySet(), HidePolicy.toHide(listOf("a.one"), self))
        // Unlock restores exactly what we hid.
        assertEquals(listOf("a.one", HidePolicy.PLAY_STORE), HidePolicy.unhideCandidates(recorded))
        recorded = HidePolicy.afterUnhide(emptyList()) { true }
        // New app installed while unlocked; next lock hides both.
        recorded = HidePolicy.afterHide(recorded, HidePolicy.toHide(listOf("a.one", "b.two"), self))
        assertEquals(setOf("a.one", "b.two"), recorded)
    }

    @Test
    fun suspendFallbackOnlyForHideablePackagesNotAlreadySuspended() {
        assertEquals(
            listOf("x.stuck"),
            HidePolicy.toSuspend(listOf("x.stuck", self, "com.google.android.gms", "y.done"), self, setOf("y.done")),
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

    @Test
    fun lockTargetsAddInstalledFileBrowserEvenWithoutLauncherEntry() {
        val t = HidePolicy.lockTargets(listOf("com.whatsapp")) { it == "com.google.android.documentsui" }
        assertEquals(setOf("com.whatsapp", "com.google.android.documentsui"), t)
        assertEquals(setOf("x"), HidePolicy.lockTargets(listOf("x")) { false })
    }

    @Test
    fun lockRestrictionsAreTheUserManagerConstants() {
        assertEquals(
            listOf("no_cross_profile_copy_paste", "no_sharing_into_profile"),
            HidePolicy.LOCK_RESTRICTIONS,
        )
    }
}
