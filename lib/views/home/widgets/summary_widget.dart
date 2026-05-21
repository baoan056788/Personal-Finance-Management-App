import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../wallet/services/transaction_service.dart';

class SummaryWidget extends StatelessWidget {
  const SummaryWidget({super.key});

  String _formatCurrency(double amount) {
    final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    return formatCurrency.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return FutureBuilder<Map<String, double>>(
      // Use the centralized service method to ensure data sync
      future: TransactionService().getMonthlyTotal(now.month, now.year),
      builder: (context, snapshot) {
        double totalIncome = 0;
        double totalExpense = 0;

        if (snapshot.hasData) {
          totalIncome = snapshot.data!['income'] ?? 0;
          totalExpense = snapshot.data!['expense'] ?? 0;
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            children: [
              const Text(
                'Tháng hiện tại',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: SummaryCard(
                      title: 'Chi tiêu',
                      amount: snapshot.connectionState == ConnectionState.waiting ? '...' : _formatCurrency(totalExpense),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SummaryCard(
                      title: 'Thu nhập',
                      amount: snapshot.connectionState == ConnectionState.waiting ? '...' : _formatCurrency(totalIncome),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String title;
  final String amount;

  const SummaryCard({
    super.key,
    required this.title,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFE0248A), // Use consistent Momo Pink
          width: 1.2,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              amount,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }
}