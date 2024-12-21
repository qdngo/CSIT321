import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'widgets/step_indicator.dart';
import 'widgets/section_title.dart';
import 'widgets/photo_id_section.dart';
import 'widgets/dropdown_field.dart';
import 'widgets/custom_text_field.dart';
import 'widgets/action_buttons.dart';
import 'widgets/section_header.dart';
import 'package:http/http.dart' as http;


//
// class CollectRegistration extends StatefulWidget {
//   const CollectRegistration({super.key});
//
//   @override
//   State<CollectRegistration> createState() => _CollectRegistrationScreenState();
// }
//
// class _CollectRegistrationScreenState extends State<CollectRegistration> {
//   final _formKey = GlobalKey<FormState>();
//   String? selectedPhotoIDType;
//   final ImagePicker _imagePicker = ImagePicker();
//   File? _uploadedPhoto;
//
//   // Method to get a photo from the gallery
//   void _getPhotoFromGallery() async {
//     try {
//       final XFile? pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
//       if (pickedFile != null) {
//         setState(() {
//           _uploadedPhoto = File(pickedFile.path);
//         });
//       }
//     } catch (e) {
//       print('Error selecting photo: $e');
//     }
//   }
//
//   // Method to take a photo using the camera
//   void _takePhoto() async {
//     try {
//       final XFile? pickedFile = await _imagePicker.pickImage(source: ImageSource.camera);
//       if (pickedFile != null) {
//         setState(() {
//           _uploadedPhoto = File(pickedFile.path);
//         });
//       }
//     } catch (e) {
//       print('Error capturing photo: $e');
//     }
//   }
//
//   // Method to show the full photo in a dialog
//   void _showFullPhotoDialog() {
//     if (_uploadedPhoto == null) return; // Ensure there is a photo to display
//
//     showDialog(
//       context: context,
//       builder: (context) {
//         return Dialog(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Image.file(
//                 _uploadedPhoto!,
//                 fit: BoxFit.cover,
//               ),
//               TextButton(
//                 onPressed: () => Navigator.pop(context), // Close the dialog
//                 child: const Text(
//                   'Close',
//                   style: TextStyle(color: Colors.red),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Collector Registration',
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: const Color(0xFF01B4D2),
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const SizedBox(height: 16),
//             const StepIndicator(),
//             const SizedBox(height: 16),
//             const SectionTitle(title: '1. Collector Identity'),
//             const SizedBox(height: 16),
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const SectionHeader(title: 'PHOTO ID'),
//                     const SizedBox(height: 16),
//                     PhotoIdSection(
//                       uploadedPhoto: _uploadedPhoto,
//                       getPhotoFromGallery: _getPhotoFromGallery,
//                       takePhoto: _takePhoto,
//                       watchPhoto: _showFullPhotoDialog, // Provide the watch photo callback
//                     ),
//                     const SizedBox(height: 8),
//                     DropdownField(
//                       hint: 'Please select a type of Photo ID',
//                       items: ['Passport', 'Driver\'s License', 'National ID'],
//                       value: selectedPhotoIDType, // Pass the current state value
//                       onChanged: (value) {
//                         setState(() {
//                           selectedPhotoIDType = value; // Update state on selection
//                         });
//                       },
//                     ),
//                     const CustomTextField(label: 'Photo ID Document Number'),
//                     const CustomTextField(label: 'Nationality'),
//                     const CustomTextField(label: 'Expiry Date'),
//                     const SizedBox(height: 16),
//                     const SectionHeader(title: 'PERSONAL DETAILS'),
//                     const CustomTextField(label: 'First Name'),
//                     const CustomTextField(label: 'Last Name'),
//                     const CustomTextField(label: 'Sex'),
//                     const CustomTextField(label: 'Date of Birth'),
//                     const SizedBox(height: 16),
//                     const SectionHeader(title: 'CONTACT INFORMATION'),
//                     const CustomTextField(label: 'Mobile Number'),
//                     const CustomTextField(label: 'Phone Number (Optional)'),
//                     const SizedBox(height: 16),
//                     const SectionHeader(title: 'ADDRESS'),
//                     const CustomTextField(label: 'Address'),
//                     const SizedBox(height: 16),
//                     ActionButtons(
//                       formKey: _formKey,
//                       onConfirm: () {
//                         if (_formKey.currentState!.validate()) {
//                           // Perform confirm action
//                           print("Form submitted successfully");
//                         }
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// 
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'services/opencv_service.dart'; 

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
  bool isLoading = false;

  // Controllers for autofill
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController licenseNumberController = TextEditingController();
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController dateOfBirthController = TextEditingController();
  final TextEditingController expiryDateController = TextEditingController();

  // Method to get a photo from the gallery
  Future<void> _getPhotoFromGallery() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _uploadedPhoto = File(pickedFile.path);
        });

        if (selectedPhotoIDType == "Driver's License") {
          await _sendPhotoToApi(_uploadedPhoto!);
        }
      }
    } catch (e) {
      print('Error selecting photo: $e');
    }
  }

  // Method to take a photo using the camera
  Future<void> _takePhoto() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          _uploadedPhoto = File(pickedFile.path);
        });

        if (selectedPhotoIDType == "Driver's License") {
          await _sendPhotoToApi(_uploadedPhoto!);
        }
      }
    } catch (e) {
      print('Error capturing photo: $e');
    }
  }

  // Method to send the photo to the API
  Future<void> _sendPhotoToApi(File photo) async {
    setState(() {
      isLoading = true;
    });

    try {
      // Process the image locally with OpenCV
      final processedPhotoPath = await OpenCVService.processImage(photo.path);

      // Send the processed photo to the API
      const String apiUrl = "http://34.55.218.37:9090/process_driver_license/";
      final request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.files.add(await http.MultipartFile.fromPath('file', processedPhotoPath));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        _populateFormFields(data['extracted_data']);
      } else {
        _showErrorDialog("Failed to process image. Status: ${response.statusCode}");
      }
    } catch (e) {
      _showErrorDialog("An error occurred: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Autofill form fields with extracted data
  void _populateFormFields(Map<String, dynamic>? data) {
    if (data == null) return;

    setState(() {
      firstNameController.text = data['first_name'] ?? '';
      lastNameController.text = data['last_name'] ?? '';
      addressController.text = data['address'] ?? '';
      licenseNumberController.text = data['license_number'] ?? '';
      cardNumberController.text = data['card_number'] ?? '';
      dateOfBirthController.text = data['date_of_birth'] ?? '';
      expiryDateController.text = data['expiry_date'] ?? '';
    });
  }

  // Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Photo ID Type"),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        value: selectedPhotoIDType,
                        items: const [
                          DropdownMenuItem(value: 'Passport', child: Text('Passport')),
                          DropdownMenuItem(value: 'Driver\'s License', child: Text('Driver\'s License')),
                          DropdownMenuItem(value: 'National ID', child: Text('National ID')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedPhotoIDType = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _getPhotoFromGallery,
                            icon: const Icon(Icons.photo_library),
                            label: const Text("Upload Photo"),
                          ),
                          ElevatedButton.icon(
                            onPressed: _takePhoto,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text("Take Photo"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_uploadedPhoto != null)
                        Image.file(
                          _uploadedPhoto!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'First Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Last Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: addressController,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: licenseNumberController,
                        decoration: const InputDecoration(
                          labelText: 'License Number',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: cardNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Card Number',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: dateOfBirthController,
                        decoration: const InputDecoration(
                          labelText: 'Date of Birth',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: expiryDateController,
                        decoration: const InputDecoration(
                          labelText: 'Expiry Date',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            print("Form Submitted");
                          }
                        },
                        child: const Text("Submit"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
