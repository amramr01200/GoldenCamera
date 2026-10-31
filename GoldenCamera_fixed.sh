#!/bin/bash

echo "⏳ جاري إنشاء مشروع GoldenCamera..."

# 1. إنشاء المجلدات
mkdir -p GoldenCamera/.github/workflows
mkdir -p GoldenCamera/app/src/main/java/com/golden/camera/data
mkdir -p GoldenCamera/app/src/main/res/layout
mkdir -p GoldenCamera/app/src/main/res/values
mkdir -p GoldenCamera/app/src/main/res/values-ar
mkdir -p GoldenCamera/app/src/main/res/drawable
mkdir -p GoldenCamera/app/src/main/res/mipmap-anydpi-v26

# 2. ملفات Gradle
cat > GoldenCamera/settings.gradle.kts << 'EOF'
pluginManagement {
    repositories { google(); mavenCentral(); gradlePluginPortal() }
}
dependencyResolutionManagement {
    repositories { google(); mavenCentral() }
}
rootProject.name = "GoldenCamera"
include(":app")
EOF

cat > GoldenCamera/build.gradle.kts << 'EOF'
plugins {
    id("com.android.application") version "8.5.2" apply false
    id("org.jetbrains.kotlin.android") version "1.9.24" apply false
    id("org.jetbrains.kotlin.kapt") version "1.9.24" apply false
}
EOF

cat > GoldenCamera/gradle.properties << 'EOF'
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=true
kotlin.code.style=official
EOF

# 3. GitHub Actions
cat > GoldenCamera/.github/workflows/build.yml << 'EOF'
name: Build APK
on:
  push:
    branches: [ main ]
  workflow_dispatch:
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: 17
      - uses: android-actions/setup-android@v3
      - uses: gradle/actions/setup-gradle@v4
        with:
          gradle-version: 8.7
      - name: Build debug APK
        run: gradle assembleDebug --no-daemon
      - uses: actions/upload-artifact@v4
        with:
          name: GoldenCamera-APK
          path: app/build/outputs/apk/debug/app-debug.apk
EOF

# 4. إعدادات تطبيق الأندرويد
cat > GoldenCamera/app/build.gradle.kts << 'EOF'
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.kapt")
}
android {
    namespace = "com.golden.camera"
    compileSdk = 34
    defaultConfig {
        applicationId = "com.golden.camera"
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }
    buildFeatures { viewBinding = true }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }
}
dependencies {
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("com.google.android.material:material:1.12.0")
    val camerax = "1.3.4"
    implementation("androidx.camera:camera-core:$camerax")
    implementation("androidx.camera:camera-camera2:$camerax")
    implementation("androidx.camera:camera-lifecycle:$camerax")
    implementation("androidx.camera:camera-view:$camerax")
    implementation("androidx.camera:camera-extensions:$camerax")
    implementation("io.github.sceneview:arsceneview:2.2.0")
    implementation("com.google.mlkit:text-recognition:16.0.1")
    implementation("com.google.mlkit:language-id:17.0.6")
    implementation("com.google.mlkit:translate:17.0.3")
    implementation("androidx.room:room-runtime:2.6.1")
    implementation("androidx.room:room-ktx:2.6.1")
    kapt("androidx.room:room-compiler:2.6.1")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.7.0")
}
EOF

cat > GoldenCamera/app/proguard-rules.pro << 'EOF'
# GoldenCamera Proguard
EOF

cat > GoldenCamera/app/src/main/AndroidManifest.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.NFC" />
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="28" />
    <uses-feature android:name="android.hardware.camera.any" android:required="true" />
    <uses-feature android:name="android.hardware.camera.ar" android:required="false" />
    <uses-feature android:name="android.hardware.nfc" android:required="false" />
    <meta-data android:name="com.google.ar.core" android:value="optional" />
    <application
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:roundIcon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:supportsRtl="true"
        android:theme="@style/Theme.GoldenCamera">
        <activity android:name=".MainActivity" android:exported="true" android:screenOrientation="portrait">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
        <activity android:name=".ARMeasureActivity" android:exported="false" />
        <activity android:name=".OcrTranslateActivity" android:exported="false" />
        <activity android:name=".AdvancedNfcActivity" android:exported="false" />
        <activity android:name=".ElevatorSimActivity" android:exported="false" />
    </application>
</manifest>
EOF

# 5. كود قاعدة البيانات (Room)
cat > GoldenCamera/app/src/main/java/com/golden/camera/data/ScanRecord.kt << 'EOF'
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
EOF

