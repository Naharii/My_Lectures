package com.example.my_lectures

import android.net.Uri
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import java.io.File

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.my_lectures/ocr"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "recognizeArabicText") {
                val path = call.argument<String>("path")
                if (path != null) {
                    recognizeText(path, result)
                } else {
                    result.error("INVALID_PATH", "Image path is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun recognizeText(path: String, result: MethodChannel.Result) {
        val image: InputImage
        try {
            val file = File(path)
            if (!file.exists()) {
                result.error("FILE_NOT_FOUND", "File does not exist at $path", null)
                return
            }
            image = InputImage.fromFilePath(applicationContext, Uri.fromFile(file))
            
            val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)

            recognizer.process(image)
                .addOnSuccessListener { visionText ->
                    val blocksList = mutableListOf<Map<String, Any>>()
                    for (block in visionText.textBlocks) {
                        val linesList = mutableListOf<Map<String, Any>>()
                        for (line in block.lines) {
                            val elementsList = mutableListOf<Map<String, Any>>()
                            for (element in line.elements) {
                                val box = element.boundingBox
                                val elementMap = mutableMapOf<String, Any>(
                                    "text" to element.text,
                                    "left" to (box?.left?.toDouble() ?: 0.0),
                                    "top" to (box?.top?.toDouble() ?: 0.0),
                                    "right" to (box?.right?.toDouble() ?: 0.0),
                                    "bottom" to (box?.bottom?.toDouble() ?: 0.0)
                                )
                                elementsList.add(elementMap)
                            }
                            linesList.add(mapOf("elements" to elementsList))
                        }
                        blocksList.add(mapOf("lines" to linesList))
                    }
                    result.success(mapOf("blocks" to blocksList))
                }
                .addOnFailureListener { e ->
                    result.error("OCR_FAILED", e.message ?: "Unknown error", null)
                }
        } catch (e: Exception) {
            result.error("IMAGE_ERROR", e.message ?: "Unknown error", null)
        }
    }
}
