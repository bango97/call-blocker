package com.callblocker

import android.app.Application
import com.callblocker.data.BlockRuleDatabase
import com.callblocker.data.BlockRuleRepository
import com.callblocker.model.BlockRule
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

/**
 * Application class that maintains a warm in-memory cache of enabled rules.
 *
 * This cache is critical for the BlockingCallScreeningService, which must
 * respond within 5 seconds. Reading from Room synchronously is risky;
 * reading from an in-memory StateFlow is instant and always current.
 */
class CallBlockerApp : Application() {

    private val appScope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    private val _ruleCache = MutableStateFlow<List<BlockRule>>(emptyList())

    /** Always-current list of enabled rules — read synchronously from the screening service. */
    val ruleCache: StateFlow<List<BlockRule>> = _ruleCache

    lateinit var repository: BlockRuleRepository
        private set

    override fun onCreate() {
        super.onCreate()
        val db = BlockRuleDatabase.getInstance(this)
        repository = BlockRuleRepository(db.blockRuleDao())

        // Keep cache warm — updates whenever the DB changes
        appScope.launch {
            repository.allRules.collect { rules ->
                _ruleCache.value = rules.filter { it.isEnabled }
            }
        }
    }
}
