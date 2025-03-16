package com.example.collect_registration

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.opencv.android.OpenCVLoader
import org.opencv.core.*
import org.opencv.imgproc.Imgproc
import org.opencv.imgcodecs.Imgcodecs
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "opencv"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Initialize OpenCV
        if (!OpenCVLoader.initDebug()) {
            Log.e("OpenCV", "OpenCV initialization failed.")
        } else {
            Log.d("OpenCV", "OpenCV initialization succeeded.")
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "opencv")
            .setMethodCallHandler { call, result ->
                if (call.method == "processImage") {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        try {
                            val processedImagePath = processImageWithOpenCV(filePath)
                            result.success(processedImagePath)
                        } catch (e: Exception) {
                            result.error("PROCESSING_ERROR", "Failed to process image with OpenCV: ${e.message}", null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "File path is null or invalid", null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun processImageWithOpenCV(filePath: String): String {
        try {
            // Load the image from the provided file path
            val src = Imgcodecs.imread(filePath)
            if (src.empty()) throw Exception("Failed to load image from path: $filePath")

            Log.d("OpenCV", "Image loaded successfully: $filePath")

            // Convert to grayscale
            val gray = Mat()
            Imgproc.cvtColor(src, gray, Imgproc.COLOR_BGR2GRAY)

            // Detect edges using Canny
            val edges = Mat()
            Imgproc.Canny(gray, edges, 50.0, 150.0)

            // Find contours
            val contours = ArrayList<MatOfPoint>()
            Imgproc.findContours(edges, contours, Mat(), Imgproc.RETR_EXTERNAL, Imgproc.CHAIN_APPROX_SIMPLE)

            Log.d("OpenCV", "Found ${contours.size} contours")

            // Find the largest contour (assuming it's the ID document)
            val largestContour = contours.maxByOrNull { Imgproc.contourArea(it) }
                ?: throw Exception("No valid contours found")
            val rect = Imgproc.boundingRect(largestContour)

            // Crop the image to the bounding rectangle
            val cropped = Mat(src, rect)

            // Save the cropped image to a file
            val croppedFile = File(getExternalFilesDir(null), "cropped_image.jpg")
            Imgcodecs.imwrite(croppedFile.absolutePath, cropped)

            Log.d("OpenCV", "Cropped image saved at: ${croppedFile.absolutePath}")

            return croppedFile.absolutePath
        } catch (e: Exception) {
            Log.e("OpenCV", "Error processing image: ${e.message}")
            throw e
        }
    }
}