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
  final Color momoPink = const Color(0xFFE91E63);

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
  
  String get _statusText {
    if (_budget.status == 'WARNING') return 'Chú ý';
    if (_budget.status == 'DANGER') return 'Nguy hiểm';
    if (_budget.status == 'OVER_LIMIT') return 'Vượt mức';
    return 'An toàn';
  }

  Future<void> _deleteBudget() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xóa Ngân sách', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc chắn muốn xóa ngân sách này không? Việc này không thể hoàn tác.', style: TextStyle(fontSize: 15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), 
            child: const Text('Hủy', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Xóa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(_budget.endDate.year, _budget.endDate.month, _budget.endDate.day);
    final int diff = target.difference(today).inDays;
    final int remainingDays = diff >= 0 ? diff + 1 : diff;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshBudget,
              color: momoPink,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    expandedHeight: 120,
                    pinned: true,
                    backgroundColor: Colors.white,
                    elevation: 0.5,
                    leading: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 18),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    actions: [
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                          child: const Icon(Icons.edit_outlined, color: Colors.black87, size: 20),
                        ),
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
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                          child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        ),
                        onPressed: _deleteBudget,
                      ),
                      const SizedBox(width: 8),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.only(left: 24, bottom: 16, right: 24),
                      title: Text(
                        _budget.name,
                        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 20),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 20, offset: const Offset(0, 10))],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _statusColor.withAlpha(20),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.fiber_manual_record, size: 10, color: _statusColor),
                                          const SizedBox(width: 6),
                                          Text(_statusText, style: TextStyle(color: _statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                                          const SizedBox(width: 6),
                                          Text(
                                            diff >= 0 ? 'Còn $remainingDays ngày' : 'Đã quá hạn', 
                                            style: TextStyle(color: diff < 0 ? Colors.red : Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 12)
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 32),
                                SizedBox(
                                  height: 240,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      PieChart(
                                        PieChartData(
                                          sectionsSpace: 0,
                                          centerSpaceRadius: 85,
                                          startDegreeOffset: 270,
                                          sections: [
                                            PieChartSectionData(
                                              color: _statusColor,
                                              value: _budget.spentAmount > 0 ? _budget.spentAmount : 0.01,
                                              title: '',
                                              radius: 18,
                                            ),
                                            PieChartSectionData(
                                              color: Colors.grey.shade100,
                                              value: _budget.limitAmount > _budget.spentAmount ? (_budget.limitAmount - _budget.spentAmount) : 0,
                                              title: '',
                                              radius: 18,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text('Đã chi tiêu', style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500)),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${(_budget.progressPercent * 100).toStringAsFixed(1)}%',
                                            style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: _statusColor, height: 1),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 32),
                                Text(
                                  '${DateFormat('dd/MM/yyyy').format(_budget.startDate)} - ${DateFormat('dd/MM/yyyy').format(_budget.endDate)}',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 20, offset: const Offset(0, 10))],
                            ),
                            child: Column(
                              children: [
                                _buildDetailRow(
                                  icon: Icons.account_balance_wallet,
                                  iconColor: Colors.blue,
                                  label: 'Giới hạn', 
                                  value: '${NumberFormat('#,###').format(_budget.limitAmount)}đ', 
                                  valueColor: Colors.black87
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Divider(height: 1, color: Colors.grey.shade100),
                                ),
                                _buildDetailRow(
                                  icon: Icons.shopping_bag,
                                  iconColor: Colors.orange,
                                  label: 'Đã chi', 
                                  value: '${NumberFormat('#,###').format(_budget.spentAmount)}đ', 
                                  valueColor: Colors.black87
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Divider(height: 1, color: Colors.grey.shade100),
                                ),
                                _buildDetailRow(
                                  icon: overLimit ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                                  iconColor: overLimit ? Colors.red : Colors.green,
                                  label: overLimit ? 'Vượt mức' : 'Còn lại', 
                                  value: '${NumberFormat('#,###').format(_budget.remainAmount.abs())}đ', 
                                  valueColor: overLimit ? Colors.red : Colors.green
                                ),
                              ],
                            ),
                          ),
                          
                          if (_budget.note.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 20, offset: const Offset(0, 10))],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.notes, size: 20, color: momoPink),
                                      const SizedBox(width: 8),
                                      const Text('Ghi chú', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(_budget.note, style: TextStyle(fontSize: 15, color: Colors.grey.shade700, height: 1.5)),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow({required IconData icon, required Color iconColor, required String label, required String value, required Color valueColor}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: valueColor)),
      ],
    );
  }
}
