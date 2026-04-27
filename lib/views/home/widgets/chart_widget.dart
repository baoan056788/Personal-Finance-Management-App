import 'package:flutter/material.dart';

class ChartWidget extends StatelessWidget {
  const ChartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 230,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: Text(
          'Biểu đồ sẽ thêm sau',
          style: TextStyle(
            fontSize: 15,
            color: Color(0xFF444444),
          ),
        ),
      ),
    );
  }
}