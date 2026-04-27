import 'package:flutter/material.dart';

class WarningWidget extends StatelessWidget {
  const WarningWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.warning,
            color: Colors.orange,
            size: 28,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Chi tiêu tăng so với tháng trước',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}