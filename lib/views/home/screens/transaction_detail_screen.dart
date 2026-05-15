import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/transaction_model.dart';
import '../../../models/category_model.dart';
import '../../../controllers/category_controller.dart';
import '../../wallet/services/transaction_service.dart';
import '../../wallet/screens/add_transaction_screen.dart';

class TransactionDetailScreen extends StatefulWidget {
  final TransactionModel transaction;
  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  final TransactionService _transactionService = TransactionService();
  final CategoryController _categoryController = CategoryController();
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  late TransactionModel _currentTransaction;

  final Color momoPink = const Color(0xFFE0248A);

  @override
  void initState() {
    super.initState();
    _currentTransaction = widget.transaction;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await _categoryController.getAllCategories();
    if (mounted) setState(() => _categories = cats);
  }

  CategoryModel? _findCategory() {
    final tx = _currentTransaction;
    String? targetId = tx.categoryId;
    String? name = tx.category;

    if ((targetId == null || targetId.isEmpty) && name.isNotEmpty && !name.contains(' ') && name.length > 15) {
      targetId = name;
    }

    if (targetId != null && targetId.isNotEmpty) {
      try { return _categories.firstWhere((c) => c.id == targetId); } catch (_) {}
    }
    if (name.isNotEmpty) {
      final lc = name.toLowerCase().trim();
      try { return _categories.firstWhere((c) => c.name.toLowerCase().trim() == lc); } catch (_) {}
    }
    return null;
  }

  Future<void> _deleteTransaction() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa giao dịch'),
        content: const Text('Bạn có chắc chắn muốn xóa giao dịch này không? Số dư ví sẽ được cập nhật lại.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Xóa', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await _transactionService.deleteTransactionGlobal(_currentTransaction);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa giao dịch thành công'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _editTransaction() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(initialTransaction: _currentTransaction),
      ),
    );

    if (result == true) {
      // Refresh the screen
      final updatedTxs = await _transactionService.getAllTransactionsGlobal();
      try {
        final updated = updatedTxs.firstWhere((tx) => tx.id == _currentTransaction.id);
        if (mounted) setState(() => _currentTransaction = updated);
      } catch (_) {
        if (mounted) Navigator.pop(context, true); // Tx might have been moved/deleted
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tx = _currentTransaction;
    final cat = _findCategory();
    final isExpense = tx.type == 'expense';
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Chi tiết giao dịch', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: _isLoading ? null : _deleteTransaction),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: Color(0xFFE0248A))) : SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(bottom: Radius.circular(24))),
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                   _buildCategoryIcon(cat),
                   const SizedBox(height: 16),
                   Text(cat?.name ?? (tx.category.length > 15 ? "Khác" : tx.category), style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500)),
                   const SizedBox(height: 8),
                   Text('${isExpense ? '-' : '+'}${NumberFormat('#,###').format(tx.amount)}đ', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: isExpense ? Colors.red : Colors.green)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildDetailRow(Icons.calendar_today_outlined, 'Thời gian', DateFormat('EEEE, dd/MM/yyyy HH:mm', 'vi_VN').format(tx.createdAt)),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Color(0xFFF5F5F5))),
                  _buildDetailRow(Icons.notes, 'Ghi chú', tx.note.isNotEmpty ? tx.note : 'Không có ghi chú'),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Color(0xFFF5F5F5))),
                  _buildDetailRow(Icons.wallet, 'Nguồn tiền', 'Ví của tôi'),
                  if (tx.isRecurring) ...[
                    const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Color(0xFFF5F5F5))),
                    _buildDetailRow(Icons.repeat, 'Tần suất', 'Hằng tháng (Định kỳ)'),
                  ],
                ],
              ),
            ),
            if (tx.imageUrl != null && tx.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Hình ảnh đính kèm', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: tx.imageUrl!.startsWith('http') 
                        ? Image.network(tx.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildImagePlaceholder())
                        : Image.file(File(tx.imageUrl!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildImagePlaceholder()),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _editTransaction,
                style: ElevatedButton.styleFrom(backgroundColor: momoPink, minimumSize: const Size.fromHeight(56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                child: const Text('Chỉnh sửa giao dịch', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() => Container(height: 150, width: double.infinity, color: Colors.grey.shade100, child: const Icon(Icons.broken_image_outlined, color: Colors.grey));

  Widget _buildCategoryIcon(CategoryModel? cat) {
    if (cat != null) {
      try {
        final hex = cat.colorHex.replaceFirst('#', '');
        final color = Color(int.parse(hex, radix: 16));
        return Container(
          width: 72, height: 72, decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
          child: Icon(IconData(int.parse(cat.iconCode, radix: 16), fontFamily: 'MaterialIcons'), color: color, size: 36),
        );
      } catch (_) {}
    }
    return CircleAvatar(radius: 36, backgroundColor: Colors.grey.shade100, child: const Icon(Icons.attach_money, color: Colors.grey, size: 36));
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 18, color: Colors.black54)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87))])),
    ]);
  }
}
