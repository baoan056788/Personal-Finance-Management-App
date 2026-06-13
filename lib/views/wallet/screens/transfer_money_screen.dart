import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/wallet_model.dart';
import '../../../services/app_config_service.dart';
import '../../../utils/currency_input_formatter.dart';
import '../services/wallet_service.dart';

class TransferMoneyScreen extends StatefulWidget {
  final String? initialSourceWalletId;

  const TransferMoneyScreen({super.key, this.initialSourceWalletId});

  @override
  State<TransferMoneyScreen> createState() => _TransferMoneyScreenState();
}

class _TransferMoneyScreenState extends State<TransferMoneyScreen> {
  final WalletService _walletService = WalletService();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  StreamSubscription<List<WalletModel>>? _walletSubscription;
  List<WalletModel> _wallets = [];
  String? _sourceWalletId;
  String? _destinationWalletId;
  bool _isLoading = true;
  bool _isTransferring = false;

  WalletModel? get _sourceWallet => _walletById(_sourceWalletId);
  WalletModel? get _destinationWallet => _walletById(_destinationWalletId);

  @override
  void initState() {
    super.initState();
    _walletSubscription = _walletService.getWallets().listen(
      _handleWallets,
      onError: (_) {
        if (mounted) setState(() => _isLoading = false);
      },
    );
  }

  WalletModel? _walletById(String? id) {
    if (id == null) return null;
    for (final wallet in _wallets) {
      if (wallet.id == id) return wallet;
    }
    return null;
  }

  void _handleWallets(List<WalletModel> wallets) {
    if (!mounted) return;
    setState(() {
      _wallets = wallets;
      _isLoading = false;

      final requestedSource = widget.initialSourceWalletId;
      if (_walletById(_sourceWalletId) == null) {
        _sourceWalletId = _walletById(requestedSource) != null
            ? requestedSource
            : (wallets.isNotEmpty ? wallets.first.id : null);
      }

      if (_walletById(_destinationWalletId) == null ||
          _destinationWalletId == _sourceWalletId) {
        _destinationWalletId = _firstOtherWalletId(_sourceWalletId);
      }
    });
  }

  String? _firstOtherWalletId(String? walletId) {
    for (final wallet in _wallets) {
      if (wallet.id != walletId) return wallet.id;
    }
    return null;
  }

  String _formatMoney(double amount) {
    return '${NumberFormat.decimalPattern('vi_VN').format(amount)}đ';
  }

  void _swapWallets() {
    if (_sourceWalletId == null || _destinationWalletId == null) return;
    setState(() {
      final previousSource = _sourceWalletId;
      _sourceWalletId = _destinationWalletId;
      _destinationWalletId = previousSource;
    });
  }

  Future<void> _transfer() async {
    final amount = parseCurrencyInput(_amountController.text);
    final source = _sourceWallet;
    final destination = _destinationWallet;
    final messenger = ScaffoldMessenger.of(context);

    if (source == null || destination == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn đủ hai ví.')),
      );
      return;
    }
    if (amount == null || amount <= 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Số tiền chuyển phải lớn hơn 0.')),
      );
      return;
    }
    if (amount > source.balance) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Ví ${source.name} chỉ còn ${_formatMoney(source.balance)}.',
          ),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      return;
    }

    final config = await AppConfigService().getConfig();
    if (!mounted) return;
    if (amount > config.maxTransactionAmount) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Số tiền vượt hạn mức ${_formatMoney(config.maxTransactionAmount)}.',
          ),
          backgroundColor: Colors.orange.shade800,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận chuyển tiền'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${source.name} → ${destination.name}'),
            const SizedBox(height: 8),
            Text(
              _formatMoney(amount),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB02A76),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Chuyển tiền'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isTransferring = true);
    try {
      await _walletService.transferMoney(
        sourceWalletId: source.id,
        destWalletId: destination.id,
        amount: amount,
        note: _noteController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Đã chuyển ${_formatMoney(amount)} đến ví ${destination.name}.',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Không thể chuyển tiền: $error'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isTransferring = false);
    }
  }

  @override
  void dispose() {
    _walletSubscription?.cancel();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: AppBar(
        title: const Text('Chuyển tiền giữa các ví'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _wallets.length < 2
          ? const _NotEnoughWallets()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _WalletSelector(
                        label: 'Từ ví',
                        value: _sourceWalletId,
                        wallets: _wallets,
                        excludedWalletId: _destinationWalletId,
                        onChanged: (value) {
                          setState(() {
                            _sourceWalletId = value;
                            if (_destinationWalletId == value) {
                              _destinationWalletId = _firstOtherWalletId(value);
                            }
                          });
                        },
                      ),
                      if (_sourceWallet != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              'Khả dụng: ${_formatMoney(_sourceWallet!.balance)}',
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      IconButton.filledTonal(
                        onPressed: _swapWallets,
                        tooltip: 'Đổi chiều chuyển',
                        icon: const Icon(Icons.swap_vert),
                      ),
                      const SizedBox(height: 8),
                      _WalletSelector(
                        label: 'Đến ví',
                        value: _destinationWalletId,
                        wallets: _wallets,
                        excludedWalletId: _sourceWalletId,
                        onChanged: (value) =>
                            setState(() => _destinationWalletId = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [CurrencyInputFormatter()],
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Số tiền',
                          suffixText: 'đ',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _noteController,
                        maxLength: 120,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Ghi chú (không bắt buộc)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _wallets.length < 2
          ? null
          : SafeArea(
              minimum: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: _isTransferring ? null : _transfer,
                icon: _isTransferring
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.swap_horiz),
                label: Text(_isTransferring ? 'Đang chuyển...' : 'Chuyển tiền'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: const Color(0xFFB02A76),
                ),
              ),
            ),
    );
  }
}

class _WalletSelector extends StatelessWidget {
  final String label;
  final String? value;
  final List<WalletModel> wallets;
  final String? excludedWalletId;
  final ValueChanged<String?> onChanged;

  const _WalletSelector({
    required this.label,
    required this.value,
    required this.wallets,
    required this.excludedWalletId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey('$label-$value'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: wallets
          .where((wallet) => wallet.id != excludedWalletId)
          .map(
            (wallet) => DropdownMenuItem(
              value: wallet.id,
              child: Text(
                wallet.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _NotEnoughWallets extends StatelessWidget {
  const _NotEnoughWallets();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_wallet_outlined, size: 64),
            SizedBox(height: 16),
            Text(
              'Bạn cần ít nhất 2 ví để chuyển tiền.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
