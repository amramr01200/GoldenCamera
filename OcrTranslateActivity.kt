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