cat > GoldenCamera/app/src/main/java/com/golden/camera/data/ScanDao.kt << 'EOF'
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
EOF

cat > GoldenCamera/app/src/main/java/com/golden/camera/data/AppDatabase.kt << 'EOF'
package com.golden.camera.data
import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase

@Database(entities = [ScanRecord::class], version = 1, exportSchema = false)
abstract class AppDatabase : RoomDatabase() {
    abstract fun scanDao(): ScanDao
    companion object {
        @Volatile private var INSTANCE: AppDatabase? = null
        fun get(context: Context): AppDatabase =
            INSTANCE ?: synchronized(this) {
                INSTANCE ?: Room.databaseBuilder(
                    context.applicationContext, AppDatabase::class.java, "golden_camera.db"
                ).build().also { INSTANCE = it }
            }
    }
}
EOF

# 6. شاشة الكاميرا الرئيسية
cat > GoldenCamera/app/src/main/java/com/golden/camera/MainActivity.kt << 'EOF'
package com.golden.camera

import android.Manifest
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.os.Build
import android.os.Bundle
import android.provider.MediaStore
import android.view.ScaleGestureDetector
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.camera.core.Camera
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import androidx.camera.core.Preview
import androidx.camera.extensions.ExtensionMode
import androidx.camera.extensions.ExtensionsManager
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import com.golden.camera.databinding.ActivityMainBinding
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class MainActivity : AppCompatActivity() {
    private lateinit var binding: ActivityMainBinding
    private lateinit var cameraExecutor: ExecutorService
    private var imageCapture: ImageCapture? = null
    private var camera: Camera? = null
    private var cameraProvider: ProcessCameraProvider? = null
    private var nightSelector: CameraSelector? = null
    private var useNightMode = false
    private var flashOn = false

    private val requestPermission = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted -> if (granted) startCamera() }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)
        cameraExecutor = Executors.newSingleThreadExecutor()
        
        setupZoom()
        binding.btnCapture.setOnClickListener { takePhoto() }
        binding.btnFlash.setOnClickListener { toggleFlash() }
        binding.btnNight.setOnClickListener { toggleNight() }
        binding.btnScreenshot.setOnClickListener { takeScreenshot() }
        binding.btnMeasure.setOnClickListener { startActivity(Intent(this, ARMeasureActivity::class.java)) }
        binding.btnOcr.setOnClickListener { startActivity(Intent(this, OcrTranslateActivity::class.java)) }
        binding.btnNfc.setOnClickListener { startActivity(Intent(this, AdvancedNfcActivity::class.java)) }
        binding.btnElevator.setOnClickListener { startActivity(Intent(this, ElevatorSimActivity::class.java)) }

        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) 
            startCamera()
        else requestPermission.launch(Manifest.permission.CAMERA)
    }

    private fun startCamera() {
        val future = ProcessCameraProvider.getInstance(this)
        future.addListener({
            cameraProvider = future.get()
            probeNightMode()
            bindUseCases()
        }, ContextCompat.getMainExecutor(this))
    }

    private fun bindUseCases() {
        val provider = cameraProvider ?: return
        provider.unbindAll()
        val preview = Preview.Builder().build().also { it.setSurfaceProvider(binding.viewFinder.surfaceProvider) }
        imageCapture = ImageCapture.Builder().setCaptureMode(ImageCapture.CAPTURE_MODE_MAXIMIZE_QUALITY).build()
        val base = CameraSelector.DEFAULT_BACK_CAMERA
        val selector = if (useNightMode && nightSelector != null) nightSelector!! else base
        try {
            camera = provider.bindToLifecycle(this, selector, preview, imageCapture)
            applyFlash()
            binding.txtZoom.text = "1.0x"
        } catch (e: Exception) { Toast.makeText(this, "Error: ${e.message}", Toast.LENGTH_SHORT).show() }
    }

    private fun setupZoom() {
        val detector = ScaleGestureDetector(this, object : ScaleGestureDetector.SimpleOnScaleGestureListener() {
            override fun onScale(detector: ScaleGestureDetector): Boolean {
                val cam = camera ?: return true
                val state = cam.cameraInfo.zoomState.value ?: return true
                val newRatio = (state.zoomRatio * detector.scaleFactor).coerceIn(state.minZoomRatio, state.maxZoomRatio)
                cam.cameraControl.setZoomRatio(newRatio)
                binding.txtZoom.text = String.format("%.1fx", newRatio)
                return true
            }
        })
        binding.viewFinder.setOnTouchListener { v, event ->
            detector.onTouchEvent(event)
            if (event.action == android.view.MotionEvent.ACTION_UP) v.performClick()
            true
        }
    }

    private fun toggleFlash() {
        flashOn = !flashOn
        applyFlash()
        binding.btnFlash.text = if (flashOn) "Flash: ON" else "Flash: OFF"
    }

    private fun applyFlash() {
        imageCapture?.flashMode = if (flashOn) ImageCapture.FLASH_MODE_ON else ImageCapture.FLASH_MODE_OFF
    }

    private fun probeNightMode() {
        val provider = cameraProvider ?: return
        try {
            val extFuture = ExtensionsManager.getInstanceAsync(this, provider)
            extFuture.addListener({
                try {
                    val manager = extFuture.get()
                    if (manager.isExtensionAvailable(CameraSelector.DEFAULT_BACK_CAMERA, ExtensionMode.NIGHT)) {
                        nightSelector = manager.getExtensionEnabledCameraSelector(CameraSelector.DEFAULT_BACK_CAMERA, ExtensionMode.NIGHT)
                    } else { binding.btnNight.isEnabled = false; binding.btnNight.text = "Night: N/A" }
                } catch (e: Exception) { binding.btnNight.isEnabled = false }
            }, ContextCompat.getMainExecutor(this))
        } catch (e: Exception) { binding.btnNight.isEnabled = false }
    }

    private fun toggleNight() {
        if (nightSelector == null) return
        useNightMode = !useNightMode
        binding.btnNight.text = if (useNightMode) "Night: ON" else "Night: OFF"
        bindUseCases()
    }

    private fun takePhoto() {
        val capture = imageCapture ?: return
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, "GOLD_${System.currentTimeMillis()}.jpg")
            put(MediaStore.MediaColumns.MIME_TYPE, "image/jpeg")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) put(MediaStore.MediaColumns.RELATIVE_PATH, "Pictures/GoldenCamera")
        }
        val output = ImageCapture.OutputFileOptions.Builder(contentResolver, MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values).build()
        capture.takePicture(output, cameraExecutor, object : ImageCapture.OnImageSavedCallback {
            override fun onImageSaved(results: ImageCapture.OutputFileResults) { runOnUiThread { Toast.makeText(this@MainActivity, "Saved ✓", Toast.LENGTH_SHORT).show() } }
            override fun onError(exception: ImageCaptureException) { runOnUiThread { Toast.makeText(this@MainActivity, "Failed", Toast.LENGTH_SHORT).show() } }
        })
    }

    private fun takeScreenshot() {
        val bitmap: Bitmap? = binding.viewFinder.bitmap ?: return
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, "SCR_${System.currentTimeMillis()}.png")
            put(MediaStore.MediaColumns.MIME_TYPE, "image/png")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) put(MediaStore.MediaColumns.RELATIVE_PATH, "Pictures/GoldenCamera/Screens")
        }
        val uri = contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
        uri?.let {
            contentResolver.openOutputStream(it)?.use { out -> bitmap.compress(Bitmap.CompressFormat.PNG, 100, out) }
            Toast.makeText(this, "Screenshot Saved ✓", Toast.LENGTH_SHORT).show()
        }
    }
    override fun onDestroy() { super.onDestroy(); cameraExecutor.shutdown() }
}
EOF

