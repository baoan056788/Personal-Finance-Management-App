import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/budget_model.dart';
import '../../../models/category_model.dart';
import '../../../controllers/budget_controller.dart';
import '../../../controllers/category_controller.dart';
import '../../budget/screens/budget_list_screen.dart';
import '../../budget/screens/budget_detail_screen.dart';

class BudgetSummaryWidget extends StatefulWidget {
  final Key? refreshKey;
  const BudgetSummaryWidget({super.key, this.refreshKey});

  @override
  State<BudgetSummaryWidget> createState() => _BudgetSummaryWidgetState();
}

class _BudgetSummaryWidgetState extends State<BudgetSummaryWidget> {
  final BudgetController _budgetController = BudgetController();
  final CategoryController _categoryController = CategoryController();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
  );
  final Color momoPink = const Color(0xFFE91E63);
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CategoryModel>>(
      future: _categoryController.getAllCategories(),
      builder: (context, categorySnapshot) {
        final categories = categorySnapshot.data ?? [];

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
              if ((now.isAfter(b.startDate) ||
                      now.isAtSameMomentAs(b.startDate)) &&
                  (now.isBefore(b.endDate) ||
                      now.isAtSameMomentAs(b.endDate))) {
                activeBudgets.add(b);
              }
            }

            if (!snapshot.hasData || activeBudgets.isEmpty) {
              return _buildEmptyState(context);
            }

            activeBudgets.sort(
              (a, b) => b.progressPercent.compareTo(a.progressPercent),
            );
            final displayBudgets = _isExpanded
                ? activeBudgets.take(3).toList()
                : activeBudgets.take(1).toList();
            final hasMore = activeBudgets.length > 1;

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ngân sách đang áp dụng',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BudgetListScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Xem tất cả',
                            style: TextStyle(
                              color: momoPink,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Column(
                      children: displayBudgets
                          .map((budget) => _buildBudgetItem(budget, categories))
                          .toList(),
                    ),
                  ),
                  if (hasMore)
                    InkWell(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.grey[100]!),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isExpanded ? 'Thu gọn' : 'Xem thêm',
                              style: TextStyle(
                                color: momoPink,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: momoPink,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBudgetItem(BudgetModel budget, List<CategoryModel> categories) {
    final isOverLimit = budget.spentAmount > budget.limitAmount;
    Color statusColor = Colors.green;
    if (budget.status == 'WARNING') {
      statusColor = Colors.orange;
    } else if (budget.status == 'DANGER') {
      statusColor = Colors.deepOrange;
    } else if (budget.status == 'OVER_LIMIT') {
      statusColor = Colors.red;
    }

    String statusText = 'An toàn';
    if (budget.status == 'WARNING') {
      statusText = 'Chú ý';
    } else if (budget.status == 'DANGER') {
      statusText = 'Nguy hiểm';
    } else if (budget.status == 'OVER_LIMIT') {
      statusText = 'Vượt mức';
    }

    final category = categories.firstWhere(
      (c) => c.id == budget.categoryId,
      orElse: () => CategoryModel(
        id: '',
        userId: '',
        name: '',
        type: '',
        iconCode: 'e84f',
        colorHex: 'FF9E9E9E',
        isDefault: false,
      ),
    );
    final IconData catIcon = IconData(
      int.parse(category.iconCode, radix: 16),
      fontFamily: 'MaterialIcons',
    );
    final Color catColor = Color(
      int.parse(category.colorHex.replaceFirst('#', ''), radix: 16),
    );

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(
      budget.endDate.year,
      budget.endDate.month,
      budget.endDate.day,
    );
    final int diff = target.difference(today).inDays;
    final int remainingDays = diff >= 0 ? diff + 1 : diff;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BudgetDetailScreen(budget: budget)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: catColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(catIcon, color: catColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_currencyFormat.format(budget.spentAmount)} / ${_currencyFormat.format(budget.limitAmount)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isOverLimit
                            ? 'Đã vượt ${_currencyFormat.format(budget.remainAmount.abs())}'
                            : 'Đã sử dụng ${(budget.progressPercent * 100).toStringAsFixed(0)}%',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (budget.progressPercent).clamp(0.0, 1.0),
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  diff >= 0 ? 'Còn $remainingDays ngày' : 'Quá hạn',
                  style: TextStyle(
                    color: diff < 0 ? Colors.red : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ngân sách đang áp dụng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
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
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 16),
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
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
