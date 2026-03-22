package com.callblocker.data

import androidx.room.TypeConverter
import com.callblocker.model.PatternType

class Converters {
    @TypeConverter
    fun fromPatternType(type: PatternType): String = type.name

    @TypeConverter
    fun toPatternType(name: String): PatternType = PatternType.valueOf(name)
}