# 7. شاشة قياس المسافات (AR)
cat > GoldenCamera/app/src/main/java/com/golden/camera/ARMeasureActivity.kt << 'EOF'
package com.golden.camera

import android.os.Bundle
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.google.ar.core.Anchor
import com.google.ar.core.TrackingState
import io.github.sceneview.ar.ARSceneView
import kotlin.math.pow

class ARMeasureActivity : AppCompatActivity() {
    private lateinit var sceneView: ARSceneView
    private lateinit var resultText: TextView
    private val anchors = mutableListOf<Anchor>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_ar_measure)
        sceneView = findViewById(R.id.sceneView)
        resultText = findViewById(R.id.txtMeasureResult)
        
        sceneView.setOnTouchListener { _, event ->
            if (event.action == android.view.MotionEvent.ACTION_UP) {
                addMeasurePoint(event.x, event.y)
            }
            true
        }
    }

    private fun addMeasurePoint(x: Float, y: Float) {
        val frame = sceneView.frame ?: return
        if (frame.camera.trackingState != TrackingState.TRACKING) {
            Toast.makeText(this, "Move device slowly", Toast.LENGTH_SHORT).show()
            return
        }
        val hit = frame.hitTest(x, y).firstOrNull() ?: return
        val anchor = hit.createAnchor()
        anchors.add(anchor)
        
        if (anchors.size >= 2) {
            val a = anchors[anchors.size - 2]
            val b = anchors[anchors.size - 1]
            val distanceCm = calculateDistance(a, b) * 100
            resultText.text = String.format("Distance: %.1f cm", distanceCm)
        }
    }

    private fun calculateDistance(a: Anchor, b: Anchor): Float {
        val p1 = a.pose.position
        val p2 = b.pose.position
        return Math.sqrt(((p1.x - p2.x).pow(2) + (p1.y - p2.y).pow(2) + (p1.z - p2.z).pow(2)).toDouble()).toFloat()
    }

    override fun onDestroy() { super.onDestroy(); anchors.forEach { it.detach() }; anchors.clear(); sceneView.destroy() }
}
EOF

