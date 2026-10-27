package com.golden.camera

import android.nfc.NfcAdapter
import android.nfc.Tag
import android.nfc.tech.MifareClassic
import android.nfc.tech.Ndef
import android.nfc.tech.NfcA
import android.os.Bundle
import android.widget.Button
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.golden.camera.data.AppDatabase
import com.golden.camera.data.ScanRecord
import kotlinx.coroutines.launch

class AdvancedNfcActivity : AppCompatActivity() {
    private lateinit var nfcAdapter: NfcAdapter?
    private lateinit var db: AppDatabase
    private lateinit var txtStatus: TextView
    private lateinit var txtUid: TextView
    private lateinit var txtDetails: TextView
    private lateinit var btnSave: Button

    private var currentUid = ""
    private var currentTech = ""
    private var currentAtqa = ""
    private var currentSak = ""

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_advanced_nfc)
        txtStatus = findViewById(R.id.txtNfcStatus)
        txtUid = findViewById(R.id.txtNfcUid)
        txtDetails = findViewById(R.id.txtNfcDetails)
        btnSave = findViewById(R.id.btnSaveNfc)
        
        db = AppDatabase.get(this)
        nfcAdapter = NfcAdapter.getDefaultAdapter(this)
        if (nfcAdapter == null) { Toast.makeText(this, "No NFC", Toast.LENGTH_LONG).show(); finish() }

        btnSave.setOnClickListener { saveCardToDatabase() }
    }

    override fun onResume() {
        super.onResume()
        nfcAdapter?.enableReaderMode(this, { tag -> runOnUiThread { handleTag(tag) } },
            NfcAdapter.FLAG_READER_NFC_A or NfcAdapter.FLAG_READER_NFC_B or NfcAdapter.FLAG_READER_NFC_F or NfcAdapter.FLAG_READER_NFC_V, null)
    }

    override fun onPause() { super.onPause(); nfcAdapter?.disableReaderMode(this) }

    private fun handleTag(tag: Tag) {
        currentUid = tag.id.joinToString("") { "%02X".format(it) }
        currentTech = tag.techList.joinToString(", ") { it.substringAfterLast('.') }
        val details = StringBuilder("UID: $currentUid\nTech: $currentTech\n")

        try { NfcA.get(tag)?.let { currentAtqa = it.atqa.joinToString("") { b -> "%02X".format(b) }; currentSak = "%02X".format(it.sak); details.append("ATQA: $currentAtqa | SAK: $currentSak\n") } } catch (_: Exception) {}
        try { MifareClassic.get(tag)?.let { details.append("MIFARE Classic (${it.size} bytes)\n") } } catch (_: Exception) {}
        try { Ndef.get(tag)?.let { details.append("NDEF: ${it.type}, Writable: ${it.isWritable}\n") } } catch (_: Exception) {}

        txtUid.text = "Card UID: $currentUid"
        txtDetails.text = details.toString()
        txtStatus.text = "Read Success ✓"
        btnSave.isEnabled = true
    }

    private fun saveCardToDatabase() {
        if (currentUid.isBlank()) return
        lifecycleScope.launch {
            if (db.scanDao().findByUid(currentUid) == null) {
                db.scanDao().insert(ScanRecord(uid = currentUid, techList = currentTech, atqa = currentAtqa, sak = currentSak, cardName = "NFC Card"))
                Toast.makeText(this@AdvancedNfcActivity, "Saved to DB ✓", Toast.LENGTH_SHORT).show()
            } else { Toast.makeText(this@AdvancedNfcActivity, "Already Saved", Toast.LENGTH_SHORT).show() }
        }
    }
}
