import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
  // final int _captureButtonHeight = 80; // Chiều cao của nút chụp ảnh

  // // Hàm cắt ảnh tự động theo khuôn có tỷ lệ 0.63 và trả về XFile
  // Future<XFile> _cropImage(String filePath) async {
  //   final imageBytes = File(filePath).readAsBytesSync();
  //   final originalImage = img.decodeImage(imageBytes);

  //   if (originalImage == null) {
  //     throw Exception('Failed to decode image');
  //   }

  //   // Tính toán kích thước khuôn cắt với tỷ lệ 0.63
  //   final cropWidth = originalImage.width - 40;
  //   final cropHeight = (cropWidth * 0.63).toInt() - 20;

  //   // Cắt ảnh từ phần trên cùng, đảm bảo không bị dư phía trên hay dưới
  //   final cropX = 0; // Cắt từ vị trí đầu tiên của ảnh
  //   final cropY = (originalImage.height - cropHeight) ~/ 2 +
  //       _captureButtonHeight; // Căn chỉnh cắt từ giữa chiều cao ảnh

  //   // Cắt ảnh theo khuôn
  //   final croppedImage = img.copyCrop(
  //     originalImage,
  //     x: cropX + 20,
  //     y: cropY,
  //     width: cropWidth,
  //     height: cropHeight,
  //   );

  //   // Lưu ảnh đã cắt vào thư mục tạm
  //   final directory = await getTemporaryDirectory();
  //   final croppedFilePath = '${directory.path}/cropped_image.jpg';
  //   File(croppedFilePath).writeAsBytesSync(img.encodeJpg(croppedImage));

  //   return XFile(croppedFilePath);
  // }

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

                // Nút chụp ảnh
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: FloatingActionButton(
                      onPressed: () async {
                        try {
                          // Chụp ảnh
                          await widget.initializeControllerFuture;
                          final file = await widget.controller.takePicture();

                          // // Cắt ảnh và trả về XFile
                          // final croppedXFile = await _cropImage(file.path);

                          // Trả về XFile đã cắt
                          // ignore: use_build_context_synchronously
                          Navigator.pop(context, file);
                        } catch (e) {
                          if (kDebugMode) {
                            print('Error capturing image: $e');
                          }
                        }
                      },
                      child: Icon(Icons.camera_alt),
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