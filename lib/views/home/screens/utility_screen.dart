import 'package:flutter/material.dart';

class UtilityScreen extends StatelessWidget {
  const UtilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Tiện ích',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}