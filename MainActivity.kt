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
        try {
            ExtensionsManager.getInstanceAsync(this, ContextCompat.getMainExecutor(this)) { manager ->
                if (manager.isExtensionAvailable(CameraSelector.DEFAULT_BACK_CAMERA, ExtensionMode.NIGHT)) {
                    nightSelector = manager.getExtensionEnabledCameraSelector(CameraSelector.DEFAULT_BACK_CAMERA, ExtensionMode.NIGHT)
                } else { binding.btnNight.isEnabled = false; binding.btnNight.text = "Night: N/A" }
            }
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
