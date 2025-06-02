import 'package:flutter/material.dart';

class DropdownField extends StatelessWidget {
  final String hint;
  final List<String> items;
  final String? value; // Add a value parameter
  final void Function(String?) onChanged;

  const DropdownField({
    required this.hint,
    required this.items,
    required this.onChanged,
    this.value, // Make the value optional
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButton<String>(
          isExpanded: true,
          value: value, // Pass the current value here
          hint: Text(
            hint,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: const TextStyle(fontSize: 16, color: Colors.black),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
        ),
      ),
    );
  }
}
