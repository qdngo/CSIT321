import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'camera_with_scan.dart';

class CollectRegistration extends StatefulWidget {
  final CameraDescription camera;
  const CollectRegistration({super.key, required this.camera});

  @override
  State<CollectRegistration> createState() => _CollectRegistrationScreenState();
}

class _CollectRegistrationScreenState extends State<CollectRegistration> {
  final _formKey = GlobalKey<FormState>();
  File? _uploadedPhoto;

  final idController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final dobController = TextEditingController();
  final expiryController = TextEditingController();

  Future<void> _scanImage() async {
    CameraController controller = CameraController(widget.camera, ResolutionPreset.high);
    Future<void> initializeControllerFuture = controller.initialize();

    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CameraWithScan(
            controller: controller,
            initializeControllerFuture: initializeControllerFuture,
          ),
        ),
      );

      if (result != null && result is Map<String, dynamic>) {
        _uploadedPhoto = File(result['file'].path);
        final extractedData = result['data'];
        idController.text = extractedData;

        setState(() {});
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error scanning ID: $e');
      }
    }
  }

  void _deletePhoto() {
    setState(() {
      _uploadedPhoto = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ID Registration')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _uploadedPhoto == null
                  ? ElevatedButton(
                onPressed: _scanImage,
                child: const Text('Scan ID'),
              )
                  : Image.file(_uploadedPhoto!),
              TextFormField(controller: idController, decoration: const InputDecoration(labelText: 'ID Number')),
              TextFormField(controller: firstNameController, decoration: const InputDecoration(labelText: 'First Name')),
              TextFormField(controller: lastNameController, decoration: const InputDecoration(labelText: 'Last Name')),
            ],
          ),
        ),
      ),
    );
  }
}
