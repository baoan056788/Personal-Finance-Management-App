import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/transaction_model.dart';
import '../../../models/wallet_model.dart';
import '../services/transaction_service.dart';
import '../services/wallet_service.dart';
import 'add_transaction_screen.dart';

class WalletDetailScreen extends StatefulWidget {
  final WalletModel wallet;

  const WalletDetailScreen({super.key, required this.wallet});

  @override
  State<WalletDetailScreen> createState() => _WalletDetailScreenState();
}

class _WalletDetailScreenState extends State<WalletDetailScreen> {
  static const Color _primaryPink = Color(0xFFE0248A);
  static const Color _darkPink = Color(0xFFB02A76);
  static const Color _pageBackground = Color(0xFFFFF7FF);

  final TransactionService _transactionService = TransactionService();
  final WalletService _walletService = WalletService();
  late String _walletName;

  @override
  void initState() {
    super.initState();
    _walletName = widget.wallet.name;
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    ).format(amount);
  }

  IconData get _walletIcon {
    final type = widget.wallet.type.toLowerCase();
    if (type.contains('bank') || type.contains('ngân hàng')) {
      return Icons.account_balance_rounded;
    }
    if (type.contains('card') || type.contains('thẻ')) {
      return Icons.credit_card_rounded;
    }
    if (type.contains('saving') || type.contains('tiết kiệm')) {
      return Icons.savings_rounded;
    }
    if (type.contains('wallet') || type.contains('điện tử')) {
      return Icons.account_balance_wallet_rounded;
    }
    return Icons.payments_rounded;
  }

  ({Color color, Color background, IconData icon}) _transactionStyle(
    TransactionModel transaction,
  ) {
    if (transaction.isTransfer) {
      return (
        color: const Color(0xFF7C4DFF),
        background: const Color(0xFFF0EAFF),
        icon: transaction.isIncomingTransfer
            ? Icons.call_received_rounded
            : Icons.call_made_rounded,
      );
    }
    if (transaction.isCredit) {
      return (
        color: const Color(0xFF35A853),
        background: const Color(0xFFEAF7EE),
        icon: Icons.south_west_rounded,
      );
    }
    return (
      color: const Color(0xFFFF5252),
      background: const Color(0xFFFFECEA),
      icon: Icons.north_east_rounded,
    );
  }

  String _transactionTitle(TransactionModel transaction) {
    if (transaction.isTransfer) {
      final relatedWallet = transaction.relatedWalletName?.trim();
      if (transaction.isIncomingTransfer) {
        return relatedWallet == null || relatedWallet.isEmpty
            ? 'Nhận chuyển ví'
            : 'Nhận từ $relatedWallet';
      }
      return relatedWallet == null || relatedWallet.isEmpty
          ? 'Chuyển sang ví khác'
          : 'Chuyển đến $relatedWallet';
    }
    return transaction.category.trim().isEmpty
        ? 'Giao dịch'
        : transaction.category;
  }

  void _showEditWalletDialog() {
    final nameController = TextEditingController(text: _walletName);
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Sửa tên ví'),
          content: TextField(
            controller: nameController,
            maxLength: 30,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Tên ví mới',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isEmpty || newName == _walletName) return;
                await _walletService.updateWalletName(
                  widget.wallet.id,
                  newName,
                );
                if (mounted) setState(() => _walletName = newName);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              style: FilledButton.styleFrom(backgroundColor: _primaryPink),
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    ).whenComplete(nameController.dispose);
  }

  void _showDeleteWalletDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Xóa ví'),
          content: const Text(
            'Chỉ có thể xóa ví khi số dư bằng 0 và chưa phát sinh giao dịch.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  await _walletService.deleteWallet(widget.wallet.id);
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  if (mounted) Navigator.pop(context);
                } catch (error) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$error'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        title: const Text(
          'Chi tiết ví',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: _pageBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _showEditWalletDialog();
              } else if (value == 'delete') {
                _showDeleteWalletDialog();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, color: Colors.black54, size: 20),
                    SizedBox(width: 10),
                    Text('Sửa tên ví'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text('Xóa ví', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildWalletSummary(),
          Expanded(
            child: StreamBuilder<List<TransactionModel>>(
              stream: _transactionService.getWalletTransactions(
                widget.wallet.id,
              ),
              builder: (context, snapshot) {
                final transactions = snapshot.data ?? const [];
                return Column(
                  children: [
                    _buildHistoryHeader(transactions.length),
                    Expanded(
                      child: _buildTransactionContent(snapshot, transactions),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddTransactionScreen(wallet: widget.wallet),
            ),
          );
        },
        backgroundColor: _primaryPink,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Thêm giao dịch',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildWalletSummary() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_darkPink, _primaryPink, Color(0xFFF06292)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _primaryPink.withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(_walletIcon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _walletName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.wallet.type,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            'Số dư hiện tại',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _formatCurrency(widget.wallet.balance),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: Colors.white70,
                  size: 15,
                ),
                const SizedBox(width: 7),
                Text(
                  'Tạo ngày ${DateFormat('dd/MM/yyyy').format(widget.wallet.createdAt)}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryHeader(int transactionCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Lịch sử giao dịch',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2F2630),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE4F1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$transactionCount giao dịch',
              style: const TextStyle(
                color: _darkPink,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionContent(
    AsyncSnapshot<List<TransactionModel>> snapshot,
    List<TransactionModel> transactions,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting &&
        !snapshot.hasData) {
      return const Center(
        child: CircularProgressIndicator(color: _primaryPink),
      );
    }
    if (snapshot.hasError) {
      return _buildMessageState(
        icon: Icons.cloud_off_outlined,
        title: 'Không thể tải giao dịch',
        message: 'Vui lòng thử lại sau.',
      );
    }
    if (transactions.isEmpty) {
      return _buildMessageState(
        icon: Icons.receipt_long_outlined,
        title: 'Chưa có giao dịch',
        message: 'Các khoản thu, chi và chuyển ví sẽ xuất hiện tại đây.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: transactions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) =>
          _buildTransactionCard(transactions[index]),
    );
  }

  Widget _buildTransactionCard(TransactionModel transaction) {
    final style = _transactionStyle(transaction);
    final sign = transaction.isCredit ? '+' : '-';
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF3EAF0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8C5A76).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: style.background,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(style.icon, color: style.color, size: 23),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _transactionTitle(transaction),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF332B31),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (transaction.note.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    transaction.note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  DateFormat(
                    'dd/MM/yyyy • HH:mm',
                  ).format(transaction.createdAt),
                  style: const TextStyle(color: Colors.black38, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 132),
            child: Text(
              '$sign${_formatCurrency(transaction.amount)}',
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: style.color,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE4F1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _primaryPink, size: 34),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF332B31),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black45, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
