package com.callblocker.data

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import com.callblocker.model.BlockRule

@Database(entities = [BlockRule::class], version = 1, exportSchema = false)
@TypeConverters(Converters::class)
abstract class BlockRuleDatabase : RoomDatabase() {

    abstract fun blockRuleDao(): BlockRuleDao

    companion object {
        @Volatile private var INSTANCE: BlockRuleDatabase? = null

        fun getInstance(context: Context): BlockRuleDatabase =
            INSTANCE ?: synchronized(this) {
                INSTANCE ?: Room.databaseBuilder(
                    context.applicationContext,
                    BlockRuleDatabase::class.java,
                    "block_rules.db"
                ).build().also { INSTANCE = it }
            }
    }
}
