package com.golden.camera.data
import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "scan_records")
data class ScanRecord(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val uid: String,
    val techList: String,
    val atqa: String = "",
    val sak: String = "",
    val cardName: String = "",
    val allowedFloors: String = "1,2,3",
    val blocked: Boolean = false,
    val scannedAt: Long = System.currentTimeMillis()
)
