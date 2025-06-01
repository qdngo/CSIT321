import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sample_assist/core/utils/consts.dart';

class ActionButtons extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final Map<String, dynamic> Function() getBody;
  final String path;
  const ActionButtons({
    required this.formKey,
    required this.getBody,
    required this.path,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF01B4D2),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: () {},
          child: const Text(
            'Save and Close',
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A1448),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: () {
            if (formKey.currentState!.validate()) {
              storeDriverLicense(context, path, getBody());
            }
          },
          child: const Text(
            'Confirm',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> storeDriverLicense(
      BuildContext context, String path, Map<String, dynamic> body) async {
    String url = '$baseUri$path';
    const Map<String, String> headers = {
      'accept': 'application/json',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (kDebugMode) {
          print("Success: ${response.body}");
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          final String message = responseData['message'] ?? 'Notification';
          _showDialog(context, message, 'Success');
        }
      } else {
        if (kDebugMode) {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          final String message =
              responseData['detail'] ?? 'An error occurred please try again';
          _showDialog(
            context,
            message,
            'Failure',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Request failed: $e");
      }
    }
  }

  Future<void> _showDialog(BuildContext context, String content, String title) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
        );
      },
    );
  }
}