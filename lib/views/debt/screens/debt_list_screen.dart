import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../utils/currency_input_formatter.dart';

import '../../../controllers/debt_controller.dart';
import '../../../models/debt_model.dart';

class DebtListScreen extends StatefulWidget {
  const DebtListScreen({super.key});

  @override
  State<DebtListScreen> createState() => _DebtListScreenState();
}

class _DebtListScreenState extends State<DebtListScreen> {
  final DebtController _debtController = DebtController();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
  );

  Color get _mainColor => const Color(0xFFE0248A);

  Future<void> _showDebtForm({DebtModel? debt}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _DebtFormSheet(
        controller: _debtController,
        debt: debt,
        mainColor: _mainColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
        title: const Text(
          'Sổ nợ',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<List<DebtModel>>(
        stream: _debtController.getDebts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: _mainColor));
          }
          if (snapshot.hasError) {
            return _buildMessageState(
              icon: Icons.error_outline,
              title: 'Không thể tải công nợ',
              message: '${snapshot.error}',
            );
          }

          final debts = snapshot.data ?? [];
          if (debts.isEmpty) return _buildEmptyState();

          final openDebts = debts.where((debt) => !debt.isPaid).toList();
          final borrowed = openDebts
              .where((debt) => debt.type == 'borrowed')
              .fold(0.0, (sum, debt) => sum + debt.remainAmount);
          final lent = openDebts
              .where((debt) => debt.type == 'lent')
              .fold(0.0, (sum, debt) => sum + debt.remainAmount);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildSummaryCard(
                borrowed: borrowed,
                lent: lent,
                openCount: openDebts.length,
              ),
              const SizedBox(height: 20),
              const Text(
                'Danh sách công nợ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              ...debts.map(_buildDebtCard),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _mainColor,
        onPressed: () => _showDebtForm(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Thêm khoản nợ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required double borrowed,
    required double lent,
    required int openCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE0248A), Color(0xFF8E1458)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
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
                child: const Icon(
                  Icons.handshake_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Theo dõi vay và cho vay',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _summaryMetric('Cần trả', borrowed, Colors.orangeAccent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryMetric('Cần thu', lent, Colors.lightGreenAccent),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$openCount khoản đang mở',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _summaryMetric(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            _currencyFormat.format(amount),
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDebtCard(DebtModel debt) {
    final statusColor = _statusColor(debt.status);
    final statusText = _statusText(debt.status);
    final isBorrowed = debt.type == 'borrowed';
    final dueText = DateFormat('dd/MM/yyyy').format(debt.dueDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isBorrowed ? Colors.orange : Colors.green).withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isBorrowed ? Icons.call_received : Icons.call_made,
                  color: isBorrowed ? Colors.orange : Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.personName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isBorrowed ? 'Đi vay' : 'Cho vay',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') _showDebtForm(debt: debt);
                  if (value == 'paid') _markAsPaid(debt);
                  if (value == 'delete') _deleteDebt(debt);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
                  if (!debt.isPaid)
                    const PopupMenuItem(value: 'paid', child: Text('Tất toán')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Xóa', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  _currencyFormat.format(debt.remainAmount),
                  style: TextStyle(
                    color: isBorrowed ? Colors.orange : Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.event, size: 15, color: Colors.black45),
              const SizedBox(width: 6),
              Text(
                'Hạn: $dueText',
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
          if (debt.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                debt.note,
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return _buildMessageState(
      icon: Icons.handshake_outlined,
      title: 'Chưa có khoản công nợ nào',
      message:
          'Ghi nhận khoản đi vay hoặc cho vay để ứng dụng nhắc bạn khi gần đến hạn.',
    );
  }

  Widget _buildMessageState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.grey.shade300, size: 80),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black45, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PAID':
        return Colors.green;
      case 'OVERDUE':
        return Colors.red;
      case 'DUE_SOON':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'PAID':
        return 'Đã tất toán';
      case 'OVERDUE':
        return 'Quá hạn';
      case 'DUE_SOON':
        return 'Sắp đến hạn';
      default:
        return 'Đang mở';
    }
  }

  Future<void> _markAsPaid(DebtModel debt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tất toán khoản công nợ?'),
        content: Text(
          'Bạn có chắc chắn muốn đánh dấu khoản với "${debt.personName}" là đã tất toán không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: _mainColor),
            child: const Text(
              'Tất toán',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _debtController.markAsPaid(debt);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã tất toán khoản công nợ')));
  }

  Future<void> _deleteDebt(DebtModel debt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa khoản công nợ?'),
        content: Text(
          'Bạn có chắc chắn muốn xóa khoản với "${debt.personName}" không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) await _debtController.deleteDebt(debt.id);
  }
}

class _DebtFormSheet extends StatefulWidget {
  final DebtController controller;
  final DebtModel? debt;
  final Color mainColor;

  const _DebtFormSheet({
    required this.controller,
    required this.mainColor,
    this.debt,
  });

  @override
  State<_DebtFormSheet> createState() => _DebtFormSheetState();
}

class _DebtFormSheetState extends State<_DebtFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _personController;
  late final TextEditingController _amountController;
  late final TextEditingController _paidController;
  late final TextEditingController _noteController;
  late String _type;
  late DateTime _dueDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final debt = widget.debt;
    _personController = TextEditingController(text: debt?.personName ?? '');
    _amountController = TextEditingController(
      text: debt == null ? '' : formatCurrencyInput(debt.amount),
    );
    _paidController = TextEditingController(
      text: debt == null ? '0' : formatCurrencyInput(debt.paidAmount),
    );
    _noteController = TextEditingController(text: debt?.note ?? '');
    _type = debt?.type ?? 'borrowed';
    _dueDate = debt?.dueDate ?? DateTime.now().add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _personController.dispose();
    _amountController.dispose();
    _paidController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double? _parseMoney(String value) {
    return parseCurrencyInput(value);
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (!mounted || picked == null) return;
    setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập lại để lưu công nợ.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final amount = _parseMoney(_amountController.text)!;
      final paid = _parseMoney(_paidController.text) ?? 0;
      final now = DateTime.now();
      final oldDebt = widget.debt;
      final model = DebtModel(
        id: oldDebt?.id ?? '',
        userId: oldDebt?.userId ?? user.uid,
        type: _type,
        personName: _personController.text.trim(),
        amount: amount,
        paidAmount: paid,
        dueDate: _dueDate,
        note: _noteController.text.trim(),
        status: oldDebt?.status ?? 'OPEN',
        createdAt: oldDebt?.createdAt ?? now,
        updatedAt: now,
      );

      if (oldDebt == null) {
        await widget.controller.createDebt(model);
      } else {
        await widget.controller.updateDebt(model);
      }
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể lưu công nợ: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEditing = widget.debt != null;

    return PopScope(
      canPop: !_isSaving,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: bottomInset + 20,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  isEditing ? 'Chỉnh sửa công nợ' : 'Thêm khoản công nợ',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'borrowed',
                      label: Text('Đi vay'),
                      icon: Icon(Icons.call_received),
                    ),
                    ButtonSegment(
                      value: 'lent',
                      label: Text('Cho vay'),
                      icon: Icon(Icons.call_made),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: _isSaving
                      ? null
                      : (value) => setState(() => _type = value.first),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _personController,
                  enabled: !_isSaving,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Người giao dịch',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Vui lòng nhập tên'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  enabled: !_isSaving,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Số tiền',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final amount = _parseMoney(value ?? '');
                    if (amount == null || amount <= 0) {
                      return 'Số tiền phải lớn hơn 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _paidController,
                  enabled: !_isSaving,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Đã thanh toán',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final paid = _parseMoney(value ?? '0');
                    final amount = _parseMoney(_amountController.text);
                    if (paid == null || paid < 0) {
                      return 'Số đã thanh toán không hợp lệ';
                    }
                    if (amount != null && paid > amount) {
                      return 'Số đã thanh toán không được vượt tổng tiền';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: _isSaving ? null : _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Ngày hạn',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(DateFormat('dd/MM/yyyy').format(_dueDate)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  enabled: !_isSaving,
                  minLines: 2,
                  maxLines: 3,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Hủy'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.mainColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Lưu',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
