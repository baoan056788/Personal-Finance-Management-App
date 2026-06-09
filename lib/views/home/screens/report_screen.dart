import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../wallet/services/transaction_service.dart';
import '../../../models/transaction_model.dart';
import '../../../models/category_model.dart';
import '../../../controllers/category_controller.dart';
import 'transaction_detail_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String _timePeriod = 'Theo tuần';
  String _reportType = 'Chi tiêu';
  final bool _compareWithPrevious = false;

  final Color momoPink = const Color(0xFFE0248A);
  final Color momoLightPink = const Color(0xFFFFF0F6);
  final Color lightBlue = const Color(0xFF90CAF9);
  final Color darkBlue = const Color(0xFF2196F3);
  final Color lightPinkChart = const Color(0xFFFFCDD2);

  final TransactionService _transactionService = TransactionService();
  final CategoryController _categoryController = CategoryController();
  List<CategoryModel> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await _categoryController.getAllCategories();
    if (mounted) setState(() => _categories = cats);
  }

  CategoryModel? _findCategory(String? id, String? name) {
    String? targetId = id;
    if ((targetId == null || targetId.isEmpty) && name != null && !name.contains(' ') && name.length > 15) {
      targetId = name;
    }

    if (targetId != null && targetId.isNotEmpty) {
      try {
        return _categories.firstWhere((c) => c.id == targetId);
      } catch (_) {}
    }
    if (name != null && name.isNotEmpty) {
      final lc = name.toLowerCase().trim();
      try {
        return _categories.firstWhere((c) => c.name.toLowerCase().trim() == lc);
      } catch (_) {}
      
      try {
        return _categories.firstWhere((c) {
          final cName = c.name.toLowerCase();
          if (lc.contains(cName) || cName.contains(lc)) return true;
          if (cName.contains("ăn") && (lc.contains("tra") || lc.contains("sua") || lc.contains("com") || lc.contains("food"))) return true;
          if ((cName.contains("hóa đơn") || cName.contains("bill")) && (lc.contains("nước") || lc.contains("điện") || lc.contains("wifi") || lc.contains("water"))) return true;
          return false;
        });
      } catch (_) {}
    }
    return null;
  }

  String _getCategoryDisplayName(String? id, String name) {
    final cat = _findCategory(id, name);
    if (cat != null) return cat.name;
    if (!name.contains(' ') && name.length > 15) return "Khác";
    return name;
  }

  Widget _categoryIcon(String? id, String name) {
    final cat = _findCategory(id, name);
    if (cat != null) {
      try {
        final hex = cat.colorHex.replaceFirst('#', '');
        final color = Color(int.parse(hex, radix: 16));
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Icon(IconData(int.parse(cat.iconCode, radix: 16), fontFamily: 'MaterialIcons'), color: color, size: 20),
        );
      } catch (_) {}
    }
    return CircleAvatar(
      backgroundColor: _reportType == 'Chi tiêu' ? const Color(0xFFFFE0F1) : const Color(0xFFE0F7FA),
      child: Icon(_reportType == 'Chi tiêu' ? Icons.shopping_bag : Icons.account_balance_wallet, 
                  color: _reportType == 'Chi tiêu' ? Colors.pink : Colors.blue, size: 20),
    );
  }

  DateTime _getPreviousDate() {
    final now = DateTime.now();
    if (_timePeriod == 'Theo tuần') return now.subtract(const Duration(days: 7));
    if (_timePeriod == 'Theo tháng') return DateTime(now.year, now.month - 1, 1);
    return DateTime(now.year - 1, 1, 1);
  }

  List<double> _getGroupedData(List<TransactionModel> txs, DateTime targetDate) {
    List<double> buckets = [];
    if (_timePeriod == 'Theo tuần') {
      buckets = List.filled(7, 0.0);
      int currentWeekday = targetDate.weekday;
      DateTime startOfWeek = targetDate.subtract(Duration(days: currentWeekday - 1));
      DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
      
      for (var tx in txs) {
        if (tx.createdAt.isAfter(startOfWeek.subtract(const Duration(days: 1))) && 
            tx.createdAt.isBefore(endOfWeek.add(const Duration(days: 1)))) {
           if ((_reportType == 'Thu nhập' && tx.type == 'income') ||
               (_reportType == 'Chi tiêu' && tx.type == 'expense')) {
             buckets[tx.createdAt.weekday - 1] += tx.amount;
           } else if (_reportType == 'Chênh lệch') {
             buckets[tx.createdAt.weekday - 1] += (tx.type == 'income' ? tx.amount : -tx.amount);
           }
        }
      }
    } else if (_timePeriod == 'Theo tháng') {
      buckets = List.filled(5, 0.0);
      for (var tx in txs) {
        if (tx.createdAt.month == targetDate.month && tx.createdAt.year == targetDate.year) {
           int weekIndex = (tx.createdAt.day - 1) ~/ 7;
           if (weekIndex > 4) weekIndex = 4;
           if ((_reportType == 'Thu nhập' && tx.type == 'income') ||
               (_reportType == 'Chi tiêu' && tx.type == 'expense')) {
             buckets[weekIndex] += tx.amount;
           } else if (_reportType == 'Chênh lệch') {
             buckets[weekIndex] += (tx.type == 'income' ? tx.amount : -tx.amount);
           }
        }
      }
    } else { 
      buckets = List.filled(12, 0.0);
      for (var tx in txs) {
        if (tx.createdAt.year == targetDate.year) {
           if ((_reportType == 'Thu nhập' && tx.type == 'income') ||
               (_reportType == 'Chi tiêu' && tx.type == 'expense')) {
             buckets[tx.createdAt.month - 1] += tx.amount;
           } else if (_reportType == 'Chênh lệch') {
             buckets[tx.createdAt.month - 1] += (tx.type == 'income' ? tx.amount : -tx.amount);
           }
        }
      }
    }
    return buckets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FF),
      body: FutureBuilder<List<TransactionModel>>(
        future: _transactionService.getAllTransactionsGlobal(),
        builder: (context, snapshot) {
          if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final transactions = snapshot.data ?? [];
          List<double> currentData = _getGroupedData(transactions, DateTime.now());
          double totalForPeriod = currentData.fold(0, (sum, item) => sum + item);
          String displayAmount = '${NumberFormat('#,###').format(totalForPeriod)}đ';

          return Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                      child: Row(
                        children: [
                          _buildTimeTab('Theo tuần'),
                          _buildTimeTab('Theo tháng'),
                          _buildTimeTab('Theo năm'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
                child: Row(
                  children: [
                    _buildTypeTab('Thu nhập'),
                    _buildTypeTab('Chi tiêu'),
                    _buildTypeTab('Chênh lệch'),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        color: Colors.white,
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            Text('Tổng ${_reportType.toLowerCase()} ${_timePeriod.toLowerCase().replaceAll('theo ', '')} này', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                            const SizedBox(height: 8),
                            Text(displayAmount, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Biến động', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                            const Text('(Triệu)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            const SizedBox(height: 16),
                            SizedBox(height: 200, child: _buildChart(transactions)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        color: Colors.white,
                        child: Column(
                          children: [
                            if (_reportType != 'Chênh lệch') Container(
                              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE0248A), width: 2))),
                                      alignment: Alignment.center,
                                      child: const Text('Danh mục', style: TextStyle(color: Color(0xFFE0248A), fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!snapshot.hasData || snapshot.data!.isEmpty || totalForPeriod == 0)
                               const Padding(padding: EdgeInsets.all(32.0), child: Text('Chưa có giao dịch nào.', style: TextStyle(color: Colors.grey)))
                            else _buildListBottom(transactions),
                          ],
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildListBottom(List<TransactionModel> transactions) {
    if (_reportType == 'Chênh lệch') return const SizedBox.shrink();
    
    // Group transactions by category name
    Map<String, List<TransactionModel>> grouped = {}; 
    final now = DateTime.now();
    
    for (var tx in transactions) {
      bool inPeriod = false;
      if (_timePeriod == 'Theo tuần') {
        int currentWeekday = now.weekday;
        DateTime startOfWeek = now.subtract(Duration(days: currentWeekday - 1));
        DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
        if (tx.createdAt.isAfter(startOfWeek.subtract(const Duration(days: 1))) && tx.createdAt.isBefore(endOfWeek.add(const Duration(days: 1)))) {
          inPeriod = true;
        }
      } else if (_timePeriod == 'Theo tháng') {
        if (tx.createdAt.month == now.month && tx.createdAt.year == now.year) {
          inPeriod = true;
        }
      } else {
        if (tx.createdAt.year == now.year) {
          inPeriod = true;
        }
      }

      if (inPeriod) {
        if ((_reportType == 'Thu nhập' && tx.type == 'income') || (_reportType == 'Chi tiêu' && tx.type == 'expense')) {
          final realName = _getCategoryDisplayName(tx.categoryId, tx.category);
          grouped.putIfAbsent(realName, () => []).add(tx);
        }
      }
    }

    if (grouped.isEmpty) return const Padding(padding: EdgeInsets.all(32.0), child: Text('Chưa có giao dịch nào trong khoảng thời gian này.', style: TextStyle(color: Colors.grey)));

    var sortedEntries = grouped.entries.toList()..sort((a, b) {
      double totalA = a.value.fold(0, (sum, tx) => sum + tx.amount);
      double totalB = b.value.fold(0, (sum, tx) => sum + tx.amount);
      return totalB.compareTo(totalA);
    });
    
    return Column(
      children: sortedEntries.map((e) {
        final total = e.value.fold(0.0, (sum, tx) => sum + tx.amount);
        return ExpansionTile(
          leading: _categoryIcon(e.value.first.categoryId, e.key),
          title: Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          trailing: Text('${NumberFormat('#,###').format(total)}đ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          children: e.value.map((tx) => ListTile(
            dense: true,
            title: Text(tx.note.isNotEmpty ? tx.note : e.key),
            subtitle: Text(DateFormat('dd/MM/yyyy • HH:mm').format(tx.createdAt)),
            trailing: Text('${NumberFormat('#,###').format(tx.amount)}đ', style: const TextStyle(fontSize: 13)),
            onTap: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionDetailScreen(transaction: tx))).then((_) => setState(() {}));
            },
          )).toList(),
        );
      }).toList(),
    );
  }

  Widget _buildChart(List<TransactionModel> transactions) {
    List<double> currentData = _getGroupedData(transactions, DateTime.now());
    List<double> prevData = _compareWithPrevious ? _getGroupedData(transactions, _getPreviousDate()) : List.filled(currentData.length, 0.0);
    List<BarChartGroupData> groups = [];
    double maxVal = 0;
    
    for (int i=0; i<currentData.length; i++) {
      double c = currentData[i] / 1000000; 
      double p = prevData[i] / 1000000;
      if (c.abs() > maxVal) maxVal = c.abs();
      if (p.abs() > maxVal) maxVal = p.abs();
      if ((p+c).abs() > maxVal && _reportType != 'Chênh lệch') {
        maxVal = (p+c).abs();
      }
      if (_reportType == 'Chênh lệch') {
        groups.add(_makeDiffGroup(i, c));
      } else {
        groups.add(_makeStackedGroup(i, p, p + c));
      }
    }
    
    double maxY = maxVal > 0 ? (maxVal * 1.2) : 10.0;
    double minY = _reportType == 'Chênh lệch' ? -maxY : 0;

    return BarChart(BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxY, minY: minY,
      barTouchData: BarTouchData(enabled: true),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (double value, TitleMeta meta) {
          int idx = value.toInt();
          String text = '';
          if (_timePeriod == 'Theo tuần') { List<String> days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN']; if (idx >= 0 && idx < 7) text = days[idx]; }
          else if (_timePeriod == 'Theo tháng') { if (idx >= 0 && idx < 5) text = 'Tuần ${idx + 1}'; }
          else { if (idx >= 0 && idx < 12) text = 'T${idx + 1}'; }
          return SideTitleWidget(meta: meta, child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 10)));
        })),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (value, meta) {
          if (value == 0) return const SizedBox.shrink();
          return Text(value.toStringAsFixed(1), style: const TextStyle(color: Colors.grey, fontSize: 10));
        })),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: FlGridData(show: true, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1), drawVerticalLine: false),
      borderData: FlBorderData(show: false),
      barGroups: groups,
    ));
  }

  BarChartGroupData _makeStackedGroup(int x, double y1, double y2) {
    double width = _timePeriod == 'Theo tuần' ? 20 : (_timePeriod == 'Theo năm' ? 12 : 28);
    return BarChartGroupData(x: x, barRods: [BarChartRodData(toY: y2, width: width, color: lightBlue, borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)), rodStackItems: [BarChartRodStackItem(0, y1, darkBlue), BarChartRodStackItem(y1, y2, lightBlue)])]);
  }

  BarChartGroupData _makeDiffGroup(int x, double y) {
    double width = _timePeriod == 'Theo tuần' ? 20 : (_timePeriod == 'Theo năm' ? 12 : 28);
    return BarChartGroupData(x: x, barRods: [BarChartRodData(toY: y, width: width, color: y >= 0 ? Colors.green.shade300 : lightPinkChart, borderRadius: BorderRadius.only(topLeft: Radius.circular(y >= 0 ? 4 : 0), topRight: Radius.circular(y >= 0 ? 4 : 0), bottomLeft: Radius.circular(y < 0 ? 4 : 0), bottomRight: Radius.circular(y < 0 ? 4 : 0)))]);
  }

  Widget _buildTimeTab(String title) {
    bool isSelected = _timePeriod == title;
    return Expanded(child: GestureDetector(onTap: () => setState(() => _timePeriod = title), child: Container(padding: const EdgeInsets.symmetric(vertical: 8), decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(8), boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : []), alignment: Alignment.center, child: Text(title, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? momoPink : Colors.black54)))));
  }

  Widget _buildTypeTab(String title) {
    bool isSelected = _reportType == title;
    return Expanded(child: GestureDetector(onTap: () => setState(() => _reportType = title), child: Container(padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isSelected ? momoPink : Colors.transparent, width: 2))), alignment: Alignment.center, child: Text(title, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? momoPink : Colors.grey.shade500)))));
  }
}
