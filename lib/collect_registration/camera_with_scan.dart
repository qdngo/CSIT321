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