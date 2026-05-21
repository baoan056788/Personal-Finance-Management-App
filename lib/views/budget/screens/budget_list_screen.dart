import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/budget_model.dart';
import '../../../controllers/budget_controller.dart';
import 'create_budget_screen.dart';
import 'budget_detail_screen.dart';

class BudgetListScreen extends StatefulWidget {
  const BudgetListScreen({super.key});

  @override
  State<BudgetListScreen> createState() => _BudgetListScreenState();
}

class _BudgetListScreenState extends State<BudgetListScreen> {
  final BudgetController _budgetController = BudgetController();
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
      body: StreamBuilder<List<BudgetModel>>(
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
              return _buildBudgetCard(budget);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: momoPink,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateBudgetScreen())),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBudgetCard(BudgetModel budget) {
    Color statusColor = Colors.green;
    if (budget.status == 'WARNING') {
      statusColor = Colors.orange;
    } else if (budget.status == 'DANGER') {
      statusColor = Colors.deepOrange;
    } else if (budget.status == 'OVER_LIMIT') {
      statusColor = Colors.red;
    }

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
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                      child: Icon(Icons.pie_chart, color: statusColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      budget.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                    ),
                  ],
                ),
                Text(
                  '${(budget.progressPercent * 100).toStringAsFixed(1)}%',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: statusColor),
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
                    const Text('Đã chi', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(
                      '${NumberFormat('#,###').format(budget.spentAmount)}đ',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Còn lại', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(
                      '${NumberFormat('#,###').format(budget.remainAmount)}đ',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: budget.remainAmount < 0 ? Colors.red : Colors.black87),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${DateFormat('dd/MM').format(budget.startDate)} - ${DateFormat('dd/MM').format(budget.endDate)}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
