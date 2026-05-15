import 'package:flutter/material.dart';

class QuickActionsWidget extends StatelessWidget {
  final VoidCallback? onInput;
  final VoidCallback? onReport;
  final VoidCallback? onCategory;
  final VoidCallback? onUtility;

  const QuickActionsWidget({
    super.key,
    this.onInput,
    this.onReport,
    this.onCategory,
    this.onUtility,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          ActionItem(
            icon: Icons.add_circle_outline,
            text: 'Nhập',
            onTap: onInput ?? () {},
          ),
          ActionItem(
            icon: Icons.bar_chart,
            text: 'Biến động',
            onTap: onReport ?? () {},
          ),
          ActionItem(
            icon: Icons.label_outline,
            text: 'Phân loại',
            onTap: onCategory ?? () {},
          ),
          ActionItem(
            icon: Icons.apps,
            text: 'Tiện ích',
            onTap: onUtility ?? () {},
          ),
        ],
      ),
    );
  }
}

class ActionItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const ActionItem({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFE0F2F1),
              child: Icon(
                icon,
                color: Colors.teal,
                size: 26,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF444444),
              ),
            ),
          ],
        ),
      ),
    );
  }
}