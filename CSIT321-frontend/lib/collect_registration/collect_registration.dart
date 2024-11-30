import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sample_assist/collect_registration/widgets/section_header.dart';

import 'widgets/step_indicator.dart';
import 'widgets/section_title.dart';
import 'widgets/photo_id_section.dart';
import 'widgets/dropdown_field.dart';
import 'widgets/text_field.dart';
import 'widgets/action_buttons.dart';

class CollectRegistration extends StatefulWidget {
  const CollectRegistration({super.key});

  @override
  State<CollectRegistration> createState() => _CollectRegistrationScreenState();
}

class _CollectRegistrationScreenState extends State<CollectRegistration> {
  final _formKey = GlobalKey<FormState>();
  String? selectedPhotoIDType;
  final ImagePicker _imagePicker = ImagePicker();
  File? _uploadedPhoto;

  void _getPhotoFromGallery() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _uploadedPhoto = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('Error selecting photo: $e');
    }
  }

  void _takePhoto() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          _uploadedPhoto = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('Error capturing photo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Collector Registration',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF01B4D2),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const StepIndicator(),
            const SizedBox(height: 16),
            const SectionTitle(title: '1. Collector Identity'),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'PHOTO ID'),
                    const SizedBox(height: 16),
                    PhotoIdSection(
                      uploadedPhoto: _uploadedPhoto,
                      getPhotoFromGallery: _getPhotoFromGallery,
                      takePhoto: _takePhoto,
                    ),
                    const SizedBox(height: 8),
                    DropdownField(
                      hint: 'Please select a type of Photo ID',
                      items: ['Passport', 'Driver\'s License', 'National ID'],
                      onChanged: (value) {
                        setState(() {
                          selectedPhotoIDType = value;
                        });
                      },
                    ),
                    const CustomTextField(label: 'Photo ID Document Number'),
                    const CustomTextField(label: 'Nationality'),
                    const CustomTextField(label: 'Expiry Date'),
                    const SizedBox(height: 16),
                    const SectionHeader(title: 'PERSONAL DETAILS'),
                    const CustomTextField(label: 'First Name'),
                    const CustomTextField(label: 'Last Name'),
                    const CustomTextField(label: 'Sex'),
                    const CustomTextField(label: 'Date of Birth'),
                    const SizedBox(height: 16),
                    const SectionHeader(title: 'CONTACT INFORMATION'),
                    const CustomTextField(label: 'Mobile Number'),
                    const CustomTextField(label: 'Phone Number (Optional)'),
                    const SizedBox(height: 16),
                    const SectionHeader(title: 'ADDRESS'),
                    const CustomTextField(label: 'Address Line 1 (Street address)'),
                    const CustomTextField(label: 'Address Line 2 (Optional)'),
                    const CustomTextField(label: 'City / Suburb'),
                    const CustomTextField(label: 'State'),
                    const CustomTextField(label: 'Postcode'),
                    const CustomTextField(label: 'Country'),
                    const SizedBox(height: 16),
                    ActionButtons(
                      formKey: _formKey,
                      onConfirm: () {
                        if (_formKey.currentState!.validate()) {
                          // Perform confirm action
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
