import 'dart:convert';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sample_assist/collect_registration/processing_page.dart';
import 'package:sample_assist/collect_registration/scan_camera_screen.dart';
import 'package:sample_assist/collect_registration/services/fetch_api.dart';
import 'package:sample_assist/extension/string_ext.dart';
import 'package:sample_assist/main.dart';
import 'package:sample_assist/model/scan_model.dart';
import 'package:sample_assist/utils/consts.dart';
import 'widgets/step_indicator.dart';
import 'widgets/section_title.dart';
import 'widgets/photo_id_section.dart';
import 'widgets/dropdown_field.dart';
import 'widgets/custom_text_field.dart';
import 'widgets/action_buttons.dart';
import 'widgets/section_header.dart';
import 'widgets/theme_provider.dart';
import 'package:http/http.dart' as http;

class CollectRegistration extends StatefulWidget {
  const CollectRegistration({super.key, required this.email});
  final String email;

  @override
  State<CollectRegistration> createState() => _CollectRegistrationScreenState();
}

class _CollectRegistrationScreenState extends State<CollectRegistration> {
  final _formKey = GlobalKey<FormState>();
  bool isError = true;
  String? selectedPhotoIDType;
  final ImagePicker _imagePicker = ImagePicker();
  File? _uploadedPhoto;
  bool isLoading = true;
  bool _isPanelOpen = false;  // Track whether the panel is open or closed

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

  final PanelController _panelController = PanelController();  // Controller for the sliding panel

  // Method to toggle the panel's state
  void _togglePanel() {
    if (_isPanelOpen) {
      _panelController.close();
    } else {
      _panelController.open();
    }
    setState(() {
      _isPanelOpen = !_isPanelOpen;
    });
  }

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

  Future<void> _handleSignOut() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (shouldLogout ?? false) {
      // Clear form state
      setState(() {
        _uploadedPhoto = null;
        selectedPhotoIDType = null;
        idController.clear();
        nationalController.clear();
        expiryController.clear();
        cardNumberController.clear();
        firstNameController.clear();
        lastNameController.clear();
        addressController.clear();
        sexController.clear();
        dobController.clear();
        mobileNumberController.clear();
        phoneNumberController.clear();
      });

      // Show success dialog
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Logged out'),
          content: const Text('You have been logged out successfully.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      // Navigate to login screen
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MyApp()),
            (route) => false,
      );
    }
  }

  Future<void> deleteAccount(String email) async {
    try {
      final response = await http.delete(
          Uri.parse('$deleteAccountUri?email=$email'), // Replace with your actual delete account endpoint
          headers: {'Content-Type': 'application/json'}
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final message = data['message'] ?? "Account deleted successfully.";

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Account Deleted"),
            content: Text(message),
          ),
        );

        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          Navigator.of(context).pop(); // Close dialog
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MyApp()),
                (Route<dynamic> route) => false,
          );
        });
      } else {
        _showErrorDialog(
          "Failed to delete account. Status: ${response.statusCode}",
        );
      }
    } catch (error) {
      _showErrorDialog("An error occurred: $error");
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

  @override
  initState() {
    super.initState();
    // Call the API to get the photo card
    initData();
  }

  Future<void> initData() async {
    // call api lấy data
    final responsePhotoCar = await FetchApi.getInfoCard(widget.email);
    final responsePassport = await FetchApi.getInfoPassport(widget.email);
    final responseDriverLicense =
    await FetchApi.getInfoDriverLicense(widget.email);

    if (responsePhotoCar.isNotEmpty ||
        responsePassport.isNotEmpty ||
        responseDriverLicense.isNotEmpty) {
      // check xem có dữ liệu hay không rồi chuyển trạng thái
      setState(() {
        isError = false;
        isLoading = false;

        // fill dữ liệu vào các trường
        if (responsePhotoCar.isNotEmpty) {
          idController.text = responsePhotoCar.first.cardNumber.toString();

          expiryController.text =
          responsePhotoCar.first.expiryDate.toString().split(' ')[0];
          cardNumberController.text =
              responsePhotoCar.first.photoCardNumber.toString();
          firstNameController.text =
              responsePhotoCar.first.firstName.toString();
          lastNameController.text = responsePhotoCar.first.lastName.toString();
          addressController.text = responsePhotoCar.first.address.toString();
          sexController.text = responsePhotoCar.first.toString();
          dobController.text =
          responsePhotoCar.first.dateOfBirth.toString().split(' ')[0];
          selectedPhotoIDType = 'National ID';
        } else if (responsePassport.isNotEmpty) {
          idController.text = responsePassport.first.documentNumber.toString();
          expiryController.text =
          responsePassport.first.expiryDate.toString().split(' ')[0];
          cardNumberController.text =
              responsePassport.first.documentNumber.toString();
          firstNameController.text =
              responsePassport.first.firstName.toString();
          lastNameController.text = responsePassport.first.lastName.toString();
          sexController.text = responsePassport.first.gender.toString();
          dobController.text =
          responsePassport.first.dateOfBirth.toString().split(' ')[0];
          selectedPhotoIDType = 'Passport';
        } else if (responseDriverLicense.isNotEmpty) {
          idController.text = responseDriverLicense.first.cardNumber.toString();
          expiryController.text =
          responseDriverLicense.first.expiryDate.toString().split(' ')[0];
          cardNumberController.text =
              responseDriverLicense.first.cardNumber.toString();
          firstNameController.text =
              responseDriverLicense.first.firstName.toString();
          lastNameController.text =
              responseDriverLicense.first.lastName.toString();
          addressController.text =
              responseDriverLicense.first.address.toString();
          dobController.text =
          responseDriverLicense.first.dateOfBirth.toString().split(' ')[0];
          selectedPhotoIDType = 'Driver\'s License';
        }
      });
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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _togglePanel,
          ),
        ],
        backgroundColor: const Color(0xFF01B4D2),
      ),
      body: Stack(
        children: [
          // Main content with error check
          isError
              ? _buildCallApiError()
              : SingleChildScrollView(
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

          // Settings Panel
          SlidingUpPanel(
            controller: _panelController,
            minHeight: 0,
            maxHeight: 300,
            panel: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Settings', style: Theme.of(context).textTheme.titleLarge),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.dark_mode),
                    title: const Text('Dark Mode'),
                    onTap: () {
                      final themeProvider = context.read<ThemeProvider>();
                      themeProvider.toggleTheme(!themeProvider.isDarkMode);
                      _panelController.close();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.exit_to_app),
                    title: const Text('Sign Out'),
                    onTap: () async {
                      await _panelController.close();
                      await _handleSignOut();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete),
                    title: const Text('Delete Account'),
                    onTap: () async {
                      _panelController.close();

                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Confirm Deletion"),
                          content: const Text("Are you sure you want to delete your account? This action cannot be undone."),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text("Delete", style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await deleteAccount(widget.email); // Make sure `userEmail` is available (from login/session)
                      }
                    },
                  )
                ],
              ),
            ),
            onPanelOpened: () => setState(() => _isPanelOpen = true),
            onPanelClosed: () => setState(() => _isPanelOpen = false),
          ),
        ],
      ),
    );
  }


  Widget _buildCallApiError() {
    return Center(
      child: isLoading
          ? CircularProgressIndicator()
          : Text(
        'Error calling API',
        style: TextStyle(color: Colors.red),
      ),
    );
  }
}