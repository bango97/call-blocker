package com.callblocker.viewmodel

import android.app.Application
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.callblocker.CallBlockerApp
import com.callblocker.model.BlockRule
import com.callblocker.model.PatternType
import kotlinx.coroutines.launch

class AddRuleViewModel(app: Application) : AndroidViewModel(app) {

    private val repo = (app as CallBlockerApp).repository

    var label by mutableStateOf("")
    var pattern by mutableStateOf("")
    var type by mutableStateOf(PatternType.EXACT)

    val normalizedPattern: String get() = when (type) {
        PatternType.EXACT, PatternType.PREFIX -> pattern.filter { it.isDigit() }
        PatternType.WILDCARD -> pattern.lowercase().filter { it.isDigit() || it == 'x' }
    }

    val validationError: String? get() {
        if (normalizedPattern.isEmpty()) return null
        return when (type) {
            PatternType.EXACT -> if (normalizedPattern.length !in 7..15)
                "Enter a valid phone number (7–15 digits)" else null
            PatternType.PREFIX -> if (normalizedPattern.length !in 3..9)
                "Enter 3–9 leading digits (e.g. 0900)" else null
            PatternType.WILDCARD -> {
                val xCount = normalizedPattern.count { it == 'x' }
                when {
                    normalizedPattern.length !in 7..15 -> "Length must be 7–15 characters"
                    xCount > 4 -> "Max 4 wildcards (x) — pattern matches ${expansionCount.format()} numbers"
                    else -> null
                }
            }
        }
    }

    val expansionCount: Int get() {
        val pat = normalizedPattern
        return when (type) {
            PatternType.EXACT -> if (pat.isNotEmpty()) 1 else 0
            PatternType.PREFIX -> {
                val suffix = maxOf(0, 10 - pat.length)
                Math.pow(10.0, suffix.toDouble()).toInt()
            }
            PatternType.WILDCARD -> {
                val xCount = pat.count { it == 'x' }
                Math.pow(10.0, xCount.toDouble()).toInt()
            }
        }
    }

    val canSave: Boolean get() =
        normalizedPattern.isNotEmpty() && validationError == null

    fun save(onDone: () -> Unit) {
        if (!canSave) return
        val pat = normalizedPattern
        val rule = BlockRule(
            label = label.ifBlank { defaultLabel(pat) },
            pattern = pat,
            type = type
        )
        viewModelScope.launch {
            repo.insert(rule)
            onDone()
        }
    }

    private fun defaultLabel(pat: String) = when (type) {
        PatternType.EXACT    -> "Block $pat"
        PatternType.PREFIX   -> "Block prefix $pat"
        PatternType.WILDCARD -> "Block pattern $pat"
    }

    private fun Int.format() = "%,d".format(this)
}
