import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/wallet_model.dart';
import '../services/wallet_service.dart';
import '../../../utils/currency_input_formatter.dart';

class AddWalletScreen extends StatefulWidget {
  const AddWalletScreen({super.key});

  @override
  State<AddWalletScreen> createState() => _AddWalletScreenState();
}

class _AddWalletScreenState extends State<AddWalletScreen> {
  final WalletService _walletService = WalletService();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();

  String _selectedType = 'Tiền mặt';
  final List<String> _types = [
    'Tiền mặt',
    'Ngân hàng',
    'Ví điện tử',
    'Thẻ tín dụng',
  ];

  bool _isLoading = false;

  Future<void> _saveWallet() async {
    final name = _nameController.text.trim();
    final balance = parseCurrencyInput(_balanceController.text);

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên nguồn tiền')),
      );
      return;
    }

    if (balance == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số dư ban đầu')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final newWallet = WalletModel(
          id: FirebaseFirestore.instance.collection('dummy').doc().id,
          name: name,
          balance: balance,
          type: _selectedType,
          createdAt: DateTime.now(),
        );

        await _walletService.createWallet(newWallet);
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Thêm nguồn tiền',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Loại nguồn tiền',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _types.map((type) {
                final isSelected = _selectedType == type;
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = type),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFFF0F6)
                          : Colors.grey.shade100,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFB2006A)
                            : Colors.transparent,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      type,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFFB2006A)
                            : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Tên nguồn tiền (VD: Thẻ VCB, Tiền mặt)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _balanceController,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Số dư ban đầu (đ)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveWallet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB2006A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Lưu nguồn tiền',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
