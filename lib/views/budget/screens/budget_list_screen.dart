import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/budget_model.dart';
import '../../../models/category_model.dart';
import '../../../controllers/budget_controller.dart';
import '../../../controllers/category_controller.dart';
import 'create_budget_screen.dart';
import 'budget_detail_screen.dart';

class BudgetListScreen extends StatefulWidget {
  const BudgetListScreen({super.key});

  @override
  State<BudgetListScreen> createState() => _BudgetListScreenState();
}

class _BudgetListScreenState extends State<BudgetListScreen> {
  final BudgetController _budgetController = BudgetController();
  final CategoryController _categoryController = CategoryController();
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  bool _isFabPressed = false;
  
  void _sortBudgets(List<BudgetModel> budgets) {
    budgets.sort((a, b) {
      return b.progressPercent.compareTo(a.progressPercent);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Quản lý Ngân sách', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: FutureBuilder<List<CategoryModel>>(
        future: _categoryController.getAllCategories(),
        builder: (context, categorySnapshot) {
          final categories = categorySnapshot.data ?? [];
          
          return StreamBuilder<List<BudgetModel>>(
            stream: _budgetController.getBudgets(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Đã xảy ra lỗi khi tải dữ liệu.'));
              }
              
              final allBudgets = snapshot.data ?? [];
              final now = DateTime.now();
              
              List<BudgetModel> activeBudgets = [];
              for (var b in allBudgets) {
                if ((now.isAfter(b.startDate) || now.isAtSameMomentAs(b.startDate)) &&
                    (now.isBefore(b.endDate) || now.isAtSameMomentAs(b.endDate))) {
                  activeBudgets.add(b);
                }
              }
              
              if (allBudgets.isEmpty) {
                return _buildEmptyState();
              }

              _sortBudgets(allBudgets);

              double totalBudget = activeBudgets.fold(0, (sum, item) => sum + item.limitAmount);
              double totalSpent = activeBudgets.fold(0, (sum, item) => sum + item.spentAmount);
              double avgProgress = totalBudget > 0 ? totalSpent / totalBudget : 0;

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeaderCard(totalBudget, totalSpent, activeBudgets.length, avgProgress),
                          const SizedBox(height: 24),
                          const Text(
                            'Tất cả ngân sách',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 16),
                          ...allBudgets.map((budget) {
                            final category = categories.firstWhere(
                              (c) => c.id == budget.categoryId, 
                              orElse: () => CategoryModel(id: '', userId: '', name: '', type: '', iconCode: 'e84f', colorHex: 'FF9E9E9E', isDefault: false)
                            );
                            return _buildBudgetCard(budget, category);
                          }),
                          const SizedBox(height: 80), // FAB spacer
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildHeaderCard(double totalBudget, double totalSpent, int activeCount, double avgProgress) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE91E63), Color(0xFF880E4F)], // Magenta gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF880E4F).withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withAlpha(50), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Tổng ngân sách đang áp dụng',
                  style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _currencyFormat.format(totalBudget),
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.white.withAlpha(25), borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Đã chi', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(_currencyFormat.format(totalSpent), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(width: 1, height: 30, color: Colors.white.withAlpha(50)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Tiến độ', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('${(avgProgress * 100).toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF80AB), Color(0xFFC2185B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: const Color(0xFFC2185B).withAlpha(50), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: const Icon(Icons.account_balance_wallet_outlined, size: 80, color: Colors.white),
          ),
          const SizedBox(height: 24),
          const Text(
            'Chưa có ngân sách nào',
            style: TextStyle(fontSize: 22, color: Colors.black87, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Tạo ngân sách để quản lý chi tiêu hiệu quả hơn và không bị vượt hạn mức.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateBudgetScreen())),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC2185B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              elevation: 4,
            ),
            child: const Text('Tạo Ngân Sách Ngay', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildBudgetCard(BudgetModel budget, CategoryModel category) {
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

    final Color catColor = Color(int.parse(category.colorHex.replaceFirst('#', ''), radix: 16));
    final IconData catIcon = IconData(int.parse(category.iconCode, radix: 16), fontFamily: 'MaterialIcons');
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(budget.endDate.year, budget.endDate.month, budget.endDate.day);
    final int diff = target.difference(today).inDays;
    final int remainingDays = diff >= 0 ? diff + 1 : diff;

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => BudgetDetailScreen(budget: budget)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
          children: [
            Row(
              children: [
                Container(
                  width: 54, height: 54,
                  decoration: BoxDecoration(
                    color: catColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(catIcon, color: catColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _currencyFormat.format(budget.spentAmount),
                  style: TextStyle(color: statusColor, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  _currencyFormat.format(budget.limitAmount),
                  style: const TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (budget.progressPercent).clamp(0.0, 1.0),
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(budget.progressPercent * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    const Icon(Icons.date_range_rounded, size: 14, color: Colors.black54),
                    const SizedBox(width: 4),
                    Text(
                      diff >= 0 ? 'Còn $remainingDays ngày' : 'Quá hạn',
                      style: TextStyle(color: diff < 0 ? Colors.red : Colors.black54, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isFabPressed = true),
      onTapUp: (_) {
        setState(() => _isFabPressed = false);
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateBudgetScreen()));
      },
      onTapCancel: () => setState(() => _isFabPressed = false),
      child: AnimatedScale(
        scale: _isFabPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE91E63), Color(0xFF880E4F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE91E63).withAlpha(80),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 32),
        ),
      ),
    );
  }
}
