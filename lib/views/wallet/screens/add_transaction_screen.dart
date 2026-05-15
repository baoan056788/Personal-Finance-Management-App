import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';

import '../../../models/wallet_model.dart';
import '../../../models/transaction_model.dart';
import '../../../models/category_model.dart';
import '../../../controllers/category_controller.dart';
import '../services/transaction_service.dart';
import '../services/wallet_service.dart';
import '../widgets/frequency_bottom_sheet.dart';

class AddTransactionScreen extends StatefulWidget {
  final WalletModel? wallet;
  final TransactionModel? initialTransaction; // NEW: support edit mode

  const AddTransactionScreen({super.key, this.wallet, this.initialTransaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  
  String _transactionType = 'expense';
  CategoryModel? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  final TransactionService _transactionService = TransactionService();
  final WalletService _walletService = WalletService();
  final CategoryController _categoryController = CategoryController();

  List<WalletModel> _wallets = [];
  WalletModel? _selectedWallet;
  
  String _frequency = 'Không lặp lại';
  DateTime? _endDate;

  File? _selectedImage;
  String? _remoteImageUrl; // For editing
  final ImagePicker _picker = ImagePicker();

  final Color momoPink = const Color(0xFFD82D8B);
  final Color momoLightPink = const Color(0xFFFFF0F6);
  final Color momoBg = const Color(0xFFF2F2F2);

  bool get _isEditing => widget.initialTransaction != null;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _noteController = TextEditingController();
    
    _categoryController.setupDefaultCategoriesIfNeeded();
    _selectedWallet = widget.wallet;
    _loadWallets();
    _initEditMode();
  }

  void _initEditMode() async {
    if (_isEditing) {
      final tx = widget.initialTransaction!;
      _amountController.text = tx.amount.toInt().toString();
      _noteController.text = tx.note;
      _transactionType = tx.type;
      _selectedDate = tx.createdAt;
      _remoteImageUrl = tx.imageUrl;
      
      // Load and select category
      final cats = await _categoryController.getAllCategories();
      try {
        if (tx.categoryId != null) {
          _selectedCategory = cats.firstWhere((c) => c.id == tx.categoryId);
        } else {
          _selectedCategory = cats.firstWhere((c) => c.name == tx.category);
        }
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
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: momoPink, onPrimary: Colors.white, onSurface: Colors.black)),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  void _openFrequencySheet() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: FrequencyBottomSheet(initialFrequency: _frequency, initialEndDate: _endDate),
      ),
    );
    if (result != null) {
      setState(() { _frequency = result['frequency']; _endDate = result['endDate']; });
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) setState(() { _selectedImage = File(image.path); _remoteImageUrl = null; });
  }

  Future<void> _saveTransaction() async {
    final amountText = _amountController.text.replaceAll(',', '').replaceAll('.', '');
    if (amountText.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ'))); return; }
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Số tiền phải lớn hơn 0'))); return; }
    if (_selectedCategory == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn danh mục'))); return; }
    if (_selectedWallet == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn nguồn tiền'))); return; }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Người dùng chưa đăng nhập');

      String? imageUrl = _remoteImageUrl;
      if (_selectedImage != null) {
        try {
          final storageRef = FirebaseStorage.instance.ref().child('transactions').child(user.uid).child('${DateTime.now().millisecondsSinceEpoch}.jpg');
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

      final transaction = TransactionModel(
        id: _isEditing ? widget.initialTransaction!.id : FirebaseFirestore.instance.collection('dummy').doc().id,
        amount: amount,
        type: _transactionType,
        category: _selectedCategory!.name,
        categoryId: _selectedCategory!.id,
        note: _noteController.text.trim(),
        createdAt: _selectedDate,
        imageUrl: imageUrl,
        walletId: _selectedWallet!.id,
      );

      if (_isEditing) {
        await _transactionService.updateTransaction(_selectedWallet!.id, widget.initialTransaction!, transaction);
      } else {
        await _transactionService.createTransaction(_selectedWallet!.id, transaction, _selectedWallet!.balance);
      }

      // Handle recurring (simplified: only for new or if not changed much)
      if (!_isEditing && _frequency != 'Không lặp lại') {
        final recurringRef = FirebaseFirestore.instance.collection('recurring_transactions').doc();
        await recurringRef.set({
          'id': recurringRef.id, 'userId': user.uid, 'name': _noteController.text.trim().isEmpty ? _selectedCategory!.name : _noteController.text.trim(),
          'amount': amount, 'type': _transactionType, 'categoryId': _selectedCategory!.id, 'walletId': _selectedWallet!.id, 'frequency': _frequency,
          'nextDueDate': Timestamp.fromDate(_selectedDate), 'createdAt': Timestamp.fromDate(DateTime.now()),
          if (_endDate != null) 'endDate': Timestamp.fromDate(_endDate!), if (imageUrl != null) 'imageUrl': imageUrl,
        });
      }

      if (!mounted) return;
      Navigator.pop(context, true); // Return true to indicate change
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isEditing ? 'Đã cập nhật giao dịch!' : 'Đã thêm giao dịch!'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() { _amountController.dispose(); _noteController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: momoBg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    InkWell(onTap: () => Navigator.pop(context), borderRadius: BorderRadius.circular(20), child: const Padding(padding: EdgeInsets.all(4.0), child: Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87))),
                    const SizedBox(width: 12),
                    Text(_isEditing ? 'Sửa Giao Dịch' : 'Ghi Chép Giao Dịch', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ]),
                  Row(children: [
                    IconButton(icon: const Icon(Icons.help_outline, color: Colors.black54), onPressed: () {}, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                    const SizedBox(width: 16),
                    IconButton(icon: const Icon(Icons.home_outlined, color: Colors.black54), onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                  ]),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(30)),
                child: Row(
                  children: [
                    _buildTypeTab('expense', 'Chi tiêu', Icons.arrow_outward),
                    _buildTypeTab('income', 'Thu nhập', Icons.call_received),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 10),
                decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Hình ảnh đính kèm', style: TextStyle(color: Colors.grey, fontSize: 14)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (_selectedImage != null || _remoteImageUrl != null)
                            Container(
                              width: 80, height: 80, margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200),
                                image: _selectedImage != null 
                                  ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                                  : DecorationImage(image: NetworkImage(_remoteImageUrl!), fit: BoxFit.cover),
                              ),
                              child: Stack(children: [Positioned(top: -4, right: -4, child: GestureDetector(onTap: () => setState(() { _selectedImage = null; _remoteImageUrl = null; }), child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle), child: const Icon(Icons.close, size: 12, color: Colors.white))))]),
                            ),
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 80, height: 80,
                              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid, width: 2), borderRadius: BorderRadius.circular(8)),
                              child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_photo_alternate_outlined, color: Colors.grey), SizedBox(height: 4), Text('Thêm ảnh', style: TextStyle(fontSize: 10, color: Colors.grey))]),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Số tiền *', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            Row(children: [
                              Expanded(child: TextField(controller: _amountController, keyboardType: TextInputType.number, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87), decoration: const InputDecoration(hintText: '0', border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero))),
                              const Text('đ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                            ]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('Danh mục *', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 12),
                      _buildCategoryList(),
                      const SizedBox(height: 24),
                      const Text('Ngày giao dịch *', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      GestureDetector(
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text(DateFormat('EEEE, dd/MM/yyyy', 'vi_VN').format(_selectedDate), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
                            const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (!_isEditing) ...[
                        const Text('Tần suất lặp lại', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        GestureDetector(
                          onTap: _openFrequencySheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Text(_frequency, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
                              const Icon(Icons.autorenew, size: 20, color: Colors.grey),
                            ]),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      const Text('Nguồn tiền *', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Expanded(child: DropdownButtonHideUnderline(child: DropdownButton<WalletModel>(
                            value: _selectedWallet, isDense: true, isExpanded: true, icon: const SizedBox.shrink(),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                            items: _wallets.map((w) => DropdownMenuItem(value: w, child: Text(w.name))).toList(),
                            onChanged: (val) => setState(() => _selectedWallet = val),
                          ))),
                          const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      const Text('Ghi chú', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      TextField(controller: _noteController, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87), decoration: const InputDecoration(hintText: 'Nhập mô tả giao dịch', hintStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.normal), border: InputBorder.none, contentPadding: EdgeInsets.only(top: 8, bottom: 8), isDense: true)),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), offset: const Offset(0, -2), blurRadius: 10)]),
        child: SafeArea(child: ElevatedButton(
          onPressed: _isLoading ? null : _saveTransaction,
          style: ElevatedButton.styleFrom(backgroundColor: momoPink, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0, minimumSize: const Size.fromHeight(56)),
          child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(_isEditing ? 'Lưu thay đổi' : (_transactionType == 'expense' ? 'Thêm giao dịch chi' : 'Thêm giao dịch thu'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        )),
      ),
    );
  }

  Widget _buildTypeTab(String type, String label, IconData icon) {
    final isSelected = _transactionType == type;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() { _transactionType = type; if (!_isEditing) _selectedCategory = null; }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(30), boxShadow: isSelected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2)] : []),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 16, color: isSelected ? momoPink : Colors.grey.shade500), const SizedBox(width: 6), Text(label, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? momoPink : Colors.grey.shade500))]),
      ),
    ));
  }

  Widget _buildCategoryList() {
    return StreamBuilder<List<CategoryModel>>(
      stream: _categoryController.getCategories(_transactionType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final categories = snapshot.data ?? [];
        return SingleChildScrollView(scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: categories.map((cat) {
          final isSelected = _selectedCategory?.id == cat.id;
          final catColor = Color(int.parse(cat.colorHex.replaceFirst('#', ''), radix: 16));
          final catIcon = IconData(int.parse(cat.iconCode, radix: 16), fontFamily: 'MaterialIcons');
          return GestureDetector(onTap: () => setState(() => _selectedCategory = cat), child: Container(width: 72, margin: const EdgeInsets.only(right: 8), child: Column(children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: isSelected ? momoLightPink : Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? momoPink : Colors.transparent, width: 1)), child: Icon(catIcon, color: isSelected ? momoPink : catColor, size: 24)),
            const SizedBox(height: 8), Text(cat.name, textAlign: TextAlign.center, maxLines: 2, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? momoPink : Colors.grey.shade600)),
          ])));
        }).toList()));
      }
    );
  }
}
