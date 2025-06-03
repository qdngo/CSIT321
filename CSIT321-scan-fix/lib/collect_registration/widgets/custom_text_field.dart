import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final bool? isValidate;
  const CustomTextField({
    required this.label,
    this.controller, // Add the controller to the constructor
    this.isValidate = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        TextFormField(
          validator: (value) {
            if (value == null || value.isEmpty && isValidate!) {
              return 'This field is required';
            }
            return null;
          },
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            floatingLabelStyle: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.bold,
            ),
            border: const OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Colors.grey.shade400,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Colors.grey.shade400,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}