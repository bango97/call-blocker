package com.callblocker.data

import androidx.room.*
import com.callblocker.model.BlockRule
import kotlinx.coroutines.flow.Flow

@Dao
interface BlockRuleDao {

    @Query("SELECT * FROM block_rules ORDER BY createdAt DESC")
    fun observeAll(): Flow<List<BlockRule>>

    @Query("SELECT * FROM block_rules WHERE isEnabled = 1")
    suspend fun getEnabledRules(): List<BlockRule>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(rule: BlockRule): Long

    @Delete
    suspend fun delete(rule: BlockRule)

    @Query("UPDATE block_rules SET isEnabled = :enabled WHERE id = :id")
    suspend fun setEnabled(id: Long, enabled: Boolean)

    @Query("DELETE FROM block_rules WHERE id = :id")
    suspend fun deleteById(id: Long)
}
