import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:scan_ml_text_kit/extension/string_ext.dart';
import 'package:scan_ml_text_kit/main.dart';
import 'package:scan_ml_text_kit/model/scan_model.dart';
import 'package:scan_ml_text_kit/utils/consts.dart';
import 'package:collection/collection.dart';

class ScanCameraScreen extends StatefulWidget {
  const ScanCameraScreen({
    super.key,
    required this.type,
  });

  final String type;

  @override
  State<ScanCameraScreen> createState() => _ScanCameraScreenState();
}

class _ScanCameraScreenState extends State<ScanCameraScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool isBlocked = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (status.isDenied) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Need camera permission")));
      return;
    }

    _cameras = await availableCameras();
    if (_cameras.isNotEmpty) {
      _cameraController =
          CameraController(_cameras[0], ResolutionPreset.medium);
      await _cameraController!.initialize();
      setState(() {
        _isCameraInitialized = true;
      });

      _cameraController?.startImageStream((image) async {
        await _takePictureAndScan();
      });
    }
  }

  Future<void> _takePictureAndScan() async {
    await Future.delayed(const Duration(seconds: 4));
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      await _cameraController!.takePicture().then((XFile file) async {
        final File imageFile = File(file.path);
        await _scanText(imageFile);
      });
    } catch (e) {
      logger.e("Take picture error: $e");
    }
  }

  Future<void> _scanText(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);

    final rawText = recognizedText.text.toUpperCase();

    if ((rawText.contains('DRIVER LICENCE') ||
            rawText.contains('PASSPORT') ||
            rawText.contains('NATIONAL')) &&
        rawText.contains('LICENCE NO') &&
        rawText.contains('DATE OF BIRTH')) {
      final ScanModel model = ScanModel();
      final textSplit = rawText.split(RegExp(r'\r?\n'));

      model.filePath = imageFile.path;
      detachDataLocal(model, textSplit);
      Navigator.pop(context, model);
    }
  }

  Future<void> detachDataLocal(ScanModel model, List<String> textSplit) async {
    final iLicenceNo = textSplit.indexOf('LICENCE NO') + 1;
    final iDoB = textSplit.indexOf('DATE OF BIRTH') + 1;
    int count = 0;
    String address = '';
    String name = textSplit.firstWhere((e) {
      if (e.isName() &&
          !e.contains('LICENCE') &&
          !e.contains('DRIVING') &&
          !e.contains('AUSTRALIAN')) {
        return true;
      }
      return false;
    });
    for (var result in textSplit) {
      if (result.isAddress()) {
        count++;
        address += '$result ';
      }
      if (count >= 2) {
        break;
      }
    }

    model.firstName = name;
    model.address = address;
    final licenseNo = textSplit[iLicenceNo];
    final dob = textSplit[iDoB];

    if (dob.isDate()) {
      model.dateOfBirth = dob;
    } else {
      model.dateOfBirth = textSplit.firstWhereOrNull((e) => e.isDate());
    }

    if (int.tryParse(licenseNo) != null) {
      model.licenseNumber = licenseNo;
    } else {
      model.licenseNumber = textSplit.firstWhereOrNull((e) => e.isNumber());
    }
  }

  String get endPoint {
    switch (widget.type) {
      case "Driver's License":
        return pathProcessDriverLicense;
      case "Passport":
        return pathProcessPassport;
      case "National ID":
        return pathProcessPhotoCard;
    }
    return '';
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan ID"),
      ),
      body: Column(
        children: [
          _isCameraInitialized
              ? CameraPreview(_cameraController!)
              : Container(height: 200, color: Colors.black),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
