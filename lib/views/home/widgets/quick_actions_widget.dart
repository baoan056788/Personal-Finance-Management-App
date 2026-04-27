import 'package:flutter/material.dart';

class QuickActionsWidget extends StatelessWidget {
  const QuickActionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          ActionItem(
            icon: Icons.add,
            text: 'Nhập',
          ),
          ActionItem(
            icon: Icons.bar_chart,
            text: 'Biến động',
          ),
          ActionItem(
            icon: Icons.label,
            text: 'Phân loại',
          ),
          ActionItem(
            icon: Icons.apps,
            text: 'Tiện ích',
          ),
        ],
      ),
    );
  }
}

class ActionItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const ActionItem({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Color(0xFFE0F2F1),
          child: Icon(
            icon,
            color: Colors.teal,
            size: 26,
          ),
        ),
        SizedBox(height: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF444444),
          ),
        ),
      ],
    );
  }
}