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
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  final Color momoPink = const Color(0xFFD82D8B);
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
          if ((now.isAfter(b.startDate) || now.isAtSameMomentAs(b.startDate)) &&
              (now.isBefore(b.endDate) || now.isAtSameMomentAs(b.endDate))) {
            activeBudgets.add(b);
          }
        }

        if (!snapshot.hasData || activeBudgets.isEmpty) {
          return _buildEmptyState(context);
        }

        activeBudgets.sort((a, b) => b.limitAmount.compareTo(a.limitAmount));
        final displayBudgets = _isExpanded ? activeBudgets.take(3).toList() : activeBudgets.take(1).toList();
        final hasMore = activeBudgets.length > 1;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha(20),
                blurRadius: 15,
                offset: const Offset(0, 5),
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
                      'Ngân sách tháng này',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetListScreen()));
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
                  children: displayBudgets.map((budget) => _buildBudgetItem(budget, categories)).toList(),
                ),
              ),
              if (hasMore)
                InkWell(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey[200]!)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_isExpanded ? 'Thu gọn' : 'Xem thêm', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        Icon(_isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey),
                      ],
                    ),
                  ),
                )
            ],
          ),
        );
      },
    );
  });
  }

  Widget _buildBudgetItem(BudgetModel budget, List<CategoryModel> categories) {
    Color statusColor = Colors.green;
    if (budget.status == 'WARNING') {
      statusColor = Colors.orange;
    } else if (budget.status == 'DANGER') {
      statusColor = Colors.deepOrange;
    } else if (budget.status == 'OVER_LIMIT') {
      statusColor = Colors.red;
    }

    final category = categories.firstWhere(
      (c) => c.id == budget.categoryId, 
      orElse: () => CategoryModel(id: '', userId: '', name: '', type: '', iconCode: 'e84f', colorHex: 'FF9E9E9E', isDefault: false)
    );
    final IconData catIcon = IconData(int.parse(category.iconCode, radix: 16), fontFamily: 'MaterialIcons');
    final Color catColor = Color(int.parse(category.colorHex.replaceFirst('#', ''), radix: 16));

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BudgetDetailScreen(budget: budget))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 50, height: 50,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: budget.progressPercent > 1.0 ? 1.0 : budget.progressPercent,
                    backgroundColor: Colors.grey[200],
                    color: statusColor,
                    strokeWidth: 5,
                  ),
                  Center(
                    child: Icon(
                      catIcon,
                      color: catColor,
                      size: 20,
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(budget.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('${_currencyFormat.format(budget.spentAmount)} / ${_currencyFormat.format(budget.limitAmount)}', style: TextStyle(color: Colors.grey[800], fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Còn ${_currencyFormat.format(budget.remainAmount)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      Text('${(budget.progressPercent * 100).toStringAsFixed(0)}%', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  )
                ],
              ),
            )
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(20),
              blurRadius: 15,
              offset: const Offset(0, 5),
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
                  'Ngân sách tháng này',
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