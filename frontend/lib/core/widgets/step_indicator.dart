import 'package:flutter/material.dart';

class StepIndicator extends StatelessWidget {
  const StepIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: index == 0 ? const Color(0xFF156CC9) : Colors.grey.shade300,
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 12,
                  color: index == 0 ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ),
            if (index != 4)
              Container(
                width: 40,
                height: 2,
                color: Colors.grey.shade300,
              ),
          ],
        );
      }),
    );
  }
}
