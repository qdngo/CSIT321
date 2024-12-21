package com.example.sample_assist


import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity


import org.opencv.android.OpenCVLoader
import org.opencv.core.*
import org.opencv.imgproc.Imgproc
import org.opencv.imgcodecs.Imgcodecs
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "opencv"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "processImage") {
                val filePath = call.argument<String>("filePath")
                if (filePath != null) {
                    val processedPath = processImageWithOpenCV(filePath)
                    result.success(processedPath)
                } else {
                    result.error("INVALID_ARGUMENT", "File path is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun processImageWithOpenCV(filePath: String): String {
        val src = Imgcodecs.imread(filePath)

        // Convert to grayscale
        val gray = Mat()
        Imgproc.cvtColor(src, gray, Imgproc.COLOR_BGR2GRAY)

        // Detect edges
        val edges = Mat()
        Imgproc.Canny(gray, edges, 50.0, 150.0)

        // Find contours
        val contours = mutableListOf<MatOfPoint>()
        Imgproc.findContours(edges, contours, Mat(), Imgproc.RETR_EXTERNAL, Imgproc.CHAIN_APPROX_SIMPLE)

        // Find the largest rectangle
        val rect = contours.maxByOrNull { Imgproc.contourArea(it) }?.let { Imgproc.boundingRect(it) }

        // Crop the image
        val cropped = Mat(src, rect)

        // Save the cropped image
        val croppedFile = File(getExternalFilesDir(null), "cropped_image.jpg")
        Imgcodecs.imwrite(croppedFile.absolutePath, cropped)

        return croppedFile.absolutePath
    }
}

