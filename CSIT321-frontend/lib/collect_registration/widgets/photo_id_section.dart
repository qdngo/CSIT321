import 'dart:io';
import 'package:flutter/material.dart';

class PhotoIdSection extends StatelessWidget {
  final File? uploadedPhoto;
  final VoidCallback getPhotoFromGallery;
  final VoidCallback takePhoto;

  const PhotoIdSection({
    required this.uploadedPhoto,
    required this.getPhotoFromGallery,
    required this.takePhoto,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: uploadedPhoto != null
          ? ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          uploadedPhoto!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      )
          : Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Please upload your current Photo ID',
            style: TextStyle(fontSize: 18, color: Color(0xFF156CC9)),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _showPhotoIdOptions(context),
            child: Container(
              height: 70,
              width: 70,
              decoration: const BoxDecoration(
                color: Color(0xFF156CC9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt, size: 30, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showPhotoIdOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF156CC9)),
              title: const Text('Take Photo'),
              onTap: () {
                takePhoto();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload, color: Color(0xFF156CC9)),
              title: const Text('Upload'),
              onTap: () {
                getPhotoFromGallery();
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}
