package com.callblocker.viewmodel

import android.app.Application
import android.app.role.RoleManager
import android.os.Build
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.callblocker.CallBlockerApp
import com.callblocker.model.BlockRule
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

class RuleListViewModel(app: Application) : AndroidViewModel(app) {

    private val repo = (app as CallBlockerApp).repository

    val rules: StateFlow<List<BlockRule>> = repo.allRules
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    val hasScreeningRole: Boolean
        get() = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            getApplication<Application>()
                .getSystemService(RoleManager::class.java)
                ?.isRoleHeld(RoleManager.ROLE_CALL_SCREENING) == true
        } else {
            false
        }

    fun delete(rule: BlockRule) = viewModelScope.launch {
        repo.delete(rule)
    }

    fun toggleEnabled(rule: BlockRule) = viewModelScope.launch {
        repo.setEnabled(rule.id, !rule.isEnabled)
    }
}
