import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../../../models/recurring_transaction_model.dart';
import '../../../models/category_model.dart';
import '../../../models/wallet_model.dart';
import '../../../controllers/category_controller.dart';
import '../../../controllers/recurring_transaction_controller.dart';
import '../services/wallet_service.dart';
import '../widgets/frequency_bottom_sheet.dart';

class AddRecurringTransactionScreen extends StatefulWidget {
  final RecurringTransactionModel? initialTransaction; // NEW: support edit mode
  const AddRecurringTransactionScreen({super.key, this.initialTransaction});

  @override
  State<AddRecurringTransactionScreen> createState() => _AddRecurringTransactionScreenState();
}

class _AddRecurringTransactionScreenState extends State<AddRecurringTransactionScreen> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  
  CategoryModel? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  String _frequency = 'Hằng tháng'; // Default for recurring
  DateTime? _endDate;
  bool _isLoading = false;

  File? _selectedImage;
  String? _remoteImageUrl; // For editing
  final ImagePicker _picker = ImagePicker();

  final CategoryController _categoryController = CategoryController();
  final RecurringTransactionController _recurringController = RecurringTransactionController();
  final WalletService _walletService = WalletService();

  List<WalletModel> _wallets = [];
  WalletModel? _selectedWallet;

  final Color momoPink = const Color(0xFFD82D8B);
  final Color momoHeaderBg = const Color(0xFFF9EEF3);
  final Color momoBgLight = const Color(0xFFF8F8F8);

  bool get _isEditing => widget.initialTransaction != null;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _noteController = TextEditingController();
    _loadWallets();
    _initEditMode();
  }

  void _initEditMode() async {
    if (_isEditing) {
      final tx = widget.initialTransaction!;
      _amountController.text = tx.amount.toInt().toString();
      _noteController.text = tx.name; // In recurring, name is the note/purpose
      _frequency = tx.frequency;
      _selectedDate = tx.nextDueDate;
      _endDate = tx.endDate;
      _remoteImageUrl = tx.imageUrl;
      
      // Load and select category
      final cats = await _categoryController.getAllCategories();
      try {
        _selectedCategory = cats.firstWhere((c) => c.id == tx.categoryId);
      } catch (_) {}
      
      if (mounted) setState(() {});
    }
  }

  void _loadWallets() {
    _walletService.getWallets().listen((wallets) {
      if (mounted) {
        setState(() {
          _wallets = wallets;
          if (_isEditing && _selectedWallet == null) {
             try {
               _selectedWallet = _wallets.firstWhere((w) => w.id == widget.initialTransaction!.walletId);
             } catch (_) {}
          }
          
          if (_selectedWallet != null) {
            try {
              _selectedWallet = _wallets.firstWhere((w) => w.id == _selectedWallet!.id);
            } catch (_) {
              _selectedWallet = _wallets.isNotEmpty ? _wallets.first : null;
            }
          } else if (_wallets.isNotEmpty) {
            _selectedWallet = _wallets.first;
          }
        });
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: _isEditing ? DateTime(2000) : DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: momoPink,
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

  void _openFrequencySheet() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: FrequencyBottomSheet(
          initialFrequency: _frequency,
          initialEndDate: _endDate,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _frequency = result['frequency'];
        _endDate = result['endDate'];
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _remoteImageUrl = null;
      });
    }
  }

  Future<void> _saveRecurringTransaction() async {
    final amountText = _amountController.text.replaceAll(',', '').replaceAll('.', '');
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ')));
      return;
    }
    
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Số tiền phải lớn hơn 0')));
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn danh mục')));
      return;
    }

    if (_selectedWallet == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn nguồn tiền')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Người dùng chưa đăng nhập');

      String? imageUrl = _remoteImageUrl;
      if (_selectedImage != null) {
        try {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('recurring_transactions')
              .child(user.uid)
              .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
              
          final uploadTask = storageRef.putData(await _selectedImage!.readAsBytes());
          final snapshot = await uploadTask.whenComplete(() => null);
          imageUrl = await snapshot.ref.getDownloadURL();
        } catch (e) {
          final directory = await getApplicationDocumentsDirectory();
          final fileName = '${DateTime.now().millisecondsSinceEpoch}${path.extension(_selectedImage!.path)}';
          final savedImage = await _selectedImage!.copy('${directory.path}/$fileName');
          imageUrl = savedImage.path;
        }
      }

      final transaction = RecurringTransactionModel(
        id: _isEditing ? widget.initialTransaction!.id : '',
        userId: user.uid,
        name: _noteController.text.trim().isEmpty ? _selectedCategory!.name : _noteController.text.trim(),
        amount: amount,
        type: _isEditing ? widget.initialTransaction!.type : 'expense',
        categoryId: _selectedCategory!.id,
        walletId: _selectedWallet!.id,
        frequency: _frequency,
        nextDueDate: _selectedDate,
        createdAt: _isEditing ? widget.initialTransaction!.createdAt : DateTime.now(),
        endDate: _endDate,
        imageUrl: imageUrl,
      );

      if (_isEditing) {
        await _recurringController.updateRecurringTransaction(transaction);
      } else {
        await _recurringController.addRecurringTransaction(transaction);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? 'Đã cập nhật thiết lập định kỳ!' : 'Đã thêm thiết lập định kỳ thành công!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.redAccent),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: momoBgLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: momoHeaderBg,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isEditing ? 'Sửa Thiết Lập Định Kỳ' : 'Thêm Giao Dịch Định Kỳ',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.help_outline, color: Colors.black54),
                        onPressed: () {},
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.home_outlined, color: Colors.black54),
                        onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Upload
                    const Text('Hình ảnh đính kèm', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (_selectedImage != null || _remoteImageUrl != null)
                          Container(
                            width: 80,
                            height: 80,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                              image: _selectedImage != null 
                                ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                                : DecorationImage(image: NetworkImage(_remoteImageUrl!), fit: BoxFit.cover),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: GestureDetector(
                                    onTap: () => setState(() { _selectedImage = null; _remoteImageUrl = null; }),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.black87,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, size: 12, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, color: Colors.grey),
                                SizedBox(height: 4),
                                Text('Thêm ảnh', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Amount
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 2, offset: const Offset(0, 1))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Số tiền *', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _amountController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                                  decoration: const InputDecoration(
                                    hintText: '0',
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.only(top: 4),
                                  ),
                                ),
                              ),
                              const Text('đ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category Selector
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 2, offset: const Offset(0, 1))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Danh mục *', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 12),
                          StreamBuilder<List<CategoryModel>>(
                            stream: _categoryController.getCategories(_isEditing ? widget.initialTransaction!.type : 'expense'),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              final categories = snapshot.data ?? [];
                              if (categories.isEmpty) return const Text('Chưa có danh mục nào.', style: TextStyle(color: Colors.grey));

                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: categories.map((cat) {
                                    final isSelected = _selectedCategory?.id == cat.id;
                                    final catIcon = IconData(int.parse(cat.iconCode, radix: 16), fontFamily: 'MaterialIcons');

                                    return GestureDetector(
                                      onTap: () => setState(() => _selectedCategory = cat),
                                      child: Container(
                                        width: 72,
                                        margin: const EdgeInsets.only(right: 8),
                                        child: Column(
                                          children: [
                                            Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: isSelected ? Colors.pink.shade50 : Colors.grey.shade50,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: isSelected ? momoPink : Colors.grey.shade200,
                                                  width: isSelected ? 2 : 1,
                                                ),
                                              ),
                                              child: Icon(catIcon, color: isSelected ? momoPink : Colors.grey.shade400, size: 24),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              cat.name,
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                color: isSelected ? momoPink : Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            }
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade100),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 2, offset: const Offset(0, 1))],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Ngày bắt đầu / Kỳ tiếp theo *', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('EEEE, dd/MM/yyyy', 'vi_VN').format(_selectedDate),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                                ),
                              ],
                            ),
                            const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Frequency
                    GestureDetector(
                      onTap: _openFrequencySheet,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade100),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 2, offset: const Offset(0, 1))],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Tần suất lặp lại', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                const SizedBox(height: 4),
                                Text(_frequency, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
                              ],
                            ),
                            const Icon(Icons.autorenew, size: 20, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Wallet Source
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 2, offset: const Offset(0, 1))],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Nguồn tiền *', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                const SizedBox(height: 2),
                                if (_wallets.isEmpty)
                                  const Text('Đang tải...', style: TextStyle(fontSize: 14))
                                else
                                  DropdownButtonHideUnderline(
                                    child: DropdownButton<WalletModel>(
                                      value: _selectedWallet,
                                      isDense: true,
                                      isExpanded: true,
                                      icon: const SizedBox.shrink(),
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                                      items: _wallets.map((w) => DropdownMenuItem(value: w, child: Text(w.name))).toList(),
                                      onChanged: (val) => setState(() => _selectedWallet = val),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Note
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 2, offset: const Offset(0, 1))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ghi chú / Tên hóa đơn', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          TextField(
                            controller: _noteController,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                            decoration: const InputDecoration(
                              hintText: 'Nhập tên hóa đơn hoặc mô tả',
                              hintStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.normal),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100), // Padding for sticky bottom button
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade50)),
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveRecurringTransaction,
            style: ElevatedButton.styleFrom(
              backgroundColor: momoPink,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              minimumSize: const Size.fromHeight(56),
            ),
            child: _isLoading 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(_isEditing ? 'Lưu thay đổi' : 'Thêm giao dịch định kỳ', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ),
    );
  }
}
