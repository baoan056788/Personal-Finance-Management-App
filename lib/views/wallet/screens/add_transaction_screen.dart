import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../../models/wallet_model.dart';
import '../../../models/transaction_model.dart';
import '../services/transaction_service.dart';
import '../services/wallet_service.dart';
import '../../auth/widgets/custom_text_field.dart';

class AddTransactionScreen extends StatefulWidget {
  final WalletModel wallet;

  const AddTransactionScreen({super.key, required this.wallet});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  String _transactionType = 'expense'; // 'income', 'expense', or 'transfer'
  String _category = 'Khác';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  final TransactionService _transactionService = TransactionService();
  final WalletService _walletService = WalletService();

  final List<String> _expenseCategories = ['Ăn uống', 'Di chuyển', 'Mua sắm', 'Hóa đơn', 'Giải trí', 'Khác'];
  final List<String> _incomeCategories = ['Lương', 'Thưởng', 'Đầu tư', 'Khác'];

  List<WalletModel> _otherWallets = [];
  String? _selectedDestWalletId;

  @override
  void initState() {
    super.initState();
    _loadOtherWallets();
  }

  void _loadOtherWallets() {
    _walletService.getWallets().listen((wallets) {
      if (mounted) {
        setState(() {
          _otherWallets = wallets.where((w) => w.id != widget.wallet.id).toList();
          if (_otherWallets.isNotEmpty && _selectedDestWalletId == null) {
            _selectedDestWalletId = _otherWallets.first.id;
          }
        });
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFB02A76),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Người dùng chưa đăng nhập');

      final amount = double.parse(_amountController.text.replaceAll(',', ''));

      if (_transactionType == 'transfer') {
        if (_selectedDestWalletId == null) throw Exception('Vui lòng chọn ví đích');
        await _walletService.transferMoney(
          sourceWalletId: widget.wallet.id,
          destWalletId: _selectedDestWalletId!,
          amount: amount,
          note: _noteController.text.trim(),
        );
      } else {
        final newTxRef = FirebaseFirestore.instance.collection('dummy').doc(); 
        final transaction = TransactionModel(
          id: newTxRef.id,
          amount: amount,
          type: _transactionType,
          category: _category,
          note: _noteController.text.trim(),
          createdAt: _selectedDate,
        );

        await _transactionService.createTransaction(widget.wallet.id, transaction, widget.wallet.balance);
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thành công!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Widget _buildTypeButton(String title, String type, Color color) {
    bool isSelected = _transactionType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _transactionType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_transactionType != 'transfer') {
      List<String> currentCategories = _transactionType == 'income' ? _incomeCategories : _expenseCategories;
      if (!currentCategories.contains(_category)) {
        _category = currentCategories.first;
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Thêm giao dịch', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                Row(
                  children: [
                    _buildTypeButton('Chi tiêu', 'expense', Colors.redAccent),
                    const SizedBox(width: 8),
                    _buildTypeButton('Thu nhập', 'income', Colors.green),
                    const SizedBox(width: 8),
                    _buildTypeButton('Chuyển tiền', 'transfer', Colors.blueAccent),
                  ],
                ),
                const SizedBox(height: 32),
                CustomTextField(
                  label: 'Số tiền',
                  hint: '0 ₫',
                  controller: _amountController,
                  prefixIcon: Icons.attach_money,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Vui lòng nhập số tiền';
                    if (double.tryParse(value.replaceAll(',', '')) == null) return 'Số tiền không hợp lệ';
                    return null;
                  },
                ),
                if (_transactionType != 'transfer')
                  Container(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _category,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFB02A76)),
                        items: (_transactionType == 'income' ? _incomeCategories : _expenseCategories).map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _category = newValue!;
                          });
                        },
                      ),
                    ),
                  ),
                if (_transactionType == 'transfer')
                  Container(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedDestWalletId,
                        isExpanded: true,
                        hint: const Text('Chọn ví đích'),
                        icon: const Icon(Icons.account_balance_wallet, color: Colors.blueAccent),
                        items: _otherWallets.map((WalletModel wallet) {
                          return DropdownMenuItem<String>(
                            value: wallet.id,
                            child: Text('${wallet.name} (${wallet.balance.toStringAsFixed(0)} ₫)'),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedDestWalletId = newValue;
                          });
                        },
                      ),
                    ),
                  ),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Color(0xFFB02A76)),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('dd/MM/yyyy').format(_selectedDate),
                          style: const TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),
                CustomTextField(
                  label: 'Ghi chú (Tùy chọn)',
                  hint: 'Thêm thông tin...',
                  controller: _noteController,
                  prefixIcon: Icons.notes,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB02A76),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('LƯU GIAO DỊCH', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
