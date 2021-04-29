package com.example.flutter_file_downloader

import android.app.Activity
import android.app.DownloadManager
import android.content.Context
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Environment
import android.util.Log
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

object PluginMethods {
  const val downloadFile = "download_file"
}

data class DownloadParameters(val uri: Uri, var headers: Map<String, String>?)

class FlutterFileDownloaderPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.RequestPermissionsResultListener {

  private lateinit var channel : MethodChannel
  private lateinit var context: Context
  private lateinit var activityPluginBinding: ActivityPluginBinding
  private lateinit var downloadManager: DownloadManager
  private val requestPermissionCode = 23
  private lateinit var result: Result
  private lateinit var lastDownloadParameters: DownloadParameters

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_file_downloader")
    context = flutterPluginBinding.applicationContext
    downloadManager = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    this.result = result
    if (call.method == PluginMethods.downloadFile) {
      val urlString = call.argument<String>("url")
      if (urlString == null){
        result.error("flutter_downloader_error.invalid_input", "Invalid input", null)
        return
      }
      val url = Uri.parse(urlString)
      if (url == null){
        result.error("flutter_downloader_error.invalid_url", "Invalid url", null)
        return
      }
      lastDownloadParameters = DownloadParameters(url, call.argument<Map<String, String>>("headers"))
      checkPermissionsAndDownloadFile()
    } else {
      result.notImplemented()
    }
  }

  private fun checkPermissionsAndDownloadFile(){
    val permission =  ContextCompat.checkSelfPermission(context, android.Manifest.permission.WRITE_EXTERNAL_STORAGE)
    val granted = permission == PackageManager.PERMISSION_GRANTED
    if (granted) {
      downloadWithPermission(lastDownloadParameters, granted)
    } else {
      ActivityCompat.requestPermissions(activityPluginBinding.activity, arrayOf(android.Manifest.permission.WRITE_EXTERNAL_STORAGE), requestPermissionCode)
    }
  }

  private fun downloadWithPermission(downloadParameters: DownloadParameters, permissionGranted: Boolean) {
    val request = DownloadManager.Request(downloadParameters.uri)
    request.setTitle(downloadParameters.uri.lastPathSegment)
    request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
    downloadParameters.headers?.forEach { entry ->
      request.addRequestHeader(entry.key, entry.value)
      }
    if (permissionGranted) {
      request.setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, downloadParameters.uri.lastPathSegment)
    }
    downloadManager.enqueue(request)
    Log.d("DOWNLOAD MANAGER", "Enqueued Request $request")
    result.success("ok")
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>?, grantResults: IntArray?): Boolean {
    if (requestCode != requestPermissionCode){
      return false
    }
    if (grantResults != null && permissions?.first() == android.Manifest.permission.WRITE_EXTERNAL_STORAGE) {
      downloadWithPermission(lastDownloadParameters, grantResults[0] == PackageManager.PERMISSION_GRANTED)
      return true
    }
    return false
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    this.activityPluginBinding = binding
    binding.addRequestPermissionsResultListener(this)
  }

  override fun onDetachedFromActivityForConfigChanges() {

  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    this.activityPluginBinding.removeRequestPermissionsResultListener(this)
    this.activityPluginBinding = binding
    binding.addRequestPermissionsResultListener(this)
  }

  override fun onDetachedFromActivity() {
    activityPluginBinding.removeRequestPermissionsResultListener(this)
  }
}
