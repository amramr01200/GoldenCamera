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

    override fun onResume() { super.onResume(); sceneView.resume() }
    override fun onPause() { super.onPause(); sceneView.pause() }
    override fun onDestroy() { super.onDestroy(); sceneView.destroy() }
}
