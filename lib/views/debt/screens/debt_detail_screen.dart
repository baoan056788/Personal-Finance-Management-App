import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../controllers/debt_controller.dart';
import '../../../models/debt_model.dart';
import '../../../models/debt_payment_model.dart';
import '../../../models/wallet_model.dart';
import '../../../utils/currency_input_formatter.dart';
import '../../../utils/finance_error_message.dart';
import '../../../widgets/finance_status_dialog.dart';
import '../../wallet/services/wallet_service.dart';

class DebtDetailScreen extends StatefulWidget {
  final DebtModel debt;

  const DebtDetailScreen({super.key, required this.debt});

  @override
  State<DebtDetailScreen> createState() => _DebtDetailScreenState();
}

class _DebtDetailScreenState extends State<DebtDetailScreen> {
  final DebtController _controller = DebtController();
  final WalletService _walletService = WalletService();
  final NumberFormat _money = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  static const _pink = Color(0xFFE0248A);

  void _showPayment(DebtModel debt) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _DebtPaymentSheet(
          debt: debt,
          controller: _controller,
          walletService: _walletService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DebtModel>>(
      stream: _controller.getDebts(),
      builder: (context, snapshot) {
        final debts = snapshot.data ?? const <DebtModel>[];
        final index = debts.indexWhere((item) => item.id == widget.debt.id);
        final debt = index >= 0 ? debts[index] : widget.debt;
        return Scaffold(
          backgroundColor: const Color(0xFFFFF8FC),
          appBar: AppBar(
            backgroundColor: const Color(0xFFFFF8FC),
            surfaceTintColor: Colors.transparent,
            foregroundColor: Colors.black87,
            title: Text(
              debt.isBorrowed ? 'Khoản cần trả' : 'Khoản cần thu',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
            children: [
              _buildHero(debt),
              const SizedBox(height: 16),
              _buildOverview(debt),
              if (debt.note.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildNote(debt.note),
              ],
              const SizedBox(height: 22),
              const Text(
                'Lịch sử thanh toán',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              _buildHistory(debt),
            ],
          ),
          bottomNavigationBar: debt.isPaid
              ? null
              : SafeArea(
                  minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: FilledButton.icon(
                    onPressed: () => _showPayment(debt),
                    icon: Icon(
                      debt.isBorrowed
                          ? Icons.payments_outlined
                          : Icons.savings_outlined,
                    ),
                    label: Text(
                      debt.isBorrowed
                          ? 'Ghi nhận trả một phần'
                          : 'Ghi nhận thu một phần',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: _pink,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildHero(DebtModel debt) {
    final progress = debt.amount <= 0
        ? 0.0
        : (debt.paidAmount / debt.amount).clamp(0.0, 1.0);
    final color = debt.isPaid
        ? const Color(0xFF159447)
        : debt.isBorrowed
        ? const Color(0xFFFF7043)
        : const Color(0xFF159447);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, Color.lerp(color, _pink, 0.45)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
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
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  debt.isPaid
                      ? Icons.check_circle_outline
                      : Icons.handshake_outlined,
                  color: Colors.white,
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
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      debt.isPaid
                          ? 'Đã tất toán'
                          : debt.isBorrowed
                          ? 'Bạn còn phải trả'
                          : 'Bạn còn phải thu',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            _money.format(debt.remainAmount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Đã thanh toán ${(progress * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverview(DebtModel debt) {
    return _card(
      child: Column(
        children: [
          _row('Tổng công nợ', _money.format(debt.amount), Icons.flag_outlined),
          const Divider(height: 28),
          _row(
            'Đã thanh toán',
            _money.format(debt.paidAmount),
            Icons.task_alt,
            color: const Color(0xFF159447),
          ),
          const Divider(height: 28),
          _row(
            'Ngày đến hạn',
            DateFormat('dd/MM/yyyy').format(debt.dueDate),
            Icons.event_outlined,
            color: debt.status == 'OVERDUE' ? Colors.red : _pink,
          ),
          const Divider(height: 28),
          _row(
            'Ghi nhận vào ví',
            debt.affectsWallet ? 'Có' : 'Không',
            Icons.account_balance_wallet_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildNote(String note) => _card(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.notes_rounded, color: _pink),
        const SizedBox(width: 12),
        Expanded(child: Text(note, style: const TextStyle(height: 1.5))),
      ],
    ),
  );

  Widget _buildHistory(DebtModel debt) {
    return StreamBuilder<List<DebtPaymentModel>>(
      stream: _controller.getPayments(debt.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final payments = snapshot.data ?? const <DebtPaymentModel>[];
        if (payments.isEmpty) {
          return _card(
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  'Chưa phát sinh lần thanh toán nào',
                  style: TextStyle(color: Colors.black45),
                ),
              ),
            ),
          );
        }
        return _card(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: payments.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, index) {
              final payment = payments[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 5),
                leading: CircleAvatar(
                  backgroundColor: _pink.withValues(alpha: 0.1),
                  child: const Icon(Icons.payments_outlined, color: _pink),
                ),
                title: Text(
                  _money.format(payment.amount),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  payment.note.isEmpty
                      ? DateFormat('dd/MM/yyyy HH:mm').format(payment.createdAt)
                      : '${payment.note} • ${DateFormat('dd/MM/yyyy HH:mm').format(payment.createdAt)}',
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _row(
    String label,
    String value,
    IconData icon, {
    Color color = Colors.black87,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 21),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: const TextStyle(color: Colors.black54)),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DebtPaymentSheet extends StatefulWidget {
  final DebtModel debt;
  final DebtController controller;
  final WalletService walletService;

  const _DebtPaymentSheet({
    required this.debt,
    required this.controller,
    required this.walletService,
  });

  @override
  State<_DebtPaymentSheet> createState() => _DebtPaymentSheetState();
}

class _DebtPaymentSheetState extends State<_DebtPaymentSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _walletId;
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = parseCurrencyInput(_amountController.text);
    if (_walletId == null || amount == null || amount <= 0) {
      await showFinanceStatusDialog(
        context,
        success: false,
        title: 'Thông tin chưa đầy đủ',
        message: 'Vui lòng chọn ví và nhập số tiền thanh toán hợp lệ.',
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.controller.recordPayment(
        debtId: widget.debt.id,
        walletId: _walletId!,
        amount: amount,
        note: _noteController.text.trim(),
      );
      if (!mounted) return;
      await showFinanceStatusDialog(
        context,
        success: true,
        title: 'Ghi nhận thành công',
        message: widget.debt.isBorrowed
            ? 'Khoản trả nợ đã được cập nhật và trừ khỏi ví đã chọn.'
            : 'Khoản thu hồi nợ đã được cập nhật vào ví đã chọn.',
        buttonText: 'Hoàn tất',
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      await showFinanceStatusDialog(
        context,
        success: false,
        title: 'Chưa thể ghi nhận',
        message: financeErrorMessage(error),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
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
            const SizedBox(height: 20),
            Text(
              widget.debt.isBorrowed
                  ? 'Ghi nhận trả nợ'
                  : 'Ghi nhận thu hồi nợ',
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Còn lại ${money.format(widget.debt.remainAmount)}',
              style: const TextStyle(
                color: Color(0xFFE0248A),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            StreamBuilder<List<WalletModel>>(
              stream: widget.walletService.getWallets(),
              builder: (context, snapshot) {
                final wallets = snapshot.data ?? const <WalletModel>[];
                return DropdownButtonFormField<String>(
                  initialValue: _walletId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: widget.debt.isBorrowed
                        ? 'Ví dùng để trả'
                        : 'Ví nhận tiền',
                    prefixIcon: const Icon(
                      Icons.account_balance_wallet_outlined,
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  items: wallets
                      .map(
                        (wallet) => DropdownMenuItem(
                          value: wallet.id,
                          child: Text(
                            '${wallet.name} (${money.format(wallet.balance)})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _walletId = value),
                );
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              decoration: InputDecoration(
                labelText: 'Số tiền thanh toán',
                prefixIcon: const Icon(Icons.payments_outlined),
                suffixIcon: TextButton(
                  onPressed: () => _amountController.text = formatCurrencyInput(
                    widget.debt.remainAmount,
                  ),
                  child: const Text('Toàn bộ'),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _noteController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Ghi chú',
                prefixIcon: Icon(Icons.notes_rounded),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded),
              label: const Text('Xác nhận thanh toán'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE0248A),
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