# 8. شاشة ترجمة النصوص (OCR + Translate)
cat > GoldenCamera/app/src/main/java/com/golden/camera/OcrTranslateActivity.kt << 'EOF'
package com.golden.camera

import android.content.ContentValues
import android.graphics.Bitmap
import android.os.Build
import android.os.Bundle
import android.provider.MediaStore
import android.widget.Button
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import com.google.mlkit.nl.languageid.LanguageIdentification
import com.google.mlkit.nl.translate.DownloadConditions
import com.google.mlkit.nl.translate.TranslateLanguage
import com.google.mlkit.nl.translate.Translation
import com.google.mlkit.nl.translate.Translator
import com.google.mlkit.nl.translate.TranslatorOptions
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import java.util.concurrent.Executors
import androidx.camera.core.ExperimentalGetImage

class OcrTranslateActivity : AppCompatActivity() {
    private lateinit var previewView: PreviewView
    private lateinit var resultText: TextView
    private lateinit var translationText: TextView
    private val cameraExecutor = Executors.newSingleThreadExecutor()
    private val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
    private var translator: Translator? = null
    private var currentTargetLang = TranslateLanguage.ARABIC
    private var lastTranslatedText = ""

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_ocr_translate)
        previewView = findViewById(R.id.previewOcr)
        resultText = findViewById(R.id.txtOcrResult)
        translationText = findViewById(R.id.txtTranslation)
        
        startCameraWithOcr()
        
        findViewById<Button>(R.id.btnSwitchLang).setOnClickListener {
            currentTargetLang = if (currentTargetLang == TranslateLanguage.ARABIC) TranslateLanguage.ENGLISH else TranslateLanguage.ARABIC
            translator?.close(); translator = null; translationText.text = ""
        }
        findViewById<Button>(R.id.btnOcrShot).setOnClickListener { takeScreenshot() }
    }

    private fun startCameraWithOcr() {
        val future = ProcessCameraProvider.getInstance(this)
        future.addListener({
            val provider = future.get()
            val preview = Preview.Builder().build().also { it.setSurfaceProvider(previewView.surfaceProvider) }
            val analysis = ImageAnalysis.Builder().setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST).build()
                .also { it.setAnalyzer(cameraExecutor, TextAnalyzer()) }
            provider.unbindAll()
            provider.bindToLifecycle(this, CameraSelector.DEFAULT_BACK_CAMERA, preview, analysis)
        }, ContextCompat.getMainExecutor(this))
    }

    private inner class TextAnalyzer : ImageAnalysis.Analyzer {
        @androidx.annotation.OptIn(ExperimentalGetImage::class)
        override fun analyze(imageProxy: androidx.camera.core.ImageProxy) {
            val mediaImage = imageProxy.image ?: run { imageProxy.close(); return }
            val image = InputImage.fromMediaImage(mediaImage, imageProxy.imageInfo.rotationDegrees)
            recognizer.process(image).addOnSuccessListener { visionText ->
                val text = visionText.text.trim()
                if (text.isNotBlank() && text != lastTranslatedText) {
                    runOnUiThread { resultText.text = text }
                    translateToTarget(text)
                }
            }.addOnCompleteListener { imageProxy.close() }
        }
    }

    private fun translateToTarget(text: String) {
        LanguageIdentification.getClient().identifyLanguage(text).addOnSuccessListener { langTag ->
            val sourceLang = TranslateLanguage.fromLanguageTag(langTag) ?: TranslateLanguage.ENGLISH
            if (sourceLang == currentTargetLang) {
                runOnUiThread { translationText.text = text }; return@addOnSuccessListener
            }
            if (translator == null) {
                val options = TranslatorOptions.Builder().setSourceLanguage(sourceLang).setTargetLanguage(currentTargetLang).build()
                translator = Translation.getClient(options)
            }
            val conditions = DownloadConditions.Builder().requireWifi().build()
            translator!!.downloadModelIfNeeded(conditions).addOnSuccessListener {
                translator!!.translate(text).addOnSuccessListener { tr ->
                    lastTranslatedText = text
                    runOnUiThread { translationText.text = tr }
                }
            }.addOnFailureListener { runOnUiThread { translationText.text = "Download failed" } }
        }
    }

    private fun takeScreenshot() {
        val bitmap: Bitmap? = previewView.bitmap ?: return
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, "OCR_${System.currentTimeMillis()}.png")
            put(MediaStore.MediaColumns.MIME_TYPE, "image/png")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) put(MediaStore.MediaColumns.RELATIVE_PATH, "Pictures/GoldenCamera/OCR")
        }
        val uri = contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
        uri?.let {
            contentResolver.openOutputStream(it)?.use { out -> bitmap.compress(Bitmap.CompressFormat.PNG, 100, out) }
            Toast.makeText(this, "Screenshot Saved", Toast.LENGTH_SHORT).show()
        }
    }
    override fun onDestroy() { super.onDestroy(); cameraExecutor.shutdown(); translator?.close(); recognizer.close() }
}
EOF

