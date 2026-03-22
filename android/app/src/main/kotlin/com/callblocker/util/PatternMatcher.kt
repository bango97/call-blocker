package com.callblocker.util

import com.callblocker.model.BlockRule
import com.callblocker.model.PatternType

/**
 * Stateless, allocation-minimal pattern matching used in the hot path of
 * BlockingCallScreeningService. Must be fast — the service has a 5-second deadline.
 */
object PatternMatcher {

    /**
     * Returns true if [incomingNumber] matches [rule].
     *
     * Both the incoming number and pattern are normalized to digits only before
     * comparison. For wildcard, 'x'/'X' in the pattern matches any single digit.
     *
     * E.164 numbers (e.g. "+84912345678") are normalized to local format by
     * stripping the leading country-code prefix if it maps to a leading "0".
     * This handles the common Vietnamese case of +84 ↔ 0.
     */
    fun matches(incomingNumber: String, rule: BlockRule): Boolean {
        if (!rule.isEnabled) return false

        val digits = normalize(incomingNumber)
        val pat = rule.pattern.lowercase()

        return when (rule.type) {
            PatternType.EXACT -> digits == pat

            PatternType.PREFIX -> digits.startsWith(pat)

            PatternType.WILDCARD -> {
                if (digits.length != pat.length) return false
                digits.indices.all { i ->
                    pat[i] == 'x' || digits[i] == pat[i]
                }
            }
        }
    }

    /**
     * Checks a number against a list of rules, returning the first matching rule or null.
     */
    fun firstMatch(incomingNumber: String, rules: List<BlockRule>): BlockRule? =
        rules.firstOrNull { matches(incomingNumber, it) }

    // MARK: - Normalization

    /**
     * Strips non-digit characters and normalizes E.164 to local format.
     * "+84912345678" → "0912345678" (Vietnamese example)
     */
    fun normalize(number: String): String {
        val digits = number.filter { it.isDigit() }
        // E.164 → local: strip leading country code and replace with "0"
        // Vietnamese: +84 (84) → 0
        if (digits.startsWith("84") && digits.length == 11) {
            return "0" + digits.substring(2)
        }
        return digits
    }
}
