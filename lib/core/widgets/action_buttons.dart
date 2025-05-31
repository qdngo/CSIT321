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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: () {},
          child: const Text(
            'Save and Close',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A1448),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: () async {
            if (formKey.currentState!.validate()) {
              final body = getBody(); // ✅ Capture body before await
              final currentContext = context; // ✅ Save context before await

              final result = await storeDriverLicense(path, body); // ✅ Remove context from here

              if (!currentContext.mounted) return; // ✅ Check if context is still valid

              if (result['status'] == 'Success') {
                _showDialog(currentContext, result['message']!, 'Success'); // ✅ Use saved context
              } else {
                _showDialog(currentContext, result['message']!, 'Failure'); // ✅ Use saved context
              }
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

  Future<Map<String, String>> storeDriverLicense(
      String path, Map<String, dynamic> body) async { // ✅ Removed context from here
    String url = '$baseUri$path';
    const headers = {
      'accept': 'application/json',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (kDebugMode) debugPrint("Success: ${response.body}");
        return {
          'status': 'Success',
          'message': responseData['message'] ?? 'Operation successful.',
        };
      } else {
        return {
          'status': 'Failure',
          'message': responseData['detail'] ?? 'An error occurred. Please try again.',
        };
      }
    } catch (e) {
      if (kDebugMode) debugPrint("Request failed: $e");
      return {
        'status': 'Failure',
        'message': 'Request failed. Please check your network.',
      };
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
