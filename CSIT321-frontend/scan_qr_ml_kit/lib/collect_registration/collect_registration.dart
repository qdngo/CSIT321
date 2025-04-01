import 'dart:convert';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scan_ml_text_kit/collect_registration/processing_page.dart';
import 'package:scan_ml_text_kit/collect_registration/scan_camera_screen.dart';
import 'package:scan_ml_text_kit/extension/string_ext.dart';
import 'package:scan_ml_text_kit/main.dart';
import 'package:scan_ml_text_kit/model/scan_model.dart';
import 'package:scan_ml_text_kit/utils/consts.dart';
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
        if (_uploadedPhoto != null) {
          final model = await _detachTextFromFile(_uploadedPhoto!);

          setState(() {
            firstNameController.text = model.firstName ?? '';
            addressController.text = model.address ?? '';
            dobController.text = model.dateOfBirth ?? '';
            cardNumberController.text = model.licenseNumber ?? '';
          });
        }

        await uploadFileDriver(_uploadedPhoto!.path, getPathProcess());
      }
      setState(() {});
    } catch (e) {
      logger.e('Error selecting photo: $e');
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
            toolbarTitle: 'Crop image',
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
    try {
      final XFile? pickedFile = await pickAndCropImage();
      if (pickedFile != null) {
        _uploadedPhoto = File(pickedFile.path);
        if (_uploadedPhoto != null) {
          final model = await _detachTextFromFile(_uploadedPhoto!);

          setState(() {
            firstNameController.text = model.firstName ?? '';
            addressController.text = model.address ?? '';
            dobController.text = model.dateOfBirth ?? '';
            cardNumberController.text = model.licenseNumber ?? '';
          });
        }

        await uploadFileDriver(_uploadedPhoto!.path, getPathProcess());
      }
      setState(() {});
    } catch (e) {
      logger.e('Error capturing photo: $e');
    }
  }

  //Method to take a photo using the camera
  Future<void> _scanImage() async {
    try {
      final ScanModel results = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScanCameraScreen(
            type: selectedPhotoIDType!,
          ),
        ),
      );

      setState(() {
        _uploadedPhoto = File(results.filePath ?? '');
        firstNameController.text = results.firstName ?? '';
        addressController.text = results.address ?? '';
        dobController.text = results.dateOfBirth ?? '';
        cardNumberController.text = results.licenseNumber ?? '';
      });

      if (results.filePath != null) {
        await uploadFileDriver(_uploadedPhoto!.path, getPathProcess());
      }
    } catch (e) {
      logger.e('Error capturing photo: $e');
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

  String getPathStorage() {
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

      // Tạo file từ đường dẫn
      var file = File(filePath);

      if (!await file.exists()) {
        logger.e('File không tồn tại.');
        return;
      }

      // Tạo yêu cầu multipart
      var request = http.MultipartRequest('POST', url)
        ..headers['Accept'] = 'application/json'
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      // Gửi yêu cầu
      var response = await request.send();

      // Đọc phần hồi
      if (!mounted) return;
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
        logger.e('Lỗi khi tải lên: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Đã xảy ra lỗi: $e');
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  Future<ScanModel> _detachTextFromFile(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);
    final ScanModel model = ScanModel();

    final rawText = recognizedText.text.toUpperCase();

    if ((rawText.contains('DRIVER LICENCE') ||
            rawText.contains('PASSPORT') ||
            rawText.contains('NATIONAL')) &&
        rawText.contains('LICENCE NO') &&
        rawText.contains('DATE OF BIRTH')) {
      final textSplit = rawText.split(RegExp(r'\r?\n'));

      model.filePath = imageFile.path;
      return await _detachDataLocal(model, textSplit);
    }
    return model;
  }

  Future<ScanModel> _detachDataLocal(
    ScanModel model,
    List<String> textSplit,
  ) async {
    final iLicenceNo = textSplit.indexOf('LICENCE NO') + 1;
    final iDoB = textSplit.indexOf('DATE OF BIRTH') + 1;
    int count = 0;
    String address = '';
    String name = textSplit.firstWhere((e) {
      if (e.isName() &&
          !e.contains('LICENCE') &&
          !e.contains('PASSPORT') &&
          !e.contains('NATIONAL') &&
          !e.contains('DRIVING') &&
          !e.contains('AUSTRALIAN')) {
        return true;
      }
      return false;
    });
    for (var result in textSplit) {
      if (result.isAddress()) {
        count++;
        address += '$result ';
      }
      if (count >= 2) {
        break;
      }
    }

    final licenseNo = textSplit[iLicenceNo];
    final dob = textSplit[iDoB];

    model.firstName = name;
    model.address = address;

    if (dob.isDate()) {
      model.dateOfBirth = dob;
    } else {
      model.dateOfBirth = textSplit.firstWhereOrNull((e) => e.isDate()) ?? '';
    }

    if (int.tryParse(licenseNo) != null) {
      model.licenseNumber = licenseNo;
    } else {
      model.licenseNumber =
          textSplit.firstWhereOrNull((e) => e.isNumber()) ?? '';
    }
    return model;
  }

  void _deletePhoto() {
    // Delete the photo and update the state
    setState(() {
      _uploadedPhoto = null;
    });
    logger.e("Photo deleted");
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
                      items: const [
                        'Passport',
                        'Driver\'s License',
                        'National ID'
                      ],
                      value: selectedPhotoIDType,
                      onChanged: (value) {
                        setState(() {
                          selectedPhotoIDType = value;
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
                      deletePhoto: _deletePhoto,
                      // Provide the watch photo callback
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
                    const SizedBox(height: 16),
                    const SectionHeader(title: 'PERSONAL DETAILS'),
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
                    const SectionHeader(title: 'CONTACT INFORMATION'),
                    CustomTextField(
                      label: 'Mobile Number',
                      controller: mobileNumberController,
                    ),
                    CustomTextField(
                      label: 'Phone Number (Optional)',
                      controller: phoneNumberController,
                    ),
                    const SizedBox(height: 16),
                    if (selectedPhotoIDType == "Driver's License" ||
                        selectedPhotoIDType == "National ID")
                      const SectionHeader(title: 'ADDRESS'),
                    if (selectedPhotoIDType == "Driver's License" ||
                        selectedPhotoIDType == "National ID")
                      CustomTextField(
                        label: 'Address',
                        controller: addressController,
                      ),
                    const SizedBox(height: 16),
                    ActionButtons(
                      formKey: _formKey,
                      path: getPathStorage(),
                      body: getBody(),
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
