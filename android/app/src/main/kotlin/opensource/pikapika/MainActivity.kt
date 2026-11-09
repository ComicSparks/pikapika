package opensource.pikapika

import android.net.Uri
import android.os.Build
import android.provider.OpenableColumns
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.view.KeyEvent
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.nio.file.Files
import java.util.UUID

class MainActivity : FlutterFragmentActivity() {
    private val uiThreadHandler = Handler(Looper.getMainLooper())
    private var volumeEvents: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "pikapika/platform")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "dataLocal" -> result.success(androidDataLocal())
                        "androidGetExtendDirs" -> result.success(androidGetExtendDirs())
                        "migrate" -> {
                            androidMigrate(call.argument<String>("path")!!)
                            result.success("")
                        }
                        "androidGetModes" -> result.success(modes())
                        "androidSetMode" -> {
                            setMode(call.argument<String>("mode") ?: "")
                            result.success("")
                        }
                        "androidGetVersion" -> result.success(Build.VERSION.SDK_INT)
                        "androidSecureFlag" -> {
                            androidSecureFlag(call.argument<Boolean>("flag") == true)
                            result.success("")
                        }
                        "androidStorageRoot" -> result.success(Environment.getExternalStorageDirectory().absolutePath)
                        "androidDefaultExportsDir" -> result.success(File(File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS), "pic2acg"), "exports").absolutePath)
                        "androidMkdirs" -> {
                            val path = call.arguments as? String ?: ""
                            File(path).mkdirs()
                            result.success("")
                        }
                        "contentUriToFile" -> {
                            val uriString = call.argument<String>("uri") ?: ""
                            Thread {
                                try {
                                    val path = copyContentUri(uriString)
                                    uiThreadHandler.post { result.success(path) }
                                } catch (e: Exception) {
                                    uiThreadHandler.post { result.error("platform", e.message, null) }
                                }
                            }.start()
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("platform", e.message, null)
                }
            }
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "volume_button")
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    volumeEvents = events
                }

                override fun onCancel(arguments: Any?) {
                    volumeEvents = null
                }
            })
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        volumeEvents?.let {
            if (keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
                uiThreadHandler.post { it.success("DOWN") }
                return true
            }
            if (keyCode == KeyEvent.KEYCODE_VOLUME_UP) {
                uiThreadHandler.post { it.success("UP") }
                return true
            }
        }
        return super.onKeyDown(keyCode, event)
    }

    private fun modes(): List<String> {
        val display = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) display else null
        return display?.supportedModes?.map { it.toString() } ?: emptyList()
    }

    private fun setMode(string: String) {
        val display = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) display else null
        if (string.isEmpty()) {
            uiThreadHandler.post {
                window.attributes = window.attributes.also { it.preferredDisplayModeId = 0 }
            }
            return
        }
        display?.supportedModes?.firstOrNull { it.toString() == string }?.let { mode ->
            uiThreadHandler.post {
                window.attributes = window.attributes.also { it.preferredDisplayModeId = mode.modeId }
            }
        }
    }

    private fun androidSecureFlag(flag: Boolean) {
        uiThreadHandler.post {
            if (flag) {
                window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
            } else {
                window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
            }
        }
    }

    private fun androidDataLocal(): String {
        val localFile = File(filesDir.absolutePath, "data.local")
        if (localFile.exists()) {
            val path = String(FileInputStream(localFile).use { it.readBytes() })
            if (File(path).isDirectory) {
                return path
            }
        }
        return filesDir.absolutePath
    }

    private fun androidGetExtendDirs(): String {
        val result = getExternalFilesDirs("")?.toMutableList()?.also {
            it.add(filesDir)
        }?.joinToString("|") { it.absolutePath }
        if (result != null) {
            return result
        }
        throw Exception("System version too low")
    }

    private fun androidMigrate(path: String) {
        val current = androidDataLocal()
        if (current == path) {
            return
        }
        File(current, "data.local").delete()
        val target = File(path)
        if (!target.exists()) {
            target.mkdirs()
        }
        target.listFiles()?.forEach { deleteRec(it) }
        File(current).listFiles()?.forEach { moveRec(it, File(target, it.name)) }
        val localFile = File(filesDir.absolutePath, "data.local")
        if (path == filesDir.absolutePath) {
            localFile.delete()
        } else {
            FileOutputStream(localFile).use { it.write(path.toByteArray()) }
        }
    }

    private fun copyContentUri(uriString: String): String {
        val uri = Uri.parse(uriString)
        var name = ""
        contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
                val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (index >= 0) {
                    name = cursor.getString(index) ?: ""
                }
            }
        }
        if (name.isEmpty()) {
            name = uri.lastPathSegment ?: "file"
        }
        val dir = File(cacheDir, "uri_to_file/${UUID.randomUUID()}")
        if (!dir.mkdirs() && !dir.isDirectory) {
            throw java.io.IOException("无法创建缓存目录")
        }
        val output = File(dir, name)
        contentResolver.openInputStream(uri)?.use { input ->
            FileOutputStream(output).use { input.copyTo(it) }
        } ?: throw java.io.IOException("无法打开 $uriString")
        return output.absolutePath
    }

    private fun deleteRec(f: File) {
        if (f.isDirectory) {
            f.listFiles()?.forEach { deleteRec(it) }
        }
        f.delete()
    }

    private fun moveRec(f: File, t: File) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && f.isDirectory) {
            Files.createDirectories(t.toPath())
            f.listFiles()?.forEach { moveRec(it, File(t, it.name)) }
            Files.delete(f.toPath())
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Files.move(f.toPath(), t.toPath())
        } else if (f.isDirectory) {
            t.mkdirs()
            f.listFiles()?.forEach { moveRec(it, File(t, it.name)) }
            f.delete()
        } else {
            f.copyTo(t, overwrite = true)
            f.delete()
        }
    }
}
