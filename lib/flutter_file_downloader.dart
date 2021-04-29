import 'dart:async';
import 'package:flutter/services.dart';

abstract class Constants {
  static const String methodChannel = 'flutter_file_downloader';
  static const String downloadFileMethod = 'download_file';
}

class FlutterFileDownloader {
  static const MethodChannel _channel = const MethodChannel(Constants.methodChannel);

  static Future<void> downloadFile(String url, {Map<String, String> headers}) async {
    await _channel.invokeMethod(Constants.downloadFileMethod, {"url": url, "headers": headers});
  }
}
