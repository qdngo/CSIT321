import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
  @override
  void initState() {
    initData();
    super.initState();
  }

  initData() async {
    await Future.delayed(Duration(seconds: 4));
    try {
      // Chụp ảnh
      await widget.initializeControllerFuture;
      final file = await widget.controller.takePicture();
      Navigator.pop(context, file);
    } catch (e) {
      if (kDebugMode) {
        print('Error capturing image: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: widget.initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                CameraPreview(widget.controller),

                // Tạo lớp nền tối với độ mờ xung quanh khuôn
                Positioned.fill(
                  child: Container(
                    color: Colors.transparent, // Nền tối xung quanh khuôn
                  ),
                ),

                // Tạo khuôn cắt với viền đỏ và phần giữa trong suốt
                Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: (MediaQuery.of(context).size.width * 0.8 * 0.63),
                    decoration: BoxDecoration(
                      border:
                      Border.all(color: Colors.red, width: 3), // Viền đỏ
                      color: Colors.transparent, // Phần giữa trong suốt
                    ),
                  ),
                ),

                Positioned(
                  top: 15,
                  left: 10,
                  child: IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

// import 'dart:async';
// import 'dart:typed_data';
// import 'package:camera/camera.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:google_ml_kit/google_ml_kit.dart';
//
// class CameraWithScan extends StatefulWidget {
//   const CameraWithScan({
//     super.key,
//     required this.controller,
//     required this.initializeControllerFuture,
//   });
//
//   final CameraController controller;
//   final Future<void> initializeControllerFuture;
//
//   @override
//   State<CameraWithScan> createState() => _CameraWithScanState();
// }
//
// class _CameraWithScanState extends State<CameraWithScan> {
//   bool _isDetecting = false;
//   bool _hasCaptured = false;
//   final TextRecognizer _textRecognizer = GoogleMlKit.vision.textRecognizer();
//
//   @override
//   void initState() {
//     super.initState();
//     _startCameraStream();
//   }
//
//   Future<void> _startCameraStream() async {
//     // Make sure the camera is initialized
//     await widget.initializeControllerFuture;
//
//     // Start streaming frames
//     widget.controller.startImageStream((CameraImage image) async {
//       // If we're already processing or we already captured, skip
//       if (_isDetecting || _hasCaptured) return;
//       _isDetecting = true;
//
//       try {
//         final inputImage = _convertCameraImage(image);
//         final recognizedText = await _textRecognizer.processImage(inputImage);
//
//         // If text likely indicates an ID, capture and return
//         if (_detectID(recognizedText.text)) {
//           _hasCaptured = true;
//           final file = await widget.controller.takePicture();
//           await widget.controller.stopImageStream();
//
//           if (mounted) {
//             Navigator.pop(context, file);
//           }
//         }
//       } catch (e) {
//         if (kDebugMode) {
//           print('Error during ID detection: $e');
//         }
//       } finally {
//         _isDetecting = false;
//       }
//     });
//   }
//
//   /// Simple check if the recognized text suggests we found an ID.
//   bool _detectID(String text) {
//     final pattern = RegExp(r'(passport|license|national\s?id)', caseSensitive: false);
//     return pattern.hasMatch(text);
//   }
//
//   /// Convert [CameraImage] -> ML Kit [InputImage].
//   InputImage _convertCameraImage(CameraImage cameraImage) {
//     // Combine all planes into a single Uint8List
//     final WriteBuffer allBytes = WriteBuffer();
//     for (final Plane plane in cameraImage.planes) {
//       allBytes.putUint8List(plane.bytes);
//     }
//     final bytes = allBytes.done().buffer.asUint8List();
//
//     // Prepare metadata for ML Kit
//     final Size imageSize = Size(
//       cameraImage.width.toDouble(),
//       cameraImage.height.toDouble(),
//     );
//
//     // Convert the camera's sensor rotation to ML Kit's rotation format
//     final rotation = _rotationIntToImageRotation(
//       widget.controller.description.sensorOrientation,
//     );
//
//     // Convert raw image format to an ML Kit enum
//     final format = _rawFormatToInputImageFormat(cameraImage.format.raw);
//
//     // Plane data (bytesPerRow, etc.)
//     final planeData = cameraImage.planes.map(
//           (Plane plane) {
//         return InputImagePlaneMetadata(
//           bytesPerRow: plane.bytesPerRow,
//           width: cameraImage.width,
//           height: cameraImage.height,
//         );
//       },
//     ).toList();
//
//     // Create the input image with metadata
//     return InputImage.fromBytes(
//       bytes: bytes,
//       inputImageData: InputImageData(
//         size: imageSize,
//         imageRotation: rotation,
//         inputImageFormat: format,
//         planeData: planeData,
//       ),
//     );
//   }
//
//   /// Convert integer rotation degrees to [InputImageRotation].
//   InputImageRotation _rotationIntToImageRotation(int rotation) {
//     switch (rotation) {
//       case 90:
//         return InputImageRotation.rotation90deg;
//       case 180:
//         return InputImageRotation.rotation180deg;
//       case 270:
//         return InputImageRotation.rotation270deg;
//       case 0:
//       default:
//         return InputImageRotation.rotation0deg;
//     }
//   }
//
//   /// Convert raw camera format to an ML Kit [InputImageFormat].
//   InputImageFormat _rawFormatToInputImageFormat(int raw) {
//     // Common values: 17 == NV21, 842094169 == YUV_420_888
//     switch (raw) {
//       case 17:
//         return InputImageFormat.nv21;
//       case 842094169:
//         return InputImageFormat.yuv420;
//       default:
//       // Fallback if unknown
//         return InputImageFormat.yuv420;
//     }
//   }
//
//   @override
//   void dispose() {
//     // Close the text recognizer
//     _textRecognizer.close();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: FutureBuilder<void>(
//         future: widget.initializeControllerFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.done) {
//             return Stack(
//               children: [
//                 // Camera preview
//                 CameraPreview(widget.controller),
//                 // Optional: A red frame or overlay for alignment
//                 Center(
//                   child: Container(
//                     width: MediaQuery.of(context).size.width * 0.8,
//                     height: (MediaQuery.of(context).size.width * 0.8 * 0.63),
//                     decoration: BoxDecoration(
//                       border: Border.all(color: Colors.red, width: 3),
//                       color: Colors.transparent,
//                     ),
//                   ),
//                 ),
//                 // Back button
//                 Positioned(
//                   top: 15,
//                   left: 10,
//                   child: IconButton(
//                     onPressed: () {
//                       Navigator.pop(context);
//                     },
//                     icon: const Icon(Icons.arrow_back, color: Colors.white),
//                   ),
//                 ),
//               ],
//             );
//           } else {
//             return const Center(child: CircularProgressIndicator());
//           }
//         },
//       ),
//     );
//   }
// }