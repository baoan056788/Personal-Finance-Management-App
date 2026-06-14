import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../wallet/services/transaction_service.dart';

class SummaryWidget extends StatelessWidget {
  const SummaryWidget({super.key});

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return StreamBuilder<Map<String, double>>(
      stream: TransactionService().watchMonthlyTotal(now.month, now.year),
      builder: (context, snapshot) {
        final income = snapshot.data?['income'] ?? 0;
        final expense = snapshot.data?['expense'] ?? 0;
        final difference = income - expense;
        final loading = snapshot.connectionState == ConnectionState.waiting;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFF3EAF0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8C5A76).withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE4F1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: Color(0xFFE0248A),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tổng quan tháng này',
                          style: TextStyle(
                            color: Color(0xFF332B31),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Không bao gồm chuyển tiền giữa các ví',
                          style: TextStyle(color: Colors.black38, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _SummaryItem(
                      title: 'Thu nhập',
                      amount: loading ? '...' : _formatCurrency(income),
                      icon: Icons.south_west_rounded,
                      color: const Color(0xFF35A853),
                      background: const Color(0xFFEAF7EE),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryItem(
                      title: 'Chi tiêu',
                      amount: loading ? '...' : _formatCurrency(expense),
                      icon: Icons.north_east_rounded,
                      color: const Color(0xFFFF5252),
                      background: const Color(0xFFFFECEA),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4FA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      difference >= 0
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: difference >= 0
                          ? const Color(0xFF35A853)
                          : const Color(0xFFFF5252),
                      size: 21,
                    ),
                    const SizedBox(width: 9),
                    const Expanded(
                      child: Text(
                        'Chênh lệch thu chi',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      loading ? '...' : _formatCurrency(difference),
                      style: TextStyle(
                        color: difference >= 0
                            ? const Color(0xFF35A853)
                            : const Color(0xFFFF5252),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;
  final Color color;
  final Color background;

  const _SummaryItem({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(color: Colors.black45, fontSize: 12),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
