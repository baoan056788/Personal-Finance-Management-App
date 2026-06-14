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
    final actions = [
      _ActionData(
        icon: Icons.account_balance_wallet_rounded,
        label: 'Ví của tôi',
        color: const Color(0xFFE0248A),
        background: const Color(0xFFFFE4F1),
        onTap: onInput,
      ),
      _ActionData(
        icon: Icons.insights_rounded,
        label: 'Biến động',
        color: const Color(0xFF7C4DFF),
        background: const Color(0xFFF0EAFF),
        onTap: onReport,
      ),
      _ActionData(
        icon: Icons.receipt_long_rounded,
        label: 'Giao dịch',
        color: const Color(0xFF00A68A),
        background: const Color(0xFFE4F8F4),
        onTap: onCategory,
      ),
      _ActionData(
        icon: Icons.grid_view_rounded,
        label: 'Tiện ích',
        color: const Color(0xFFFF8A3D),
        background: const Color(0xFFFFF0E5),
        onTap: onUtility,
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
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
          const Text(
            'Truy cập nhanh',
            style: TextStyle(
              color: Color(0xFF332B31),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: actions
                .map((action) => Expanded(child: _ActionItem(data: action)))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ActionData {
  final IconData icon;
  final String label;
  final Color color;
  final Color background;
  final VoidCallback? onTap;

  const _ActionData({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
    this.onTap,
  });
}

class _ActionItem extends StatelessWidget {
  final _ActionData data;

  const _ActionItem({required this.data});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: data.background,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(data.icon, color: data.color, size: 24),
            ),
            const SizedBox(height: 9),
            Text(
              data.label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF51464D),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
