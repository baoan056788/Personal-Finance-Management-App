import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/wallet_model.dart';
import '../services/wallet_service.dart';
import '../../auth/widgets/custom_button.dart';
import '../../auth/widgets/custom_text_field.dart';
import '../../home/home_view.dart';

class EnterBalanceScreen extends StatefulWidget {
  final String name;
  final String type;

  const EnterBalanceScreen({
    super.key,
    required this.name,
    required this.type,
  });

  @override
  State<EnterBalanceScreen> createState() => _EnterBalanceScreenState();
}

class _EnterBalanceScreenState extends State<EnterBalanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _balanceController = TextEditingController();
  bool _isLoading = false;
  final WalletService _walletService = WalletService();

  void _setPresetAmount(String amount) {
    _balanceController.text = amount;
    _balanceController.selection = TextSelection.fromPosition(TextPosition(offset: amount.length));
  }

  Widget _buildPresetChip(String label, String value) {
    return ActionChip(
      label: Text(label),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: const Color(0xFFF06292).withValues(alpha: 0.5)),
      ),
      onPressed: () => _setPresetAmount(value),
    );
  }

  Future<void> _createWallet() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Người dùng chưa đăng nhập');

      final newId = _walletService.generateWalletId();
      final wallet = WalletModel(
        id: newId,
        name: widget.name,
        type: widget.type,
        balance: double.parse(_balanceController.text.replaceAll(',', '')),
        createdAt: DateTime.now(),
      );

      await _walletService.createWallet(wallet);

      // Set onboarding completed
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'onboardingCompleted': true,
      }, SetOptions(merge: true));

      if (!mounted) return;
      
      // Use pushAndRemoveUntil to clear the onboarding stack cleanly
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeView()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xảy ra lỗi: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FF),
      appBar: AppBar(
        title: const Text('Số dư ban đầu', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Icon(Icons.account_balance, size: 80, color: Color(0xFFF06292)),
                const SizedBox(height: 24),
                Text(
                  'Bạn hiện đang có bao nhiêu tiền trong ví\n"${widget.name}"?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 48),
                CustomTextField(
                  label: 'Số dư ban đầu (VNĐ)',
                  hint: 'Nhập số tiền',
                  controller: _balanceController,
                  prefixIcon: Icons.attach_money_outlined,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Vui lòng nhập số dư';
                    final balance = double.tryParse(value.replaceAll(',', ''));
                    if (balance == null) return 'Số dư không hợp lệ';
                    if (balance < 0) return 'Số dư không được âm';
                    if (balance > 999999999) return 'Số dư tối đa là 999,999,999';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildPresetChip('0 ₫', '0'),
                    _buildPresetChip('500,000 ₫', '500000'),
                    _buildPresetChip('1,000,000 ₫', '1000000'),
                    _buildPresetChip('5,000,000 ₫', '5000000'),
                  ],
                ),
                const SizedBox(height: 48),
                CustomButton(
                  text: 'HOÀN TẤT',
                  onPressed: _createWallet,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