# 9. شاشة قارئ NFC
cat > GoldenCamera/app/src/main/java/com/golden/camera/AdvancedNfcActivity.kt << 'EOF'
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
    private var nfcAdapter: NfcAdapter? = null
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
EOF

# 10. شاشة محاكي المصعد 3D
cat > GoldenCamera/app/src/main/java/com/golden/camera/ElevatorSimActivity.kt << 'EOF'
package com.golden.camera

import android.os.Bundle
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import io.github.sceneview.SceneView
import io.github.sceneview.math.Position
import io.github.sceneview.math.Size
import io.github.sceneview.node.CubeNode
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

class ElevatorSimActivity : AppCompatActivity() {
    private lateinit var sceneView: SceneView
    private lateinit var txtStatus: TextView
    private var currentFloor = 1
    private var doorOpen = false
    private var cabinNode: CubeNode? = null
    private var leftDoor: CubeNode? = null
    private var rightDoor: CubeNode? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_elevator_sim)
        sceneView = findViewById(R.id.sceneViewSim)
        txtStatus = findViewById(R.id.txtSimStatus)
        
        setupScene()
        findViewById<Button>(R.id.btnFloor1).setOnClickListener { goToFloor(1) }
        findViewById<Button>(R.id.btnFloor2).setOnClickListener { goToFloor(2) }
        findViewById<Button>(R.id.btnFloor3).setOnClickListener { goToFloor(3) }
        findViewById<Button>(R.id.btnDoor).setOnClickListener { toggleDoor() }
    }

    private fun setupScene() {
        cabinNode = CubeNode(sceneView.engine).apply { size = Size(1.2f, 2.4f, 1.2f); position = Position(0f, 0f, 0f) }
        sceneView.addChildNode(cabinNode!!)
        leftDoor = CubeNode(sceneView.engine).apply { size = Size(0.55f, 2.2f, 0.1f); position = Position(-0.28f, 0f, 0.65f) }
        rightDoor = CubeNode(sceneView.engine).apply { size = Size(0.55f, 2.2f, 0.1f); position = Position(0.28f, 0f, 0.65f) }
        sceneView.addChildNode(leftDoor!!)
        sceneView.addChildNode(rightDoor!!)
        updateStatus()
    }

    private fun goToFloor(floor: Int) {
        if (floor == currentFloor) return
        lifecycleScope.launch {
            txtStatus.text = "Moving to Floor $floor..."
            val startY = cabinNode?.position?.y ?: 0f
            val targetY = (floor - 1) * 3f
            val steps = 30
            for (i in 1..steps) {
                delay(30)
                val y = startY + (targetY - startY) * i / steps
                cabinNode?.position = Position(0f, y, 0f)
                leftDoor?.position = Position(-0.28f, y, 0.65f)
                rightDoor?.position = Position(0.28f, y, 0.65f)
            }
            currentFloor = floor; updateStatus()
            if (!doorOpen) toggleDoor()
        }
    }

    private fun toggleDoor() {
        lifecycleScope.launch {
            val targetX = if (doorOpen) 0.28f else 0.7f
            val startOffset = if (doorOpen) 0.42f else 0f
            val steps = 15
            for (i in 1..steps) {
                delay(20)
                val offset = startOffset + ((targetX - 0.28f) - startOffset) * i / steps
                leftDoor?.position = Position(-0.28f - offset, leftDoor!!.position.y, leftDoor!!.position.z)
                rightDoor?.position = Position(0.28f + offset, rightDoor!!.position.y, rightDoor!!.position.z)
            }
            doorOpen = !doorOpen; updateStatus()
        }
    }

    private fun updateStatus() {
        txtStatus.text = "Floor $currentFloor — Door ${if (doorOpen) "Open" else "Closed"}"
    }

    override fun onDestroy() { super.onDestroy(); sceneView.destroy() }
}
EOF

