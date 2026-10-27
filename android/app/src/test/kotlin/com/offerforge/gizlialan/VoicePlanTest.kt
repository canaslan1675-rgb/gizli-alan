package com.offerforge.gizlialan

import com.offerforge.gizlialan.VoicePlan.Attempt
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class VoicePlanTest {
    @Test fun instantNoMatchFallsBack() {
        // The reported bug: ERROR_NO_MATCH right after tapping, nothing said.
        assertTrue(VoicePlan.shouldFallback(VoicePlan.NO_MATCH, speechBegan = false, elapsedMs = 120))
        assertTrue(VoicePlan.shouldFallback(VoicePlan.SPEECH_TIMEOUT, false, 50))
    }

    @Test fun realNoMatchDoesNotFallBack() {
        assertFalse(VoicePlan.shouldFallback(VoicePlan.NO_MATCH, speechBegan = true, elapsedMs = 300))
        assertFalse(VoicePlan.shouldFallback(VoicePlan.NO_MATCH, false, 4000))
        assertFalse(VoicePlan.shouldFallback(VoicePlan.SPEECH_TIMEOUT, false, 6000))
    }

    @Test fun otherErrorsFallBack() {
        for (e in listOf(1, 2, 3, 4, 5, 8, 9, 10, 11, 12, 13, 14)) {
            assertTrue("e$e", VoicePlan.shouldFallback(e, true, 9000))
        }
    }

    @Test fun attemptOrder() {
        assertEquals(
            listOf(Attempt.DEFAULT, Attempt.GOOGLE, Attempt.NO_LANG, Attempt.ON_DEVICE, Attempt.DIALOG),
            VoicePlan.attempts(hasGoogle = true, hasOnDevice = true, hasDialog = true),
        )
        assertEquals(
            listOf(Attempt.DEFAULT, Attempt.NO_LANG),
            VoicePlan.attempts(hasGoogle = false, hasOnDevice = false, hasDialog = false),
        )
        assertEquals("e7", VoicePlan.code(7))
    }

    @Test fun finalCodeNeverBareError() {
        assertEquals("e7", VoicePlan.finalCode("default:e7"))
        assertEquals("x:SecurityException",
            VoicePlan.finalCode("on_device:" + VoicePlan.exc("SecurityException", "not allowed  to bind")))
        assertEquals("x_IllegalArgumentException(bad component)",
            VoicePlan.exc("IllegalArgumentException", "bad   component"))
        assertEquals("x:unknown", VoicePlan.finalCode("weird"))
    }
}
