import 'package:flutter/cupertino.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({required this.title, super.key});
  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    );
  }
}
