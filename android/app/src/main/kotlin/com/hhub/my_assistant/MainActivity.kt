package com.hhub.my_assistant

import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

// local_auth يتطلب FragmentActivity بدل FlutterActivity العادية.
class MainActivity : FlutterFragmentActivity() {
    private val adhanChannel = "com.hhub.my_assistant/adhan"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // بيحوّل ملف أذان مخصّص (اختاره المستخدم) لـ content:// URI يقدر نظام
        // الإشعارات يقراه، ويمنح صلاحية القراءة لواجهة النظام اللي بتشغّل الصوت.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, adhanChannel)
            .setMethodCallHandler { call, result ->
                if (call.method == "contentUri") {
                    try {
                        val path = call.argument<String>("path")!!
                        val authority = "$packageName.adhanprovider"
                        val uri = FileProvider.getUriForFile(this, authority, File(path))
                        grantUriPermission(
                            "com.android.systemui", uri,
                            Intent.FLAG_GRANT_READ_URI_PERMISSION
                        )
                        result.success(uri.toString())
                    } catch (e: Exception) {
                        result.error("ADHAN_URI", e.message, null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}
