package com.callblocker

import com.callblocker.model.BlockRule
import com.callblocker.model.PatternType
import com.callblocker.util.PatternMatcher
import org.junit.Assert.*
import org.junit.Test

class PatternMatcherTest {

    private fun rule(pattern: String, type: PatternType, enabled: Boolean = true) =
        BlockRule(label = "test", pattern = pattern, type = type, isEnabled = enabled)

    // MARK: - Exact

    @Test fun `exact - matches identical number`() {
        assertTrue(PatternMatcher.matches("0912345678", rule("0912345678", PatternType.EXACT)))
    }

    @Test fun `exact - no match on different number`() {
        assertFalse(PatternMatcher.matches("0912345679", rule("0912345678", PatternType.EXACT)))
    }

    @Test fun `exact - strips non-digits from incoming`() {
        assertTrue(PatternMatcher.matches("+84912345678", rule("0912345678", PatternType.EXACT)))
    }

    // MARK: - Prefix

    @Test fun `prefix - matches number starting with prefix`() {
        assertTrue(PatternMatcher.matches("0900123456", rule("0900", PatternType.PREFIX)))
    }

    @Test fun `prefix - no match on different prefix`() {
        assertFalse(PatternMatcher.matches("0901123456", rule("0900", PatternType.PREFIX)))
    }

    @Test fun `prefix - exact length match`() {
        assertTrue(PatternMatcher.matches("0900", rule("0900", PatternType.PREFIX)))
    }

    // MARK: - Wildcard

    @Test fun `wildcard - x matches any digit`() {
        assertTrue(PatternMatcher.matches("0912345678", rule("09x2345678", PatternType.WILDCARD)))
        assertTrue(PatternMatcher.matches("0902345678", rule("09x2345678", PatternType.WILDCARD)))
        assertTrue(PatternMatcher.matches("0982345678", rule("09x2345678", PatternType.WILDCARD)))
    }

    @Test fun `wildcard - multiple x positions`() {
        assertTrue(PatternMatcher.matches("09121234", rule("09xx1234", PatternType.WILDCARD)))
        assertTrue(PatternMatcher.matches("09991234", rule("09xx1234", PatternType.WILDCARD)))
    }

    @Test fun `wildcard - length mismatch returns false`() {
        assertFalse(PatternMatcher.matches("091212345", rule("09xx1234", PatternType.WILDCARD)))
    }

    @Test fun `wildcard - non-x must match exactly`() {
        assertFalse(PatternMatcher.matches("09121235", rule("09xx1234", PatternType.WILDCARD)))
    }

    // MARK: - Disabled rule

    @Test fun `disabled rule never matches`() {
        assertFalse(PatternMatcher.matches("0912345678",
            rule("0912345678", PatternType.EXACT, enabled = false)))
    }

    // MARK: - Normalization

    @Test fun `normalize strips non-digits`() {
        assertEquals("0912345678", PatternMatcher.normalize("+84912345678"))
        assertEquals("0912345678", PatternMatcher.normalize("0912345678"))
        assertEquals("0912345678", PatternMatcher.normalize("091-234-5678"))
    }

    // MARK: - firstMatch

    @Test fun `firstMatch returns first matching rule`() {
        val rules = listOf(
            rule("0800", PatternType.PREFIX),
            rule("0900", PatternType.PREFIX),
            rule("0912345678", PatternType.EXACT)
        )
        val match = PatternMatcher.firstMatch("0900123456", rules)
        assertEquals("0900", match?.pattern)
    }

    @Test fun `firstMatch returns null when no rule matches`() {
        val rules = listOf(rule("0800", PatternType.PREFIX))
        assertNull(PatternMatcher.firstMatch("0912345678", rules))
    }
}
