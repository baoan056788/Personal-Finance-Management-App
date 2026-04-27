import 'package:flutter/material.dart';

class BudgetWidget extends StatelessWidget {
  const BudgetWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ngân sách',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        SizedBox(height: 14),
        SizedBox(
          height: 150,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                BudgetCard(title: 'Ăn uống'),
                SizedBox(width: 14),
                BudgetCard(title: 'Mua sắm'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class BudgetCard extends StatelessWidget {
  final String title;

  const BudgetCard({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF444444),
          ),
        ),
      ),
    );
  }
}