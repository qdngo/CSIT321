import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:path_provider/path_provider.dart';

class IDCardScannerPage extends StatefulWidget {
  const IDCardScannerPage({super.key});

  @override
  State<IDCardScannerPage> createState() => _IDCardScannerPageState();
}

class _IDCardScannerPageState extends State<IDCardScannerPage> {
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  bool _isDetecting = false;
  bool _idDetected = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  void _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.first;

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    _initializeControllerFuture = _cameraController.initialize();
    await _initializeControllerFuture;

    _cameraController.startImageStream((CameraImage image) {
      if (!_isDetecting) {
        _isDetecting = true;
        _detectIDCard(image);
      }
    });
  }

  Future<void> _detectIDCard(CameraImage image) async {
    try {
      // Convert the CameraImage to an InputImage for Google ML Kit
      final InputImage inputImage = _convertCameraImageToInputImage(image);

      // Initialize the ObjectDetector
      final objectDetector = GoogleMlKit.vision.objectDetector(
        ObjectDetectorOptions(
          classifyObjects: true,
        ),
      );

      final List<DetectedObject> objects = await objectDetector.processImage(inputImage);

      // Check if an ID-like object is detected
      for (var detectedObject in objects) {
        if (_isIDCardDetected(detectedObject)) {
          setState(() {
            _idDetected = true;
          });

          // Automatically take a picture and stop the stream
          await _captureImage();
          break;
        }
      }
      _isDetecting = false;
    } catch (e) {
      debugPrint('Error detecting ID card: $e');
      _isDetecting = false;
    }
  }

  bool _isIDCardDetected(DetectedObject detectedObject) {
    // Logic to determine if the object is an ID card (e.g., based on bounding box size/ratio)
    final boundingBox = detectedObject.boundingBox;
    final aspectRatio = boundingBox.width / boundingBox.height;

    // Assuming ID cards have a rectangular aspect ratio
    return aspectRatio > 1.4 && aspectRatio < 1.8;
  }

  Future<void> _captureImage() async {
    try {
      await _initializeControllerFuture;

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/id_card_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final XFile file = await _cameraController.takePicture();
      await file.saveTo(filePath);

      // Perform any post-processing or navigation
      debugPrint('Image saved to $filePath');
    } catch (e) {
      debugPrint('Error capturing image: $e');
    }
  }

  InputImage _convertCameraImageToInputImage(CameraImage image) {
    // Logic to convert CameraImage to InputImage
    // This requires platform-specific conversion based on CameraImage format.
    // Check the Google ML Kit documentation for proper conversion implementation.
    throw UnimplementedError('Conversion logic not implemented');
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ID Card Scanner"),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                CameraPreview(_cameraController),
                if (_idDetected)
                  const Center(
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 100,
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
