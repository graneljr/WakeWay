package com.example.wakeway

import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.provider.OpenableColumns
import android.webkit.MimeTypeMap
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    companion object {
        private const val REQUEST_DEVICE_MUSIC = 7410
        private const val REQUEST_SYSTEM_RINGTONE = 7411
    }

    private var pendingAudioResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.example.wakeway/audio_picker",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickDeviceMusic" -> launchAudioPicker(result)
                "pickSystemRingtone" -> launchRingtonePicker(result)
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.example.wakeway/app_updates",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAppVersion" -> result.success(installedAppVersion())
                "canInstallPackages" -> result.success(canInstallPackages())
                "openInstallPermissionSettings" -> openInstallPermissionSettings(result)
                "installApk" -> installApk(call.argument<String>("path"), result)
                else -> result.notImplemented()
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun installedAppVersion(): String =
        packageManager.getPackageInfo(packageName, 0).versionName ?: "0.0.0"

    private fun canInstallPackages(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.O ||
            packageManager.canRequestPackageInstalls()

    private fun openInstallPermissionSettings(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            result.success(null)
            return
        }
        try {
            val intent = Intent(
                Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                Uri.parse("package:$packageName"),
            )
            startActivity(intent)
            result.success(null)
        } catch (error: Exception) {
            result.error("settings_failed", error.localizedMessage, null)
        }
    }

    private fun installApk(path: String?, result: MethodChannel.Result) {
        if (path == null) {
            result.error("apk_missing", "The downloaded APK path is missing.", null)
            return
        }

        try {
            val apkFile = File(path)
            if (!apkFile.isFile) {
                throw IllegalArgumentException("The downloaded APK could not be found.")
            }
            val apkUri = FileProvider.getUriForFile(
                this,
                "$packageName.fileprovider",
                apkFile,
            )
            val intent = Intent(Intent.ACTION_INSTALL_PACKAGE).apply {
                setDataAndType(apkUri, "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            result.success(null)
        } catch (error: Exception) {
            result.error("installer_failed", error.localizedMessage, null)
        }
    }

    private fun launchAudioPicker(result: MethodChannel.Result) {
        if (pendingAudioResult != null) {
            result.error("picker_busy", "An audio picker is already open.", null)
            return
        }
        pendingAudioResult = result
        try {
            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = "audio/*"
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            startActivityForResult(intent, REQUEST_DEVICE_MUSIC)
        } catch (error: Exception) {
            pendingAudioResult = null
            result.error("picker_failed", error.localizedMessage, null)
        }
    }

    private fun launchRingtonePicker(result: MethodChannel.Result) {
        if (pendingAudioResult != null) {
            result.error("picker_busy", "An audio picker is already open.", null)
            return
        }
        pendingAudioResult = result
        val intent = Intent(RingtoneManager.ACTION_RINGTONE_PICKER).apply {
            putExtra(RingtoneManager.EXTRA_RINGTONE_TYPE, RingtoneManager.TYPE_RINGTONE)
            putExtra(RingtoneManager.EXTRA_RINGTONE_TITLE, "Choose WakeWay alarm sound")
            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, false)
            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
        }
        try {
            startActivityForResult(intent, REQUEST_SYSTEM_RINGTONE)
        } catch (error: Exception) {
            pendingAudioResult = null
            result.error("picker_failed", error.localizedMessage, null)
        }
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        when (requestCode) {
            REQUEST_DEVICE_MUSIC -> {
                val uri = if (resultCode == RESULT_OK) data?.data else null
                copySelectedAudio(uri)
            }
            REQUEST_SYSTEM_RINGTONE -> handleRingtoneResult(resultCode, data)
        }
    }

    private fun handleRingtoneResult(resultCode: Int, data: Intent?) {
        if (resultCode != RESULT_OK) {
            completeAudioSelection(null)
            return
        }
        @Suppress("DEPRECATION")
        val selectedUri = data?.getParcelableExtra<Uri>(
            RingtoneManager.EXTRA_RINGTONE_PICKED_URI,
        )
        val uri = selectedUri
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
        val title = RingtoneManager.getRingtone(this, uri)?.getTitle(this)
        copySelectedAudio(uri, title)
    }

    private fun copySelectedAudio(uri: Uri?, fallbackName: String? = null) {
        if (uri == null) {
            completeAudioSelection(null)
            return
        }
        val result = pendingAudioResult ?: return
        try {
            val mimeType = contentResolver.getType(uri)
            if (mimeType != null && !mimeType.startsWith("audio/")) {
                throw IllegalArgumentException("Choose an audio file or ringtone.")
            }
            val sourceName = contentResolver.query(
                uri,
                arrayOf(OpenableColumns.DISPLAY_NAME),
                null,
                null,
                null,
            )?.use { cursor ->
                if (cursor.moveToFirst()) cursor.getString(0) else null
            } ?: fallbackName ?: uri.lastPathSegment ?: "Alarm audio"
            val extension = sourceName.substringAfterLast('.', "")
                .lowercase()
                .filter { it.isLetterOrDigit() }
                .take(8)
                .ifBlank {
                    MimeTypeMap.getSingleton().getExtensionFromMimeType(mimeType) ?: "audio"
                }
            val displayName = (fallbackName ?: sourceName)
                .substringBeforeLast('.', fallbackName ?: sourceName)
                .ifBlank { "Alarm audio" }
            val audioDirectory = File(filesDir, "alarm_audio").apply { mkdirs() }
            val audioFile = File(
                audioDirectory,
                "wakeway_${System.currentTimeMillis()}.$extension",
            )
            val input = contentResolver.openInputStream(uri)
                ?: throw IllegalStateException("Could not read the selected audio.")
            input.use { source ->
                audioFile.outputStream().use { output -> source.copyTo(output) }
            }
            result.success(
                mapOf("path" to audioFile.absolutePath, "name" to displayName),
            )
            pendingAudioResult = null
        } catch (error: Exception) {
            completeAudioError(error)
        }
    }

    private fun completeAudioSelection(selection: Any?) {
        val result = pendingAudioResult ?: return
        pendingAudioResult = null
        result.success(selection)
    }

    private fun completeAudioError(error: Exception) {
        val result = pendingAudioResult ?: return
        pendingAudioResult = null
        result.error("audio_copy_failed", error.localizedMessage, null)
    }
}
