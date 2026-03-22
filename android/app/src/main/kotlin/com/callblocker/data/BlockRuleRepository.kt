package com.callblocker.data

import com.callblocker.model.BlockRule
import kotlinx.coroutines.flow.Flow

class BlockRuleRepository(private val dao: BlockRuleDao) {

    val allRules: Flow<List<BlockRule>> = dao.observeAll()

    suspend fun insert(rule: BlockRule): Long = dao.insert(rule)

    suspend fun delete(rule: BlockRule) = dao.delete(rule)

    suspend fun deleteById(id: Long) = dao.deleteById(id)

    suspend fun setEnabled(id: Long, enabled: Boolean) = dao.setEnabled(id, enabled)

    suspend fun getEnabledRules(): List<BlockRule> = dao.getEnabledRules()
}
