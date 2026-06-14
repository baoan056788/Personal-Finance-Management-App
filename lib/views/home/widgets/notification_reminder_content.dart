import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/debt_model.dart';
import '../../../models/recurring_transaction_model.dart';
import '../../../models/system_notification_model.dart';

class NotificationReminderContent extends StatelessWidget {
  final List<SystemNotificationModel> systemNotifications;
  final List<DebtModel> debts;
  final List<RecurringTransactionModel> recurring;
  final bool constrainHeight;

  const NotificationReminderContent({
    super.key,
    required this.systemNotifications,
    required this.debts,
    required this.recurring,
    this.constrainHeight = true,
  });

  String _formatMoney(double amount) {
    return '${NumberFormat('#,###', 'vi_VN').format(amount)}đ';
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _timingText(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(date.year, date.month, date.day);
    final days = due.difference(today).inDays;
    if (days < 0) return 'Quá hạn ${days.abs()} ngày';
    if (days == 0) return 'Đến hạn hôm nay';
    if (days == 1) return 'Còn 1 ngày';
    return 'Còn $days ngày';
  }

  String _frequencyLabel(String frequency) {
    switch (frequency.toLowerCase()) {
      case 'daily':
        return 'Hàng ngày';
      case 'weekly':
        return 'Hàng tuần';
      case 'monthly':
        return 'Hàng tháng';
      case 'yearly':
        return 'Hàng năm';
      default:
        return frequency;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (systemNotifications.isEmpty && debts.isEmpty && recurring.isEmpty) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 8),
          Icon(Icons.notifications_none, size: 56, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'Chưa có thông báo mới',
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),
        ],
      );
    }

    final content = SizedBox(
      width: double.maxFinite,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (systemNotifications.isNotEmpty) ...[
            const Text(
              'Thông báo hệ thống',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...systemNotifications.map(
              (notification) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F6BED).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF4F6BED).withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(0xFFE9EDFF),
                      child: Icon(
                        Icons.campaign_outlined,
                        color: Color(0xFF4F6BED),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            notification.message,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Hiệu lực đến ${_formatDate(notification.expiresAt)}',
                            style: const TextStyle(
                              color: Color(0xFF4F6BED),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (debts.isNotEmpty) ...[
            if (systemNotifications.isNotEmpty) const SizedBox(height: 8),
            const Text(
              'Công nợ đến hạn',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...debts.map((debt) {
              final isOverdue = debt.status == 'OVERDUE';
              return _ReminderCard(
                icon: debt.type == 'borrowed'
                    ? Icons.call_received
                    : Icons.call_made,
                title: debt.personName,
                typeLabel: debt.type == 'borrowed'
                    ? 'Đi vay • Cần trả'
                    : 'Cho vay • Cần thu',
                amount: _formatMoney(debt.remainAmount),
                dueDate: 'Hạn ${_formatDate(debt.dueDate)}',
                timing: _timingText(debt.dueDate),
                note: debt.note,
                color: isOverdue ? Colors.red : Colors.orange,
              );
            }),
          ],
          if (recurring.isNotEmpty) ...[
            if (debts.isNotEmpty) const SizedBox(height: 16),
            const Text(
              'Giao dịch định kỳ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...recurring.map((transaction) {
              final isIncome = transaction.type == 'income';
              final timing = _timingText(transaction.nextDueDate);
              final isOverdue = timing.startsWith('Quá hạn');
              return _ReminderCard(
                icon: isIncome
                    ? Icons.south_west_rounded
                    : Icons.north_east_rounded,
                title: transaction.name,
                typeLabel: isIncome ? 'Khoản thu định kỳ' : 'Khoản chi định kỳ',
                amount:
                    '${isIncome ? '+' : '-'}${_formatMoney(transaction.amount)}',
                dueDate: 'Hạn ${_formatDate(transaction.nextDueDate)}',
                timing: timing,
                note: 'Tần suất: ${_frequencyLabel(transaction.frequency)}',
                color: isOverdue
                    ? Colors.red
                    : (isIncome ? Colors.green : Colors.purple),
              );
            }),
          ],
        ],
      ),
    );

    if (!constrainHeight) return content;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.58,
      ),
      child: SingleChildScrollView(child: content),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String typeLabel;
  final String amount;
  final String dueDate;
  final String timing;
  final String note;
  final Color color;

  const _ReminderCard({
    required this.icon,
    required this.title,
    required this.typeLabel,
    required this.amount,
    required this.dueDate,
    required this.timing,
    this.note = '',
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  typeLabel,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        amount,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        timing,
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.event_outlined,
                      size: 14,
                      color: Colors.black45,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dueDate,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                if (note.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    note,
                    style: const TextStyle(color: Colors.black45, fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
