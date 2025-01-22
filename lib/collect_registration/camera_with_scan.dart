import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(MaterialApp(
    home: CameraWithScan(
      controller: CameraController(firstCamera, ResolutionPreset.high),
      initializeControllerFuture: CameraController(firstCamera, ResolutionPreset.high).initialize(),
    ),
  ));
}

class CameraWithScan extends StatefulWidget {
  const CameraWithScan({
    super.key,
    required this.controller,
    required this.initializeControllerFuture,
  });

  final CameraController controller;
  final Future<void> initializeControllerFuture;

  @override
  State<CameraWithScan> createState() => _CameraWithScanState();
}

class _CameraWithScanState extends State<CameraWithScan> {
  bool _isDetecting = false;
  final TextRecognizer _textRecognizer = GoogleMlKit.vision.textRecognizer();

  @override
  void initState() {
    super.initState();
    _startIDDetection();
  }

  Future<void> _startIDDetection() async {
    await widget.initializeControllerFuture;
    widget.controller.startImageStream((CameraImage image) async {
      if (_isDetecting) return;
      _isDetecting = true;
      try {
        final inputImage = _convertCameraImage(image);
        final recognizedText = await _textRecognizer.processImage(inputImage);

        if (_isValidID(recognizedText.text)) {
          final file = await widget.controller.takePicture();
          await widget.controller.stopImageStream();
          if (mounted) {
            Navigator.pop(context, {'file': file, 'data': recognizedText.text});
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error detecting ID: $e');
        }
      } finally {
        _isDetecting = false;
      }
    });
  }

  bool _isValidID(String text) {
    final pattern = RegExp(r'(passport|license|national\s?id)', caseSensitive: false);
    return pattern.hasMatch(text);
  }

  InputImage _convertCameraImage(CameraImage cameraImage) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in cameraImage.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final imageSize = Size(
      cameraImage.width.toDouble(),
      cameraImage.height.toDouble(),
    );

    final rotation = InputImageRotation.rotation0deg;
    final format = InputImageFormat.yuv420;

    final planeData = cameraImage.planes.map(
          (Plane plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          width: cameraImage.width,
          height: cameraImage.height,
        );
      },
    ).toList();

    return InputImage.fromBytes(
      bytes: bytes,
      inputImageData: InputImageData(
        size: imageSize,
        imageRotation: rotation,
        inputImageFormat: format,
        planeData: planeData,
      ),
    );
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CameraPreview(widget.controller),
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.width * 0.8 * 0.63,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red, width: 3),
                color: Colors.transparent,
              ),
            ),
          ),
          Positioned(
            top: 15,
            left: 10,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
