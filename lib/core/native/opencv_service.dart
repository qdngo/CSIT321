// TODO Implement this library.
import 'package:flutter/services.dart';

class OpenCVService {
  static const MethodChannel _channel = MethodChannel('opencv');

  static Future<String> processImage(String filePath) async {
    try {
      final String result = await _channel.invokeMethod('processImage', {'filePath': filePath});
      return result;
    } catch (e) {
      print("Error during OpenCV processing: $e");
      throw Exception("Failed to process image with OpenCV");
    }
  }
}