# 11. ملفات الواجهات (Layouts)
cat > GoldenCamera/app/src/main/res/layout/activity_main.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent" android:background="@color/black_deep">
    <androidx.camera.view.PreviewView android:id="@+id/viewFinder" android:layout_width="match_parent" android:layout_height="match_parent" />
    <TextView android:id="@+id/txtZoom" android:layout_width="wrap_content" android:layout_height="wrap_content"
        android:layout_gravity="top|center_horizontal" android:layout_marginTop="24dp"
        android:background="@color/gold_translucent" android:paddingHorizontal="14dp" android:paddingVertical="6dp"
        android:text="1.0x" android:textColor="@color/black_deep" android:textStyle="bold" />
    <Button android:id="@+id/btnMeasure" android:layout_width="wrap_content" android:layout_height="wrap_content"
        android:layout_gravity="top|start" android:layout_margin="12dp" android:text="@string/btn_measure"
        android:backgroundTint="@color/gold" android:textColor="@color/black_deep" />
    <Button android:id="@+id/btnOcr" android:layout_width="wrap_content" android:layout_height="wrap_content"
        android:layout_gravity="top|end" android:layout_margin="12dp" android:text="@string/btn_ocr"
        android:backgroundTint="@color/gold_bright" android:textColor="@color/black_deep" />
    <Button android:id="@+id/btnNfc" android:layout_width="wrap_content" android:layout_height="wrap_content"
        android:layout_gravity="top|start" android:layout_marginTop="80dp" android:layout_marginStart="12dp"
        android:text="@string/btn_nfc" android:backgroundTint="@color/gold" android:textColor="@color/black_deep" />
    <Button android:id="@+id/btnElevator" android:layout_width="wrap_content" android:layout_height="wrap_content"
        android:layout_gravity="top|start" android:layout_marginTop="140dp" android:layout_marginStart="12dp"
        android:text="@string/btn_elevator" android:backgroundTint="@color/gold_bright" android:textColor="@color/black_deep" />
    <Button android:id="@+id/btnScreenshot" android:layout_width="56dp" android:layout_height="56dp"
        android:layout_gravity="center_vertical|end" android:layout_marginEnd="16dp" android:text="📸"
        android:textSize="22sp" android:backgroundTint="@color/gold_bright" android:textColor="@color/black_deep" />
    <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content"
        android:layout_gravity="bottom" android:orientation="horizontal" android:padding="16dp">
        <Button android:id="@+id/btnFlash" android:layout_width="0dp" android:layout_height="wrap_content"
            android:layout_weight="1" android:text="Flash: OFF" android:textColor="@color/black_deep" android:backgroundTint="@color/gold" />
        <Button android:id="@+id/btnCapture" android:layout_width="0dp" android:layout_height="wrap_content"
            android:layout_weight="1" android:layout_marginHorizontal="8dp" android:text="@string/btn_capture"
            android:textColor="@color/black_deep" android:backgroundTint="@color/gold_bright" android:textStyle="bold" />
        <Button android:id="@+id/btnNight" android:layout_width="0dp" android:layout_height="wrap_content"
            android:layout_weight="1" android:text="Night: OFF" android:textColor="@color/black_deep" android:backgroundTint="@color/gold" />
    </LinearLayout>
</FrameLayout>
EOF

cat > GoldenCamera/app/src/main/res/layout/activity_ar_measure.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent">
    <io.github.sceneview.ar.ARSceneView android:id="@+id/sceneView" android:layout_width="match_parent" android:layout_height="match_parent" />
    <TextView android:id="@+id/txtMeasureResult" android:layout_width="wrap_content" android:layout_height="wrap_content"
        android:layout_gravity="top|center_horizontal" android:layout_marginTop="32dp" android:background="@color/gold_translucent"
        android:padding="12dp" android:text="@string/ar_measure_hint" android:textColor="@color/black_deep" android:textStyle="bold" />
