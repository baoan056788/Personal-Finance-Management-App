import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/budget_model.dart';
import '../../../controllers/budget_controller.dart';
import '../../budget/screens/budget_list_screen.dart';

class BudgetSummaryWidget extends StatefulWidget {
  final Key? refreshKey;
  const BudgetSummaryWidget({super.key, this.refreshKey});

  @override
  State<BudgetSummaryWidget> createState() => _BudgetSummaryWidgetState();
}

class _BudgetSummaryWidgetState extends State<BudgetSummaryWidget> {
  final BudgetController _budgetController = BudgetController();
  final Color momoPink = const Color(0xFFD82D8B);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BudgetModel>>(
      key: widget.refreshKey,
      stream: _budgetController.getBudgets(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Lỗi tải ngân sách: ${snapshot.error}');
        }

        final budgets = snapshot.data ?? [];
        final now = DateTime.now();
        List<BudgetModel> activeBudgets = [];

        for (var b in budgets) {
          if ((now.isAfter(b.startDate) || now.isAtSameMomentAs(b.startDate)) &&
              (now.isBefore(b.endDate) || now.isAtSameMomentAs(b.endDate))) {
            activeBudgets.add(b);
          }
        }

        if (!snapshot.hasData || activeBudgets.isEmpty) {
          return _buildEmptyState(context);
        }

        activeBudgets.sort((a, b) => b.limitAmount.compareTo(a.limitAmount));
        final displayBudgets = activeBudgets.take(3).toList();

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BudgetListScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Ngân sách tháng này',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    Text(
                      'Chi tiết',
                      style: TextStyle(
                        color: momoPink,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  children: displayBudgets.asMap().entries.map((entry) {
                    final index = entry.key;
                    final budget = entry.value;
                    return Column(
                      children: [
                        _buildBudgetItem(budget, context),
                        if (index < displayBudgets.length - 1) ...[
                          const SizedBox(height: 16),
                          Divider(height: 1, color: Colors.grey.shade200),
                          const SizedBox(height: 16),
                        ],
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBudgetItem(BudgetModel budget, BuildContext context) {
    Color statusColor = Colors.green;
    if (budget.status == 'WARNING') {
      statusColor = Colors.orange;
    } else if (budget.status == 'DANGER') {
      statusColor = Colors.deepOrange;
    } else if (budget.status == 'OVER_LIMIT') {
      statusColor = Colors.red;
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.pie_chart,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  budget.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            Text(
              '${(budget.progressPercent * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: statusColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: budget.progressPercent > 1.0 ? 1.0 : budget.progressPercent,
            backgroundColor: Colors.grey.shade200,
            color: statusColor,
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Đã chi',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '${NumberFormat('#,###').format(budget.spentAmount)}đ',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Còn lại',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '${NumberFormat('#,###').format(budget.remainAmount)}đ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: budget.remainAmount < 0 ? Colors.red : Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BudgetListScreen()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ngân sách tháng này',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                Text(
                  'Thiết lập',
                  style: TextStyle(
                    color: momoPink,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.pie_chart_outline,
                    size: 48,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Chưa có ngân sách hoạt động',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}