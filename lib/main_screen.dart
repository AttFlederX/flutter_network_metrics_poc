import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart';
import 'package:dart_ping/dart_ping.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const platform = MethodChannel('samples.flutter.dev/battery');

  String batteryLevel = '';
  String signalStrength = '';
  String pingResults = '';
  String selectedFileName = '';
  int selectedFileSize = 0;
  int uploadTime = 0;
  bool isUploading = false;
  double avgUploadSpeed = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: () async => await getBatteryLevel(),
            child: const Text('Get battery level'),
          ),
          Text(batteryLevel),
          ElevatedButton(
            onPressed: () async => await getSignalStrength(),
            child: const Text('Get signal strength'),
          ),
          Text(signalStrength),
          ElevatedButton(
            onPressed: () async => await onPingRequested(context),
            child: const Text('Ping server'),
          ),
          Text(pingResults),
          ElevatedButton(
            onPressed: () async =>
                await onFileUploadRequested(ScaffoldMessenger.of(context)),
            child: const Text('Upload file'),
          ),
          Center(
            child: isUploading
                ? const CircularProgressIndicator()
                : const SizedBox(height: 24),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Selected file name: "),
              Text(selectedFileName),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Selected file size: "),
              Text('$selectedFileSize B'),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Upload time: "),
              Text('$uploadTime ms'),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Avg. upload speed: "),
              Text('${avgUploadSpeed.toStringAsFixed(2)} Mbit/s'),
            ],
          ),
        ],
      ),
    );
  }

  Future onFileUploadRequested(ScaffoldMessengerState scaffold) async {
    final dialogResult = await FilePicker.platform.pickFiles();

    if (dialogResult != null) {
      final file = File(dialogResult.files.single.path!);

      setState(() {
        selectedFileName = dialogResult.files.single.name;
        selectedFileSize = dialogResult.files.single.size;
      });

      final mpReq =
          MultipartRequest('POST', Uri.parse('http://10.0.2.2:8080/upload'));
      mpReq.files.add(
        await MultipartFile.fromPath(
          'file',
          file.path,
          filename: selectedFileName,
          contentType: MediaType('multipart', 'form-data'),
        ),
      );

      final startDtm = DateTime.now();
      setState(() {
        isUploading = true;
      });

      final resp = await mpReq.send();

      if (resp.statusCode == HttpStatus.ok) {
        final endDtm = DateTime.now();

        setState(() {
          isUploading = false;

          uploadTime = endDtm.difference(startDtm).inMilliseconds;
          avgUploadSpeed = (((selectedFileSize / uploadTime) * 8) / 1024);
        });

        scaffold.showSnackBar(
          const SnackBar(content: Text('File uploaded')),
        );
      }
    }
  }

  onPingRequested(BuildContext context) {
    setState(() {
      pingResults = '';
    });

    final ping = Ping('10.0.2.2', count: 5);

    ping.stream.listen((event) {
      setState(() {
        pingResults += '$event\n';
      });
    });
  }

  Future getBatteryLevel() async {
    String res;

    try {
      final level = await platform.invokeMethod('getBatteryLevel');
      res = 'Battery level is $level%';
    } catch (e) {
      res = 'Failed to get battery level: $e';
    }

    setState(() {
      batteryLevel = res;
    });
  }

  Future getSignalStrength() async {
    String res;

    try {
      final level = await platform.invokeMethod('getSignalStrength');
      res = 'Signal strength is $level';
    } catch (e) {
      res = 'Failed to get Signal strength: $e';
    }

    setState(() {
      signalStrength = res;
    });
  }
}