</FrameLayout>
EOF

cat > GoldenCamera/app/src/main/res/layout/activity_ocr_translate.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent"
    android:orientation="vertical" android:background="@color/black_deep">
    <androidx.camera.view.PreviewView android:id="@+id/previewOcr" android:layout_width="match_parent"
        android:layout_height="0dp" android:layout_weight="1" />
    <TextView android:id="@+id/txtOcrResult" android:layout_width="match_parent" android:layout_height="wrap_content"
        android:padding="10dp" android:maxLines="3" android:ellipsize="end" android:textColor="@color/gold" android:textSize="14sp" />
    <TextView android:id="@+id/txtTranslation" android:layout_width="match_parent" android:layout_height="wrap_content"
        android:padding="12dp" android:textColor="@color/gold_bright" android:textSize="20sp" android:textStyle="bold"
        android:maxLines="4" android:ellipsize="end" />
    <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content" android:orientation="horizontal" android:padding="8dp">
        <Button android:id="@+id/btnSwitchLang" android:layout_width="0dp" android:layout_height="wrap_content"
            android:layout_weight="1" android:layout_marginEnd="8dp" android:text="@string/switch_language"
            android:backgroundTint="@color/gold" android:textColor="@color/black_deep" />
        <Button android:id="@+id/btnOcrShot" android:layout_width="wrap_content" android:layout_height="wrap_content"
            android:text="📸" android:textSize="20sp" android:backgroundTint="@color/gold_bright" android:textColor="@color/black_deep" />
    </LinearLayout>
</LinearLayout>
EOF

cat > GoldenCamera/app/src/main/res/layout/activity_advanced_nfc.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent"
    android:orientation="vertical" android:padding="16dp" android:background="@color/black_deep">
    <TextView android:id="@+id/txtNfcStatus" android:layout_width="match_parent" android:layout_height="wrap_content"
        android:text="@string/nfc_hint" android:textColor="@color/gold_bright" android:textSize="18sp"
        android:textStyle="bold" android:gravity="center" android:padding="16dp" />
    <TextView android:id="@+id/txtNfcUid" android:layout_width="match_parent" android:layout_height="wrap_content"
        android:textColor="@color/gold_bright" android:textSize="20sp" android:textStyle="bold" android:padding="8dp" />
    <TextView android:id="@+id/txtNfcDetails" android:layout_width="match_parent" android:layout_height="0dp"
        android:layout_weight="1" android:textColor="@color/gold" android:textSize="16sp" android:padding="8dp" android:fontFamily="monospace" />
    <Button android:id="@+id/btnSaveNfc" android:layout_width="match_parent" android:layout_height="wrap_content"
        android:text="@string/save_card" android:enabled="false" android:backgroundTint="@color/gold" android:textColor="@color/black_deep" android:textStyle="bold" />
</LinearLayout>
EOF

cat > GoldenCamera/app/src/main/res/layout/activity_elevator_sim.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent"
    android:orientation="vertical" android:background="@color/black_deep">
    <io.github.sceneview.SceneView android:id="@+id/sceneViewSim" android:layout_width="match_parent"
        android:layout_height="0dp" android:layout_weight="1" />
    <TextView android:id="@+id/txtSimStatus" android:layout_width="match_parent" android:layout_height="wrap_content"
        android:padding="8dp" android:textColor="@color/gold_bright" android:textStyle="bold" android:gravity="center" />
    <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content" android:orientation="horizontal" android:padding="8dp">
        <Button android:id="@+id/btnFloor1" android:layout_width="0dp" android:layout_height="wrap_content" android:layout_weight="1" android:text="1" android:backgroundTint="@color/gold" android:textColor="@color/black_deep" />
        <Button android:id="@+id/btnFloor2" android:layout_width="0dp" android:layout_height="wrap_content" android:layout_weight="1" android:text="2" android:backgroundTint="@color/gold" android:textColor="@color/black_deep" />
        <Button android:id="@+id/btnFloor3" android:layout_width="0dp" android:layout_height="wrap_content" android:layout_weight="1" android:text="3" android:backgroundTint="@color/gold" android:textColor="@color/black_deep" />
        <Button android:id="@+id/btnDoor" android:layout_width="0dp" android:layout_height="wrap_content" android:layout_weight="1" android:text="Door" android:backgroundTint="@color/gold_bright" android:textColor="@color/black_deep" />
    </LinearLayout>
