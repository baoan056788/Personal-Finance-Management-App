import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../controllers/category_controller.dart';
import '../../../models/category_model.dart';
import '../../../models/transaction_model.dart';
import '../../wallet/services/transaction_service.dart';
import 'transaction_detail_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  static const Color _primaryPink = Color(0xFFE0248A);
  static const Color _darkPink = Color(0xFFB02A76);
  static const Color _pageBackground = Color(0xFFFFF7FF);

  final TransactionService _transactionService = TransactionService();
  final CategoryController _categoryController = CategoryController();
  final NumberFormat _currency = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  late final Stream<List<TransactionModel>> _transactionsStream;
  List<CategoryModel> _categories = [];
  String _timePeriod = 'Theo tuần';
  String _reportType = 'Chi tiêu';

  @override
  void initState() {
    super.initState();
    _transactionsStream = _transactionService.watchAllTransactionsGlobal();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await _categoryController.getAllCategories();
    if (mounted) setState(() => _categories = categories);
  }

  Future<void> _refresh() async {
    await Future.wait([
      _transactionService.getAllTransactionsGlobal(),
      _loadCategories(),
    ]);
  }

  CategoryModel? _findCategory(String? id, String? name) {
    String? targetId = id;
    if ((targetId == null || targetId.isEmpty) &&
        name != null &&
        !name.contains(' ') &&
        name.length > 15) {
      targetId = name;
    }

    if (targetId != null && targetId.isNotEmpty) {
      for (final category in _categories) {
        if (category.id == targetId) return category;
      }
    }

    final normalizedName = name?.toLowerCase().trim();
    if (normalizedName == null || normalizedName.isEmpty) return null;
    for (final category in _categories) {
      if (category.name.toLowerCase().trim() == normalizedName) {
        return category;
      }
    }
    return null;
  }

  String _categoryName(TransactionModel transaction) {
    final category = _findCategory(
      transaction.categoryId,
      transaction.category,
    );
    if (category != null) return category.name;
    if (!transaction.category.contains(' ') &&
        transaction.category.length > 15) {
      return 'Khác';
    }
    return transaction.category.isEmpty ? 'Khác' : transaction.category;
  }

  bool _isInPeriod(DateTime date, DateTime target) {
    if (_timePeriod == 'Theo tuần') {
      final start = DateTime(
        target.year,
        target.month,
        target.day,
      ).subtract(Duration(days: target.weekday - 1));
      final end = start.add(const Duration(days: 7));
      return !date.isBefore(start) && date.isBefore(end);
    }
    if (_timePeriod == 'Theo tháng') {
      return date.year == target.year && date.month == target.month;
    }
    return date.year == target.year;
  }

  bool _matchesReportType(TransactionModel transaction) {
    if (_reportType == 'Thu nhập') return transaction.isIncome;
    if (_reportType == 'Chi tiêu') return transaction.isExpense;
    return transaction.isIncome || transaction.isExpense;
  }

  List<double> _groupedData(
    List<TransactionModel> transactions,
    DateTime target,
  ) {
    final bucketCount = switch (_timePeriod) {
      'Theo tuần' => 7,
      'Theo tháng' => 5,
      _ => 12,
    };
    final buckets = List<double>.filled(bucketCount, 0);

    for (final transaction in transactions) {
      if (!_isInPeriod(transaction.createdAt, target)) continue;

      final value = switch (_reportType) {
        'Thu nhập' when transaction.isIncome => transaction.amount,
        'Chi tiêu' when transaction.isExpense => transaction.amount,
        'Chênh lệch' => transaction.reportImpact,
        _ => 0.0,
      };
      if (value == 0) continue;

      final index = switch (_timePeriod) {
        'Theo tuần' => transaction.createdAt.weekday - 1,
        'Theo tháng' => ((transaction.createdAt.day - 1) ~/ 7).clamp(0, 4),
        _ => transaction.createdAt.month - 1,
      };
      buckets[index] += value;
    }
    return buckets;
  }

  Color get _reportColor => switch (_reportType) {
    'Thu nhập' => const Color(0xFF35A853),
    'Chi tiêu' => const Color(0xFFFF5252),
    _ => const Color(0xFF7C4DFF),
  };

  Color get _reportBackground => switch (_reportType) {
    'Thu nhập' => const Color(0xFFEAF7EE),
    'Chi tiêu' => const Color(0xFFFFECEA),
    _ => const Color(0xFFF0EAFF),
  };

  IconData get _reportIcon => switch (_reportType) {
    'Thu nhập' => Icons.south_west_rounded,
    'Chi tiêu' => Icons.north_east_rounded,
    _ => Icons.balance_rounded,
  };

  String get _periodLabel =>
      _timePeriod.toLowerCase().replaceFirst('theo ', '');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      body: StreamBuilder<List<TransactionModel>>(
        stream: _transactionsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: _primaryPink),
            );
          }
          if (snapshot.hasError) {
            return _buildErrorState();
          }

          final transactions = snapshot.data ?? const [];
          final data = _groupedData(transactions, DateTime.now());
          final total = data.fold<double>(0, (sum, value) => sum + value);

          return RefreshIndicator(
            color: _primaryPink,
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                _buildPageIntro(),
                const SizedBox(height: 16),
                _buildPeriodSelector(),
                const SizedBox(height: 12),
                _buildTypeSelector(),
                const SizedBox(height: 16),
                _buildTotalCard(total),
                const SizedBox(height: 16),
                _buildChartCard(data),
                const SizedBox(height: 16),
                if (_reportType != 'Chênh lệch')
                  _buildCategoryCard(transactions)
                else
                  _buildDifferenceNote(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPageIntro() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phân tích tài chính',
          style: TextStyle(
            color: Color(0xFF2F2630),
            fontSize: 23,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Theo dõi xu hướng thu chi theo từng khoảng thời gian',
          style: TextStyle(color: Colors.black45, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1E8EE)),
      ),
      child: Row(
        children: ['Theo tuần', 'Theo tháng', 'Theo năm']
            .map(
              (period) => _buildSegment(period, _timePeriod == period, () {
                setState(() => _timePeriod = period);
              }),
            )
            .toList(),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        _buildTypeChip('Thu nhập', Icons.south_west_rounded),
        const SizedBox(width: 8),
        _buildTypeChip('Chi tiêu', Icons.north_east_rounded),
        const SizedBox(width: 8),
        _buildTypeChip('Chênh lệch', Icons.balance_rounded),
      ],
    );
  }

  Widget _buildSegment(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? _primaryPink : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label.replaceFirst('Theo ', ''),
            style: TextStyle(
              color: selected ? Colors.white : Colors.black45,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String label, IconData icon) {
    final selected = _reportType == label;
    final color = switch (label) {
      'Thu nhập' => const Color(0xFF35A853),
      'Chi tiêu' => const Color(0xFFFF5252),
      _ => const Color(0xFF7C4DFF),
    };
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _reportType = label),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.11) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color : const Color(0xFFF1E8EE),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? color : Colors.black38, size: 20),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  color: selected ? color : Colors.black45,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalCard(double total) {
    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_darkPink, _primaryPink, Color(0xFFF06292)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primaryPink.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.17),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(_reportIcon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tổng ${_reportType.toLowerCase()} $_periodLabel này',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 5),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _currency.format(total),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(List<double> data) {
    final hasData = data.any((value) => value != 0);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF3EAF0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8C5A76).withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _reportBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.bar_chart_rounded, color: _reportColor),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Biểu đồ biến động',
                      style: TextStyle(
                        color: Color(0xFF332B31),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Đơn vị: triệu đồng',
                      style: TextStyle(color: Colors.black38, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 220,
            child: hasData
                ? _buildChart(data)
                : const Center(
                    child: Text(
                      'Chưa có dữ liệu trong khoảng thời gian này',
                      style: TextStyle(color: Colors.black38, fontSize: 12),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(List<double> data) {
    final values = data.map((value) => value / 1000000).toList();
    final maxAbsolute = values.fold<double>(0, (max, value) {
      return value.abs() > max ? value.abs() : max;
    });
    final limit = maxAbsolute == 0 ? 1.0 : maxAbsolute * 1.25;
    final isDifference = _reportType == 'Chênh lệch';

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: limit,
        minY: isDifference ? -limit : 0,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF3E343A),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                _currency.format(data[group.x]),
                const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  value.toStringAsFixed(value.abs() < 1 ? 1 : 0),
                  style: const TextStyle(color: Colors.black38, fontSize: 9),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    _bottomLabel(index),
                    style: const TextStyle(
                      color: Colors.black45,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: Color(0xFFF1E8EE), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(values.length, (index) {
          final value = values[index];
          final color = isDifference
              ? (value >= 0 ? const Color(0xFF35A853) : const Color(0xFFFF5252))
              : _reportColor;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: value,
                width: _timePeriod == 'Theo năm' ? 11 : 18,
                color: color,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(value >= 0 ? 6 : 0),
                  topRight: Radius.circular(value >= 0 ? 6 : 0),
                  bottomLeft: Radius.circular(value < 0 ? 6 : 0),
                  bottomRight: Radius.circular(value < 0 ? 6 : 0),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  String _bottomLabel(int index) {
    if (_timePeriod == 'Theo tuần') {
      const labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
      return index < labels.length ? labels[index] : '';
    }
    if (_timePeriod == 'Theo tháng') return 'Tuần ${index + 1}';
    return 'T${index + 1}';
  }

  Widget _buildCategoryCard(List<TransactionModel> transactions) {
    final grouped = <String, List<TransactionModel>>{};
    final now = DateTime.now();
    for (final transaction in transactions) {
      if (!_isInPeriod(transaction.createdAt, now) ||
          !_matchesReportType(transaction)) {
        continue;
      }
      grouped
          .putIfAbsent(_categoryName(transaction), () => [])
          .add(transaction);
    }

    final entries = grouped.entries.toList()
      ..sort((a, b) {
        final aTotal = a.value.fold<double>(0, (sum, tx) => sum + tx.amount);
        final bTotal = b.value.fold<double>(0, (sum, tx) => sum + tx.amount);
        return bTotal.compareTo(aTotal);
      });

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF3EAF0)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _reportBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.category_rounded, color: _reportColor),
                ),
                const SizedBox(width: 11),
                const Expanded(
                  child: Text(
                    'Phân bổ theo danh mục',
                    style: TextStyle(
                      color: Color(0xFF332B31),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 8, 24, 28),
              child: Text(
                'Chưa có giao dịch phù hợp trong khoảng thời gian này.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black38, fontSize: 12),
              ),
            )
          else
            ...entries.map(_buildCategoryTile),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(MapEntry<String, List<TransactionModel>> entry) {
    final total = entry.value.fold<double>(0, (sum, tx) => sum + tx.amount);
    final first = entry.value.first;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 3),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
        leading: _categoryIcon(first.categoryId, entry.key),
        title: Text(
          entry.key,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${entry.value.length} giao dịch',
          style: const TextStyle(color: Colors.black38, fontSize: 11),
        ),
        trailing: Text(
          _currency.format(total),
          style: TextStyle(
            color: _reportColor,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        children: entry.value.map((transaction) {
          return ListTile(
            dense: true,
            contentPadding: const EdgeInsets.only(left: 12),
            title: Text(
              transaction.note.isEmpty ? entry.key : transaction.note,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              DateFormat('dd/MM/yyyy • HH:mm').format(transaction.createdAt),
            ),
            trailing: Text(
              _currency.format(transaction.amount),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    TransactionDetailScreen(transaction: transaction),
              ),
            ).then((_) => _refresh()),
          );
        }).toList(),
      ),
    );
  }

  Widget _categoryIcon(String? id, String name) {
    final category = _findCategory(id, name);
    Color color = _reportColor;
    IconData icon = _reportIcon;
    if (category != null) {
      try {
        color = Color(
          int.parse(category.colorHex.replaceFirst('#', ''), radix: 16),
        );
        icon = IconData(
          int.parse(category.iconCode, radix: 16),
          fontFamily: 'MaterialIcons',
        );
      } catch (_) {}
    }
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }

  Widget _buildDifferenceNote() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EAFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCCEFF)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFF7C4DFF)),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'Chênh lệch được tính bằng thu nhập trừ chi tiêu. Chuyển tiền giữa các ví không làm thay đổi tổng tài sản nên không được tính vào báo cáo.',
              style: TextStyle(
                color: Color(0xFF5A488B),
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, color: _primaryPink, size: 52),
            const SizedBox(height: 14),
            const Text(
              'Không thể tải dữ liệu biến động',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
