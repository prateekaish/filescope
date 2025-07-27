package org.filescope.dev


import android.os.Environment
import android.os.StatFs
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.filescope/storage"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "getTotalDiskSpace") {
                result.success(getTotalDiskSpace())
            } else if (call.method == "getFreeDiskSpace") {
                result.success(getFreeDiskSpace())
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getTotalDiskSpace(): Double {
        return try {
            val stat = StatFs(Environment.getExternalStorageDirectory().path)
            val bytesAvailable = stat.blockSizeLong * stat.blockCountLong
            bytesAvailable.toDouble()
        } catch (e: Exception) {
            0.0
        }
    }

    private fun getFreeDiskSpace(): Double {
        return try {
            val stat = StatFs(Environment.getExternalStorageDirectory().path)
            val bytesAvailable = stat.blockSizeLong * stat.availableBlocksLong
            bytesAvailable.toDouble()
        } catch (e: Exception) {
            0.0
        }
    }
}