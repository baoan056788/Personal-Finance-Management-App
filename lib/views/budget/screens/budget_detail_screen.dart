import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../controllers/budget_controller.dart';
import '../../../models/budget_model.dart';
import '../../../models/transaction_model.dart';
import '../../../utils/budget_calculator.dart';
import '../../home/screens/transaction_detail_screen.dart';
import '../../wallet/services/transaction_service.dart';
import 'edit_budget_screen.dart';

class BudgetDetailScreen extends StatefulWidget {
  final BudgetModel budget;

  const BudgetDetailScreen({super.key, required this.budget});

  @override
  State<BudgetDetailScreen> createState() => _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends State<BudgetDetailScreen> {
  final BudgetController _budgetController = BudgetController();
  final TransactionService _transactionService = TransactionService();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );
  late BudgetModel _budget;
  StreamSubscription<BudgetModel?>? _budgetSubscription;
  late final Stream<List<TransactionModel>> _transactionsStream;
  bool _isLoading = false;
  bool _showAllTransactions = false;

  @override
  void initState() {
    super.initState();
    _budget = widget.budget;
    _transactionsStream = _transactionService.watchAllTransactionsGlobal();
    _budgetSubscription = _budgetController.watchBudgetById(_budget.id).listen((
      budget,
    ) {
      if (budget != null && mounted) setState(() => _budget = budget);
    });
  }

  @override
  void dispose() {
    _budgetSubscription?.cancel();
    super.dispose();
  }

  Future<void> _refreshBudget() async {
    await _budgetController.recalculateBudgetModel(_budget);
  }

  bool get _isOverLimit => _budget.spentAmount > _budget.limitAmount;

  Color get _statusColor {
    if (_budget.status == 'OVER_LIMIT') return const Color(0xFFFF3B45);
    if (_budget.status == 'DANGER') return const Color(0xFFFF7043);
    if (_budget.status == 'WARNING') return const Color(0xFFFFA000);
    return const Color(0xFF22A447);
  }

  IconData get _statusIcon {
    if (_isOverLimit) return Icons.warning_amber_rounded;
    if (_budget.status == 'DANGER') return Icons.error_outline_rounded;
    if (_budget.status == 'WARNING') return Icons.notifications_active_outlined;
    return Icons.verified_rounded;
  }

  String get _statusTitle {
    if (_isOverLimit) return 'Đã vượt ngân sách';
    if (_budget.status == 'DANGER') return 'Sắp chạm giới hạn';
    if (_budget.status == 'WARNING') return 'Cần chú ý chi tiêu';
    return 'Chi tiêu đang trong kế hoạch';
  }

  String get _statusDescription {
    final remaining = _budget.remainAmount.abs();
    if (_isOverLimit) {
      return 'Bạn đã chi vượt ${_currencyFormat.format(remaining)}. Hãy kiểm tra lại các khoản chi hoặc điều chỉnh giới hạn phù hợp.';
    }
    if (_budget.status == 'DANGER') {
      return 'Chỉ còn ${_currencyFormat.format(remaining)} trước khi chạm giới hạn.';
    }
    if (_budget.status == 'WARNING') {
      return 'Bạn còn ${_currencyFormat.format(remaining)} cho phần còn lại của kỳ ngân sách.';
    }
    return 'Bạn vẫn còn ${_currencyFormat.format(remaining)} để chi tiêu trong kỳ này.';
  }

  String get _usageLabel {
    if (_budget.limitAmount <= 0) return 'Chưa có giới hạn hợp lệ';
    final ratio = _budget.spentAmount / _budget.limitAmount;
    if (ratio > 1) {
      return 'Đã chi gấp ${_formatRatio(ratio)} lần giới hạn';
    }
    return 'Đã sử dụng ${(ratio * 100).toStringAsFixed(0)}% ngân sách';
  }

  String _formatRatio(double ratio) {
    if (ratio >= 100) return ratio.toStringAsFixed(0);
    if (ratio >= 10) return ratio.toStringAsFixed(1);
    return ratio.toStringAsFixed(2);
  }

