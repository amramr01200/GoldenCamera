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

    override fun onResume() { super.onResume(); sceneView.resume() }
    override fun onPause() { super.onPause(); sceneView.pause() }
    override fun onDestroy() { super.onDestroy(); anchors.forEach { it.detach() }; anchors.clear(); sceneView.destroy() }
}
