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
  final Color momoPink = const Color(0xFFD82D8B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Quản lý Ngân sách', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
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
            return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          final budgets = snapshot.data ?? [];
          if (budgets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('Bạn chưa có ngân sách nào', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateBudgetScreen())),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: momoPink,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Tạo Ngân Sách Mới', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: budgets.length,
            itemBuilder: (context, index) {
              final budget = budgets[index];
              return _buildBudgetCard(budget, categories);
            },
          );
        },
      );
      }),
      floatingActionButton: FloatingActionButton(
        backgroundColor: momoPink,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateBudgetScreen())),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBudgetCard(BudgetModel budget, List<CategoryModel> categories) {
    Color statusColor = Colors.green;
    if (budget.status == 'WARNING') {
      statusColor = Colors.orange;
    } else if (budget.status == 'DANGER') {
      statusColor = Colors.deepOrange;
    } else if (budget.status == 'OVER_LIMIT') {
      statusColor = Colors.red;
    }

    String statusText = '';
    if (budget.status == 'WARNING') {
      statusText = 'Chú ý';
    } else if (budget.status == 'DANGER') {
      statusText = 'Nguy hiểm';
    } else if (budget.status == 'OVER_LIMIT') {
      statusText = 'Vượt hạn mức';
    } else {
      statusText = 'An toàn';
    }

    final category = categories.firstWhere(
      (c) => c.id == budget.categoryId, 
      orElse: () => CategoryModel(id: '', userId: '', name: '', type: '', iconCode: 'e84f', colorHex: 'FF9E9E9E', isDefault: false)
    );
    final IconData catIcon = IconData(int.parse(category.iconCode, radix: 16), fontFamily: 'MaterialIcons');
    final Color catColor = Color(int.parse(category.colorHex.replaceFirst('#', ''), radix: 16));

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => BudgetDetailScreen(budget: budget)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: budget.progressPercent > 1.0 ? 1.0 : budget.progressPercent,
                    backgroundColor: Colors.grey[200],
                    color: statusColor,
                    strokeWidth: 6,
                  ),
                  Center(
                    child: Icon(
                      catIcon,
                      color: catColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          budget.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${NumberFormat('#,###').format(budget.spentAmount)}đ / ${NumberFormat('#,###').format(budget.limitAmount)}đ',
                    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(budget.progressPercent * 100).toStringAsFixed(1)}%',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      Text(
                        'Hạn: ${DateFormat('dd/MM/yyyy').format(budget.endDate)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