  Future<void> _deleteBudget() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Xóa ngân sách',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Ngân sách sẽ bị xóa nhưng các giao dịch chi tiêu vẫn được giữ lại.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _budgetController.deleteBudget(_budget.id);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã xóa ngân sách')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể xóa ngân sách: $error')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDate = DateTime(
      _budget.endDate.year,
      _budget.endDate.month,
      _budget.endDate.day,
    );
    final dayDifference = endDate.difference(today).inDays;
    final remainingDays = dayDifference >= 0
        ? dayDifference + 1
        : dayDifference;
    final visualProgress = _budget.progressPercent.clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8FC),
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.black87,
        iconTheme: const IconThemeData(color: Colors.black87),
        actionsIconTheme: const IconThemeData(color: Colors.black87),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: Text(
          _budget.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Chỉnh sửa',
            onPressed: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => EditBudgetScreen(budget: _budget),
                ),
              );
              if (updated == true) await _refreshBudget();
            },
            icon: const Icon(Icons.edit_outlined, color: Colors.black87),
          ),
          IconButton(
            tooltip: 'Xóa',
            onPressed: _deleteBudget,
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshBudget,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                children: [
                  _buildStatusCard(visualProgress, remainingDays),
                  const SizedBox(height: 16),
                  _buildAmountCard(),
                  const SizedBox(height: 16),
                  _buildPeriodCard(remainingDays),
                  const SizedBox(height: 16),
                  _buildTransactionHistory(),
                  if (_budget.note.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildNoteCard(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard(double visualProgress, int remainingDays) {
    final headlineAmount = _isOverLimit
        ? _budget.remainAmount.abs()
        : _budget.remainAmount;
    final headlineLabel = _isOverLimit
        ? 'Số tiền vượt mức'
        : 'Ngân sách còn lại';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _statusColor,
            Color.lerp(_statusColor, const Color(0xFFE91E63), 0.45)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _statusColor.withValues(alpha: 0.24),
            blurRadius: 22,
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
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_statusIcon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _statusTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      remainingDays >= 0
                          ? 'Còn $remainingDays ngày trong kỳ'
                          : 'Kỳ ngân sách đã kết thúc',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Text(headlineLabel, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _currencyFormat.format(headlineAmount),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 22),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: visualProgress,
              minHeight: 12,
              backgroundColor: Colors.white.withValues(alpha: 0.22),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _usageLabel,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _statusDescription,
              style: const TextStyle(color: Colors.white, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard() {
    return _buildCard(
      title: 'Tổng quan số tiền',
      icon: Icons.account_balance_wallet_outlined,
      children: [
        _buildAmountRow(
          'Giới hạn ngân sách',
          _budget.limitAmount,
          const Color(0xFF2979FF),
          Icons.flag_outlined,
        ),
        const Divider(height: 28),
        _buildAmountRow(
          'Tổng đã chi',
          _budget.spentAmount,
          const Color(0xFFFF8A00),
          Icons.shopping_bag_outlined,
        ),
        const Divider(height: 28),
        _buildAmountRow(
          _isOverLimit ? 'Đã vượt' : 'Còn có thể chi',
          _budget.remainAmount.abs(),
          _statusColor,
          _isOverLimit ? Icons.trending_up_rounded : Icons.savings_outlined,
        ),
      ],
    );
  }

  Widget _buildPeriodCard(int remainingDays) {
    return _buildCard(
      title: 'Thời gian áp dụng',
      icon: Icons.calendar_month_outlined,
      children: [
        Text(
          '${DateFormat('dd/MM/yyyy').format(_budget.startDate)} - ${DateFormat('dd/MM/yyyy').format(_budget.endDate)}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          remainingDays >= 0
              ? 'Ngân sách còn hiệu lực trong $remainingDays ngày.'
              : 'Ngân sách này đã kết thúc.',
          style: TextStyle(color: Colors.grey.shade600, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildNoteCard() {
    return _buildCard(
      title: 'Ghi chú',
      icon: Icons.notes_rounded,
      children: [
        Text(
          _budget.note,
          style: TextStyle(color: Colors.grey.shade700, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildTransactionHistory() {
    return StreamBuilder<List<TransactionModel>>(
      stream: _transactionsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildCard(
            title: 'Các khoản chi trong ngân sách',
            icon: Icons.receipt_long_outlined,
            children: const [Text('Không thể tải lịch sử giao dịch lúc này.')],
          );
        }
        if (!snapshot.hasData) {
          return _buildCard(
            title: 'Các khoản chi trong ngân sách',
            icon: Icons.receipt_long_outlined,
            children: const [Center(child: CircularProgressIndicator())],
          );
        }

        final transactions =
            snapshot.data!
                .where(
                  (transaction) =>
                      transactionCountsTowardBudget(_budget, transaction),
                )
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final total = transactions.fold<double>(
          0,
          (sum, transaction) => sum + transaction.amount.abs(),
        );
        final visibleTransactions = _showAllTransactions
            ? transactions
            : transactions.take(5).toList();

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                child: Row(
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      color: Color(0xFFE91E63),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Các khoản chi trong ngân sách',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE91E63).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${transactions.length}',
                        style: const TextStyle(
                          color: Color(0xFFE91E63),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: Row(
                  children: [
                    Text(
                      'Tổng chi trong kỳ',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const Spacer(),
                    Flexible(
                      child: Text(
                        _currencyFormat.format(total),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: _statusColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (transactions.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 46,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Chưa có khoản chi nào trong kỳ ngân sách này.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              else
                ...visibleTransactions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final transaction = entry.value;
                  return Column(
                    children: [
                      _buildTransactionItem(transaction),
                      if (index < visibleTransactions.length - 1)
                        const Divider(height: 1, indent: 74),
                    ],
                  );
                }),
              if (transactions.length > 5) ...[
                const Divider(height: 1),
                InkWell(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                  onTap: () {
                    setState(() {
                      _showAllTransactions = !_showAllTransactions;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _showAllTransactions
                              ? 'Thu gọn'
                              : 'Xem tất cả ${transactions.length} giao dịch',
                          style: const TextStyle(
                            color: Color(0xFFE91E63),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _showAllTransactions
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: const Color(0xFFE91E63),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionItem(TransactionModel transaction) {
    final note = transaction.note.trim();
    final categoryName = transaction.category.length > 30
        ? 'Chi tiêu'
        : transaction.category;
    final title = note.isNotEmpty ? note : categoryName;
    final detail = note.isNotEmpty && categoryName.isNotEmpty
        ? '$categoryName • ${DateFormat('dd/MM/yyyy HH:mm').format(transaction.createdAt)}'
        : DateFormat('dd/MM/yyyy HH:mm').format(transaction.createdAt);

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TransactionDetailScreen(transaction: transaction),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B45).withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                color: Color(0xFFFF3B45),
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.isEmpty ? 'Khoản chi' : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '-${_currencyFormat.format(transaction.amount.abs())}',
                  style: const TextStyle(
                    color: Color(0xFFFF3B45),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.black38,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFE91E63)),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _buildAmountRow(
    String label,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 21),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(label, style: TextStyle(color: Colors.grey.shade700)),
        ),
        Flexible(
          child: Text(
            _currencyFormat.format(amount),
            textAlign: TextAlign.right,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
