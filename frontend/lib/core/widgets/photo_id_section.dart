import 'dart:io';
import 'package:flutter/material.dart';

class PhotoIdSection extends StatelessWidget {
  final File? uploadedPhoto; // Photo file passed to this widget
  final VoidCallback getPhotoFromGallery; // Callback to get photo from gallery
  final VoidCallback takePhoto; // Callback to take photo
  final VoidCallback scanPhoto; // Callback to take photo
  final VoidCallback watchPhoto;
  final VoidCallback deletePhoto; // Callback to view the full photo
  final bool isCheck;

  const PhotoIdSection({
    required this.uploadedPhoto,
    required this.getPhotoFromGallery,
    required this.takePhoto,
    required this.watchPhoto,
    required this.scanPhoto,
    required this.deletePhoto,
    required this.isCheck,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (isCheck) _showPhotoIdOptions(context);
      }, // Show options when tapped
      child: Container(
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
            Container(
              height: 70,
              width: 70,
              decoration: const BoxDecoration(
                color: Color(0xFF156CC9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 30,
                color: Colors.white,
              ),
            ),
          ],
        ),
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
            if (uploadedPhoto != null) ...[
              ListTile(
                leading: const Icon(Icons.visibility, color: Color(0xFF156CC9)),
                title: const Text(
                  'Watch Photo',
                  style: TextStyle(fontSize: 16, color: Color(0xFF156CC9)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  watchPhoto(); // View the full photo
                },
              ),
              const Divider(height: 1),
            ],
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF156CC9)),
              title: const Text(
                'Take Photo',
                style: TextStyle(fontSize: 16, color: Color(0xFF156CC9)),
              ),
              onTap: () {
                Navigator.pop(context);

                takePhoto(); // Take a new photo
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.adf_scanner,
                color: Color(0xFF156CC9),
              ),
              title: const Text(
                'Scan',
                style: TextStyle(fontSize: 16, color: Color(0xFF156CC9)),
              ),
              onTap: () {
                Navigator.pop(context);

                // Tự động mở camera và chụp ảnh sau 4 giây
                scanPhoto();
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.upload, color: Color(0xFF156CC9)),
              title: const Text(
                'Upload',
                style: TextStyle(fontSize: 16, color: Color(0xFF156CC9)),
              ),
              onTap: () {
                Navigator.pop(context);
                getPhotoFromGallery(); // Upload from gallery
              },
            ),
            const Divider(height: 1),
            if (uploadedPhoto != null) ...[
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.grey),
                title: const Text(
                  'Delete',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                onTap: () {
                  Navigator.pop(context);
                  deletePhoto();
                  // Call a callback if deletion is required (not provided in this widget)
                },
              ),
              const Divider(height: 1),
            ],
            ListTile(
              title: const Center(
                child: Text(
                  'Close',
                  style: TextStyle(fontSize: 16, color: Colors.red),
                ),
              ),
              onTap: () {
                Navigator.pop(context); // Close the bottom sheet
              },
            ),
          ],
        );
      },
    );
  }
}