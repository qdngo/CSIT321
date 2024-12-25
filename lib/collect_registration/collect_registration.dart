import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sample_assist/collect_registration/camera_with_frame.dart';
import 'package:sample_assist/collect_registration/services/opencv_service.dart';
import 'widgets/step_indicator.dart';
import 'widgets/section_title.dart';
import 'widgets/photo_id_section.dart';
import 'widgets/dropdown_field.dart';
import 'widgets/custom_text_field.dart';
import 'widgets/action_buttons.dart';
import 'widgets/section_header.dart';
import 'package:http/http.dart' as http;
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
  // Method to get a photo from the gallery
  Future<void> _getPhotoFromGallery() async {
    try {
      final XFile? pickedFile =
      await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _uploadedPhoto = File(pickedFile.path);
        });
      }
      if (selectedPhotoIDType == "Driver's License") {
        await _sendPhotoToApi(_uploadedPhoto!);
      }
    } catch (e) {
      print('Error selecting photo: $e');
    }
  }

  //Method to take a photo using the camera
  Future<void> _takePhoto() async {
    final cameras = await availableCameras();
    CameraController controller =
    CameraController(cameras.first, ResolutionPreset.high);
    Future<void> initializeControllerFuture = controller.initialize();

    try {
      final XFile? pickedFile = await Navigator.push(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(
          builder: (context) => CameraWithFrame(
            controller: controller,
            initializeControllerFuture: initializeControllerFuture,
          ),
        ),
      );
      if (pickedFile != null) {
        setState(() {
          _uploadedPhoto = File(pickedFile.path);
        });
        if (selectedPhotoIDType == "Driver's License") {
          await _sendPhotoToApi(_uploadedPhoto!);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error capturing photo: $e');
      }
    }
  }

  // Method to show the full photo in a dialog
  void _showFullPhotoDialog() {
    if (_uploadedPhoto == null) return; // Ensure there is a photo to display

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.file(
                _uploadedPhoto!,
                fit: BoxFit.cover,
              ),
              TextButton(
                onPressed: () => Navigator.pop(context), // Close the dialog
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
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
        // _populateFormFields(data['extracted_data']);
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


  void _deletePhoto() {
    // Delete the photo and update the state
    setState(() {
      _uploadedPhoto = null;
    });
    print("Photo deleted");
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
                    DropdownField(
                      hint: 'Please select a type of Photo ID',
                      items: ['Passport', 'Driver\'s License', 'National ID'],
                      value:
                      selectedPhotoIDType, // Pass the current state value
                      onChanged: (value) {
                        setState(() {
                          selectedPhotoIDType =
                              value; // Update state on selection
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    PhotoIdSection(
                      uploadedPhoto: _uploadedPhoto,
                      getPhotoFromGallery: _getPhotoFromGallery,
                      takePhoto: _takePhoto,
                      watchPhoto: _showFullPhotoDialog,
                      deletePhoto:
                      _deletePhoto, // Provide the watch photo callback
                    ),
                    const CustomTextField(label: 'Photo ID Document Number'),
                    const CustomTextField(label: 'Nationality'),
                    const CustomTextField(label: 'Expiry Date'),
                    const CustomTextField(label: 'Card Number'),
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
                    const CustomTextField(label: 'Address'),
                    const SizedBox(height: 16),
                    ActionButtons(
                      formKey: _formKey,
                      onConfirm: () {
                        if (_formKey.currentState!.validate()) {
                          // Perform confirm action
                          print("Form submitted successfully");
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

//
// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:http/http.dart' as http;
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
//   // Controllers for autofill
//   final TextEditingController firstNameController = TextEditingController();
//   final TextEditingController lastNameController = TextEditingController();
//   final TextEditingController addressController = TextEditingController();
//   final TextEditingController licenseNumberController = TextEditingController();
//   final TextEditingController cardNumberController = TextEditingController();
//   final TextEditingController dateOfBirthController = TextEditingController();
//   final TextEditingController expiryDateController = TextEditingController();
//
//   // Method to get a photo from the gallery
//   void _getPhotoFromGallery() async {
//     try {
//       final XFile? pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
//       if (pickedFile != null) {
//         setState(() {
//           _uploadedPhoto = File(pickedFile.path);
//         });
//
//         // If "Driver's License" is selected, send the image to the API
//         if (selectedPhotoIDType == "Driver's License") {
//           _sendPhotoToApi(_uploadedPhoto!);
//         }
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
//
//         // If "Driver's License" is selected, send the image to the API
//         if (selectedPhotoIDType == "Driver's License") {
//           _sendPhotoToApi(_uploadedPhoto!);
//         }
//       }
//     } catch (e) {
//       print('Error capturing photo: $e');
//     }
//   }
//
//   void _deletePhoto() {
//     // Delete the photo and update the state
//     setState(() {
//       _uploadedPhoto = null;
//     });
//     print("Photo deleted");
//   }
//
//   // Method to send the photo to the API
//   Future<void> _sendPhotoToApi(File photo) async {
//     const String apiUrl = "http://34.55.218.37:9090/process_driver_license/";
//
//     try {
//       final request = http.MultipartRequest('POST', Uri.parse(apiUrl));
//       request.files.add(await http.MultipartFile.fromPath('file', photo.path));
//
//       final response = await request.send();
//       final responseBody = await response.stream.bytesToString();
//
//       print('Response status: ${response.statusCode}');
//       print('Response body: $responseBody');
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(responseBody);
//
//         // Safely access nested fields from 'extracted_data'
//         final extractedData = data['extracted_data'] ?? {};
//         final String firstName = extractedData['first_name'] ?? 'N/A';
//         final String lastName = extractedData['last_name'] ?? 'N/A';
//         final String address = extractedData['address'] ?? 'N/A';
//         final String licenseNumber = extractedData['license_number'] ?? 'N/A';
//         final String cardNumber = extractedData['card_number'] ?? 'N/A';
//         final String dateOfBirth = extractedData['date_of_birth'] ?? 'N/A';
//         final String expiryDate = extractedData['expiry_date'] ?? 'N/A';
//
//         // Autofill form fields
//         setState(() {
//           firstNameController.text = firstName;
//           lastNameController.text = lastName;
//           addressController.text = address;
//           licenseNumberController.text = licenseNumber;
//           cardNumberController.text = cardNumber;
//           dateOfBirthController.text = dateOfBirth;
//           expiryDateController.text = expiryDate;
//         });
//
//         // Show dialog with results
//         _showApiResultDialog();
//       } else {
//         _showErrorDialog("Failed to process the driver's license. Status: ${response.statusCode}");
//       }
//     } catch (e) {
//       print('Error sending photo to API: $e');
//       _showErrorDialog("An unexpected error occurred while processing the driver's license.");
//     }
//   }
//
//   void _showApiResultDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("Driver's License OCR Result"),
//         content: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text("First Name: ${firstNameController.text}"),
//             Text("Last Name: ${lastNameController.text}"),
//             Text("Address: ${addressController.text}"),
//             Text("License Number: ${licenseNumberController.text}"),
//             Text("Card Number: ${cardNumberController.text}"),
//             Text("Date of Birth: ${dateOfBirthController.text}"),
//             Text("Expiry Date: ${expiryDateController.text}"),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text("OK"),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // Method to show an error dialog
//   void _showErrorDialog(String message) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("Error"),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text("OK"),
//           ),
//         ],
//       ),
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
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 DropdownButtonFormField<String>(
//                   decoration: const InputDecoration(
//                     labelText: 'Photo ID Type',
//                     border: OutlineInputBorder(),
//                   ),
//                   value: selectedPhotoIDType,
//                   items: const [
//                     DropdownMenuItem(value: 'Passport', child: Text('Passport')),
//                     DropdownMenuItem(value: 'Driver\'s License', child: Text('Driver\'s License')),
//                     DropdownMenuItem(value: 'National ID', child: Text('National ID')),
//                   ],
//                   onChanged: (value) {
//                     setState(() {
//                       selectedPhotoIDType = value;
//                     });
//                   },
//                 ),
//                 const SizedBox(height: 16),
//                 GestureDetector(
//                   onTap: _getPhotoFromGallery,
//                   child: Container(
//                     height: 200,
//                     width: double.infinity,
//                     decoration: BoxDecoration(
//                       border: Border.all(color: Colors.grey),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: _uploadedPhoto == null
//                         ? const Center(
//                       child: Text("Upload or take a photo of your ID"),
//                     )
//                         : Image.file(
//                       _uploadedPhoto!,
//                       fit: BoxFit.cover,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: firstNameController,
//                   decoration: const InputDecoration(
//                     labelText: 'First Name',
//                     border: OutlineInputBorder(),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: lastNameController,
//                   decoration: const InputDecoration(
//                     labelText: 'Last Name',
//                     border: OutlineInputBorder(),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: addressController,
//                   decoration: const InputDecoration(
//                     labelText: 'Address',
//                     border: OutlineInputBorder(),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: licenseNumberController,
//                   decoration: const InputDecoration(
//                     labelText: 'License Number',
//                     border: OutlineInputBorder(),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: cardNumberController,
//                   decoration: const InputDecoration(
//                     labelText: 'Card Number',
//                     border: OutlineInputBorder(),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: dateOfBirthController,
//                   decoration: const InputDecoration(
//                     labelText: 'Date of Birth',
//                     border: OutlineInputBorder(),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: expiryDateController,
//                   decoration: const InputDecoration(
//                     labelText: 'Expiry Date',
//                     border: OutlineInputBorder(),
//                   ),
//                 ),
//                 const SizedBox(height: 32),
//                 ElevatedButton(
//                   onPressed: () {
//                     if (_formKey.currentState!.validate()) {
//                       print("Form Submitted");
//                     }
//                   },
//                   child: const Text("Submit"),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//