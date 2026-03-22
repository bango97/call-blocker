package com.callblocker.model

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "block_rules")
data class BlockRule(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val label: String,
    val pattern: String,
    val type: PatternType,
    val isEnabled: Boolean = true,
    val createdAt: Long = System.currentTimeMillis()
)
