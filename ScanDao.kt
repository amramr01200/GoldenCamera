package com.golden.camera.data
import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query
import androidx.room.Update
import kotlinx.coroutines.flow.Flow

@Dao
interface ScanDao {
    @Insert suspend fun insert(record: ScanRecord): Long
    @Query("SELECT * FROM scan_records ORDER BY scannedAt DESC") fun observeAll(): Flow<List<ScanRecord>>
    @Query("SELECT * FROM scan_records WHERE uid = :uid LIMIT 1") suspend fun findByUid(uid: String): ScanRecord?
    @Update suspend fun update(record: ScanRecord)
}