</LinearLayout>
EOF

# 12. الألوان والنصوص
cat > GoldenCamera/app/src/main/res/values/colors.xml << 'EOF'
<resources>
    <color name="gold">#E0B84C</color>
    <color name="gold_bright">#FFD700</color>
    <color name="gold_translucent">#CCFFD700</color>
    <color name="black_deep">#0A0A0A</color>
</resources>
EOF

cat > GoldenCamera/app/src/main/res/values/strings.xml << 'EOF'
<resources>
    <string name="app_name">Golden Camera</string>
    <string name="ar_measure_hint">Tap two points to measure</string>
    <string name="switch_language">Target: AR ⇄ EN</string>
    <string name="btn_measure">AR Measure</string>
    <string name="btn_ocr">Translate</string>
    <string name="btn_capture">Capture</string>
    <string name="enable_nfc">Please enable NFC</string>
    <string name="nfc_hint">Hold an NFC card near the back of your phone</string>
    <string name="save_card">Save to Database</string>
    <string name="btn_nfc">NFC Reader</string>
    <string name="btn_elevator">Elevator Sim</string>
</resources>
EOF

cat > GoldenCamera/app/src/main/res/values-ar/strings.xml << 'EOF'
<resources>
    <string name="app_name">الكاميرا الذهبية</string>
    <string name="ar_measure_hint">انقر على نقطتين للقياس</string>
    <string name="switch_language">الهدف: عربي ⇄ إنجليزي</string>
    <string name="btn_measure">قياس AR</string>
    <string name="btn_ocr">ترجمة النصوص</string>
    <string name="btn_capture">التقاط</string>
    <string name="enable_nfc">يرجى تفعيل NFC</string>
    <string name="nfc_hint">قرّب بطاقة NFC من ظهر الهاتف</string>
    <string name="save_card">حفظ في قاعدة البيانات</string>
    <string name="btn_nfc">قارئ NFC</string>
    <string name="btn_elevator">محاكي المصعد</string>
</resources>
EOF

cat > GoldenCamera/app/src/main/res/values/themes.xml << 'EOF'
<resources>
    <style name="Theme.GoldenCamera" parent="Theme.MaterialComponents.NoActionBar">
        <item name="colorPrimary">@color/gold</item>
        <item name="colorSecondary">@color/gold_bright</item>
        <item name="android:statusBarColor">@color/black_deep</item>
        <item name="android:navigationBarColor">@color/black_deep</item>
    </style>
</resources>
EOF

# 13. الأيقونة
cat > GoldenCamera/app/src/main/res/drawable/ic_launcher_background.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">
    <path android:fillColor="#0A0A0A" android:pathData="M0,0 h108 v108 h-108 z" />
</vector>
EOF

cat > GoldenCamera/app/src/main/res/drawable/ic_launcher_foreground.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">
    <path android:strokeColor="#FFD700" android:strokeWidth="2" android:fillColor="#00000000" android:pathData="M30,30 A20,20 0 0,1 30,50" />
    <path android:strokeColor="#FFD700" android:strokeWidth="2" android:fillColor="#00000000" android:pathData="M24,24 A28,28 0 0,1 24,56" />
    <path android:fillColor="#E0B84C" android:pathData="M54,30 h30 v48 h-30 z" />
    <path android:fillColor="#0A0A0A" android:pathData="M61,38 h6 v40 h-6 z" />
    <path android:fillColor="#0A0A0A" android:pathData="M71,38 h6 v40 h-6 z" />
    <path android:fillColor="#FFD700" android:pathData="M54,20 m-8,0 a8,8 0 1,0 16,0 a8,8 0 1,0 -16,0" />
    <path android:fillColor="#0A0A0A" android:pathData="M54,20 m-4,0 a4,4 0 1,0 8,0 a4,4 0 1,0 -8,0" />
</vector>
EOF

cat > GoldenCamera/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>
EOF

cp GoldenCamera/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml GoldenCamera/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml

# 14. الضغط إلى ملف ZIP
cd GoldenCamera
zip -r ../GoldenCamera.zip . -x "*.DS_Store"
cd ..
echo "✅ تم إنشاء المشروع بالكامل!"
echo "📦 ملف الـ ZIP جاهز للرفع على GitHub: GoldenCamera.zip"