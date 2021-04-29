import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool loading = false;
  String error;

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> download() async {
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      setState(() {
        loading = true;
      });
      await FlutterFileDownloader.downloadFile(
          "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf");
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            children: [
              Spacer(),
              loading ? CircularProgressIndicator() : GestureDetector(onTap: () => download(), child: Text('Download')),
              Text(error == null ? "" : "Error $error"),
              Spacer()
            ],
          ),
        ),
      ),
    );
  }
}
