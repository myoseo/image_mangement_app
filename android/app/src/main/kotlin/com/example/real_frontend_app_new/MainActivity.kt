package com.example.real_frontend_app

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import androidx.annotation.NonNull
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayInputStream
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.real_frontend_app/clipboard"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "copyImageToClipboard") {
                val imageBytes = call.argument<ByteArray>("imageBytes")
                if (imageBytes != null) {
                    try {
                        // 바이너리 데이터를 Bitmap으로 변환
                        val inputStream = ByteArrayInputStream(imageBytes)
                        val bitmap = BitmapFactory.decodeStream(inputStream)

                        // Bitmap을 URI로 변환하여 클립보드에 복사
                        val imageUri = getImageUri(bitmap)
                        if (imageUri != null) {
                            val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                            val clip = ClipData.newUri(contentResolver, "Image", imageUri)
                            clipboard.setPrimaryClip(clip)
                            result.success("이미지가 클립보드에 복사되었습니다.")
                        } else {
                            result.error("URI_ERROR", "이미지 URI를 생성하는 동안 오류가 발생했습니다.", null)
                        }
                    } catch (e: Exception) {
                        result.error("COPY_ERROR", "이미지를 클립보드로 복사하는 동안 오류가 발생했습니다: ${e.message}", null)
                    }
                } else {
                    result.error("INVALID_ARGUMENT", "잘못된 이미지 데이터입니다.", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    // Bitmap을 임시 파일로 저장하고 FileProvider를 통해 URI를 얻는 메소드
    private fun getImageUri(bitmap: Bitmap): Uri? {
        return try {
            // 앱의 캐시 디렉터리에 임시 파일을 생성하여 저장
            val file = File(cacheDir, "temp_image.png")
            val outputStream = FileOutputStream(file)
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
            outputStream.flush()
            outputStream.close()

            // FileProvider를 통해 파일의 URI 생성
            FileProvider.getUriForFile(this, "${applicationContext.packageName}.provider", file)
        } catch (e: IOException) {
            e.printStackTrace()
            null
        }
    }
}
