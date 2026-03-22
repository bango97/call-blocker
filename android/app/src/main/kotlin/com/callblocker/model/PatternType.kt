package com.callblocker.model

enum class PatternType {
    /** Exact 10-digit number, e.g. "0912345678" */
    EXACT,

    /** Leading digits that must match, e.g. "0900" blocks all 0900xxxxxx */
    PREFIX,

    /** Fixed-length pattern where 'x' matches any single digit, e.g. "09xx1234" */
    WILDCARD;

    val displayName: String get() = when (this) {
        EXACT    -> "Exact"
        PREFIX   -> "Prefix"
        WILDCARD -> "Wildcard"
    }

    val placeholder: String get() = when (this) {
        EXACT    -> "0912345678"
        PREFIX   -> "0900  (blocks 0900xxxxxx)"
        WILDCARD -> "09xx1234  (x = any digit)"
    }

    val hint: String get() = when (this) {
        EXACT    -> "Blocks this exact number."
        PREFIX   -> "Blocks all numbers starting with this prefix."
        WILDCARD -> "Use 'x' as a wildcard for any single digit."
    }
}
