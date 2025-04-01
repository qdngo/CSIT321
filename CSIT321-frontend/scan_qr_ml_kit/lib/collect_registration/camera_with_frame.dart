import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:scan_ml_text_kit/main.dart';

class CameraWithFrame extends StatefulWidget {
  const CameraWithFrame({
    super.key,
    required this.controller,
    required this.initializeControllerFuture,
  });

  final CameraController controller;
  final Future<void> initializeControllerFuture;

  @override
  State<CameraWithFrame> createState() => _CameraWithFrameState();
}

class _CameraWithFrameState extends State<CameraWithFrame> {
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
                // Button take picture
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: FloatingActionButton(
                      onPressed: () async {
                        try {
                          await widget.initializeControllerFuture;
                          final file = await widget.controller.takePicture();

                          // // Cắt ảnh và trả về XFile
                          // final croppedXFile = await _cropImage(file.path);

                          // Trả về XFile đã cắt
                          // ignore: use_build_context_synchronously
                          Navigator.pop(context, file);
                        } catch (e) {
                          logger.e('Error capturing image: $e');
                        }
                      },
                      child: const Icon(Icons.camera_alt),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
