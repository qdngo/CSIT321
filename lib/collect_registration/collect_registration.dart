import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sample_assist/collect_registration/camera_with_scan.dart';
import 'package:sample_assist/collect_registration/processing_page.dart';
import 'package:sample_assist/utils/consts.dart';
import 'widgets/step_indicator.dart';
import 'widgets/section_title.dart';
import 'widgets/photo_id_section.dart';
import 'widgets/dropdown_field.dart';
import 'widgets/custom_text_field.dart';
import 'widgets/action_buttons.dart';
import 'widgets/section_header.dart';
import 'package:http/http.dart' as http;

class CollectRegistration extends StatefulWidget {
  const CollectRegistration({super.key, required this.email});
  final String email;

  @override
  State<CollectRegistration> createState() => _CollectRegistrationScreenState();
}

class _CollectRegistrationScreenState extends State<CollectRegistration> {
  final _formKey = GlobalKey<FormState>();
  String? selectedPhotoIDType;
  final ImagePicker _imagePicker = ImagePicker();
  File? _uploadedPhoto;
  bool isLoading = false;

  final idController = TextEditingController();
  final nationalController = TextEditingController();
  final expiryController = TextEditingController();
  final cardNumberController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final addressController = TextEditingController();
  final sexController = TextEditingController();
  final dobController = TextEditingController();
  final mobileNumberController = TextEditingController();
  final phoneNumberController = TextEditingController();
  // Method to get a photo from the gallery
  Future<void> _getPhotoFromGallery() async {
    try {
      final XFile? pickedFile =
      await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        _uploadedPhoto = File(pickedFile.path);

        setState(() {});
      }
      await uploadFileDriver(_uploadedPhoto!.path, getPathProcess());
    } catch (e) {
      print('Error selecting photo: $e');
    }
  }

  Future<XFile?> pickAndCropImage() async {
    final XFile? pickedFile =
    await _imagePicker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Cắt ảnh',
            lockAspectRatio: false, // Giữ nguyên tỷ lệ đã đặt
          ),
          IOSUiSettings(
            aspectRatioLockEnabled: false, // Khóa tỷ lệ
          ),
        ],
      );

      if (croppedFile != null) {
        return XFile(croppedFile.path);
      }
    }

    return null;
  }

  //Method to take a photo using the camera
  Future<void> _takePhoto() async {
    final cameras = await availableCameras();
    CameraController controller =
    CameraController(cameras.first, ResolutionPreset.high);
    controller.initialize();

    try {
      final XFile? pickedFile = await pickAndCropImage();
      if (pickedFile != null) {
        _uploadedPhoto = File(pickedFile.path);

        await uploadFileDriver(_uploadedPhoto!.path, getPathProcess());
      }
      setState(() {});
    } catch (e) {
      if (kDebugMode) {
        print('Error capturing photo: $e');
      }
    }
  }

  //Method to take a photo using the camera
  Future<void> _scanImage() async {
    final cameras = await availableCameras();
    CameraController controller =
    CameraController(cameras.first, ResolutionPreset.high);
    Future<void> initializeControllerFuture = controller.initialize();

    try {
      final XFile? pickedFile = await Navigator.push(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(
          builder: (context) => CameraWithScan(
            controller: controller,
            initializeControllerFuture: initializeControllerFuture,
          ),
        ),
      );
      if (pickedFile != null) {
        _uploadedPhoto = File(pickedFile.path);

        await uploadFileDriver(_uploadedPhoto!.path, getPathProcess());
      }
      setState(() {});
    } catch (e) {
      if (kDebugMode) {
        print('Error capturing photo: $e');
      }
    }
  }

  String getPathProcess() {
    if (selectedPhotoIDType == "Driver's License") {
      return pathProcessDriverLicense;
    } else if (selectedPhotoIDType == "Passport") {
      return pathProcessPassport;
    } else if (selectedPhotoIDType == "National ID") {
      return pathProcessPhotoCard;
    }
    return '';
  }

  String getPathStorege() {
    if (selectedPhotoIDType == "Driver's License") {
      return pathStoreDriverLicense;
    } else if (selectedPhotoIDType == "Passport") {
      return pathStorePassport;
    } else if (selectedPhotoIDType == "National ID") {
      return pathStorePhotoCard;
    }
    return '';
  }

  Map<String, dynamic> getBody() {
    if (selectedPhotoIDType == "Driver's License") {
      return {
        "email": widget.email,
        "first_name": firstNameController.text,
        "last_name": lastNameController.text,
        "address": addressController.text,
        "license_number": idController.text,
        "card_number": cardNumberController.text,
        "date_of_birth": dobController.text,
        "expiry_date": expiryController.text,
      };
    } else if (selectedPhotoIDType == "Passport") {
      return {
        "email": widget.email,
        "first_name": firstNameController.text,
        "last_name": lastNameController.text,
        "date_of_birth": dobController.text,
        "document_number": idController.text,
        "expiry_date": expiryController.text,
        "gender": sexController.text,
      };
    } else if (selectedPhotoIDType == "National ID") {
      return {
        "email": widget.email,
        "first_name": firstNameController.text,
        "last_name": lastNameController.text,
        "address": addressController.text,
        "photo_card_number": idController.text,
        "date_of_birth": dobController.text,
        "card_number": cardNumberController.text,
        "gender": sexController.text,
        "expiry_date": expiryController.text,
      };
    }
    return <String, dynamic>{};
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

  Future<void> uploadFileDriver(String filePath, String urlApi) async {
    final url = Uri.parse('$baseUri$urlApi');

    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ProcessingPage(),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));
      // Tạo file từ đường dẫn
      var file = File(filePath);

      // Kiểm tra file có tồn tại không
      if (!await file.exists()) {
        return;
      }

      // Tạo yêu cầu multipart
      var request = http.MultipartRequest('POST', url)
        ..headers['Accept'] = 'application/json'
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      // Gửi yêu cầu
      var response = await request.send();

      // Đọc phần hồi
      Navigator.pop(context);

      // Kiểm tra phản hồi
      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        final data = jsonDecode(responseBody)['extracted_data'] ?? '';
        firstNameController.text = data['first_name'] ?? '';
        lastNameController.text = data['last_name'] ?? '';
        addressController.text = data['address'] ?? '';
        cardNumberController.text = data['card_number'] ?? '';
        dobController.text = data['date_of_birth'] ?? '';
        expiryController.text = data['expiry_date'] ?? '';
        sexController.text = data['gender'] ?? '';
        idController.text =
            data['photo_card_number'] ?? data['license_number'] ?? '';

        setState(() {});
      } else {
        print('Lỗi khi tải lên: ${response.statusCode}');
      }
    } catch (e) {
      print('Đã xảy ra lỗi: $e');
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
                      scanPhoto: _scanImage,
                      watchPhoto: _showFullPhotoDialog,
                      deletePhoto:
                      _deletePhoto, // Provide the watch photo callback
                      isCheck: selectedPhotoIDType != null,
                    ),
                    CustomTextField(
                      label: 'Photo ID Document Number',
                      controller: idController,
                    ),
                    CustomTextField(
                      label: 'Nationality',
                      controller: nationalController,
                    ),
                    CustomTextField(
                      label: 'Expiry Date',
                      controller: expiryController,
                    ),
                    if (selectedPhotoIDType == "Driver's License" ||
                        selectedPhotoIDType == "National ID")
                      CustomTextField(
                        label: 'Card Number',
                        controller: cardNumberController,
                      ),
                    SizedBox(height: 16),
                    SectionHeader(title: 'PERSONAL DETAILS'),
                    CustomTextField(
                      label: 'First Name',
                      controller: firstNameController,
                    ),
                    CustomTextField(
                      label: 'Last Name',
                      controller: lastNameController,
                    ),
                    if (selectedPhotoIDType == "Passport")
                      CustomTextField(
                        label: 'Sex',
                        controller: sexController,
                      ),
                    CustomTextField(
                      label: 'Date of Birth',
                      controller: dobController,
                    ),
                    const SizedBox(height: 16),
                    SectionHeader(title: 'CONTACT INFORMATION'),
                    CustomTextField(
                      label: 'Mobile Number',
                      controller: mobileNumberController,
                    ),
                    CustomTextField(
                      label: 'Phone Number (Optional)',
                      controller: phoneNumberController,
                      isValidate: false,
                    ),
                    const SizedBox(height: 16),
                    if (selectedPhotoIDType == "Driver's License" ||
                        selectedPhotoIDType == "National ID")
                      SectionHeader(title: 'ADDRESS'),
                    if (selectedPhotoIDType == "Driver's License" ||
                        selectedPhotoIDType == "National ID")
                      CustomTextField(
                        label: 'Address',
                        controller: addressController,
                      ),
                    const SizedBox(height: 16),
                    ActionButtons(
                      formKey: _formKey,
                      onTap: storeDriverLicense,
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

  Future<void> storeDriverLicense() async {
    String url = '$baseUri${getPathStorege()}';
    const Map<String, String> headers = {
      'accept': 'application/json',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(getBody()),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        showDialog(
          context: context,
          builder: (context) => const AlertDialog(
            title: Text("Success!"),
            content: Text("Your data has been saved successfully!"),
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => const AlertDialog(
            title: Text("Fail!"),
            content: Text("Your data has been saved fail!"),
          ),
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text("Fail!"),
          content: Text("Your data has been saved fail!"),
        ),
      );
    }
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