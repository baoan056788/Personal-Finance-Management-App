import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/budget_model.dart';
import '../../../controllers/budget_controller.dart';
import 'edit_budget_screen.dart';

class BudgetDetailScreen extends StatefulWidget {
  final BudgetModel budget;

  const BudgetDetailScreen({super.key, required this.budget});

  @override
  State<BudgetDetailScreen> createState() => _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends State<BudgetDetailScreen> {
  final BudgetController _budgetController = BudgetController();
  late BudgetModel _budget;
  bool _isLoading = false;
  final Color momoPink = const Color(0xFFD82D8B);

  @override
  void initState() {
    super.initState();
    _budget = widget.budget;
  }
  
  Future<void> _refreshBudget() async {
    final refreshed = await _budgetController.getBudgetById(_budget.id);
    if (refreshed != null && mounted) {
      setState(() => _budget = refreshed);
    }
  }
  
  Color get _statusColor {
    if (_budget.status == 'WARNING') return Colors.orange;
    if (_budget.status == 'DANGER') return Colors.deepOrange;
    if (_budget.status == 'OVER_LIMIT') return Colors.red;
    return Colors.green;
  }

  Future<void> _deleteBudget() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa Ngân sách'),
        content: const Text('Bạn có chắc chắn muốn xóa ngân sách này không? Việc này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _budgetController.deleteBudget(_budget.id);
        if (!mounted) return;
        Navigator.pop(context); // Go back to list
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa ngân sách'), backgroundColor: Colors.green));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final overLimit = _budget.spentAmount > _budget.limitAmount;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Chi tiết Ngân sách', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.black87),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EditBudgetScreen(budget: _budget)),
              );
              if (result == true) {
                _refreshBudget();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _deleteBudget,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshBudget,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      color: Colors.white,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(Icons.account_balance_wallet, size: 48, color: _statusColor),
                          const SizedBox(height: 16),
                          Text(_budget.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${DateFormat('dd/MM/yyyy').format(_budget.startDate)} - ${DateFormat('dd/MM/yyyy').format(_budget.endDate)}',
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Circular Progress logic here using pie chart
                          SizedBox(
                            height: 200,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                PieChart(
                                  PieChartData(
                                    sectionsSpace: 0,
                                    centerSpaceRadius: 70,
                                    startDegreeOffset: 270,
                                    sections: [
                                      PieChartSectionData(
                                        color: _statusColor,
                                        value: _budget.spentAmount > 0 ? _budget.spentAmount : 0.01,
                                        title: '',
                                        radius: 12,
                                      ),
                                      PieChartSectionData(
                                        color: Colors.grey.shade200,
                                        value: _budget.limitAmount > _budget.spentAmount ? (_budget.limitAmount - _budget.spentAmount) : 0,
                                        title: '',
                                        radius: 12,
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${(_budget.progressPercent * 100).toStringAsFixed(1)}%',
                                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _statusColor),
                                    ),
                                    const Text(
                                      'Đã dùng',
                                      style: TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          _buildDetailRow('Giới hạn', '${NumberFormat('#,###').format(_budget.limitAmount)}đ', Colors.black87),
                          const Divider(height: 32),
                          _buildDetailRow('Đã chi', '${NumberFormat('#,###').format(_budget.spentAmount)}đ', Colors.black87),
                          const Divider(height: 32),
                          _buildDetailRow(overLimit ? 'Vượt mức' : 'Còn lại', 
                            '${NumberFormat('#,###').format(_budget.remainAmount.abs())}đ', 
                            overLimit ? Colors.red : Colors.green),
                        ],
                      ),
                    ),
                    if (_budget.note.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        color: Colors.white,
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Ghi chú', style: TextStyle(color: Colors.grey, fontSize: 14)),
                            const SizedBox(height: 8),
                            Text(_budget.note, style: const TextStyle(fontSize: 16, color: Colors.black87)),
                          ],
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: valueColor)),
      ],
    );
  }
}
