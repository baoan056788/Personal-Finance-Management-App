import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/budget_model.dart';
import '../../../models/category_model.dart';
import '../../../controllers/budget_controller.dart';
import '../../../controllers/category_controller.dart';

class CreateBudgetScreen extends StatefulWidget {
  const CreateBudgetScreen({super.key});

  @override
  State<CreateBudgetScreen> createState() => _CreateBudgetScreenState();
}

class _CreateBudgetScreenState extends State<CreateBudgetScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  
  final BudgetController _budgetController = BudgetController();
  final CategoryController _categoryController = CategoryController();
  
  CategoryModel? _selectedCategory;
  String _periodType = 'MONTHLY'; // DAILY, WEEKLY, MONTHLY, YEARLY
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0); // Last day of month
  
  bool _isLoading = false;
  final Color momoPink = const Color(0xFFD82D8B);

  @override
  void initState() {
    super.initState();
  }
  
  void _updateDatesBasedOnPeriod() {
    final now = DateTime.now();
    switch (_periodType) {
      case 'DAILY':
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'WEEKLY':
        int currentWeekday = now.weekday;
        _startDate = now.subtract(Duration(days: currentWeekday - 1));
        _startDate = DateTime(_startDate.year, _startDate.month, _startDate.day);
        _endDate = _startDate.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        break;
      case 'MONTHLY':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case 'YEARLY':
        _startDate = DateTime(now.year, 1, 1);
        _endDate = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
      case 'CUSTOM':
        // Keep user's manual selection
        break;
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: momoPink, onPrimary: Colors.white, onSurface: Colors.black),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _periodType = 'CUSTOM';
        if (isStart) {
          _startDate = DateTime(picked.year, picked.month, picked.day);
        } else {
          _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        }
      });
    }
  }

  Future<void> _saveBudget() async {
    final amountText = _amountController.text.replaceAll(',', '').replaceAll('.', '');
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập giới hạn ngân sách')));
      return;
    }
    
    final limitAmount = double.tryParse(amountText);
    if (limitAmount == null || limitAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Giới hạn ngân sách phải lớn hơn 0')));
      return;
    }
    
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn danh mục')));
      return;
    }

    if (_startDate.isAfter(_endDate)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ngày kết thúc phải sau ngày bắt đầu')));
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final name = _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Ngân sách ${_selectedCategory!.name}';
      
      final newBudget = BudgetModel(
        id: '',
        userId: '', // populated in controller
        categoryId: _selectedCategory!.id,
        name: name,
        limitAmount: limitAmount,
        spentAmount: 0,
        remainAmount: limitAmount,
        progressPercent: 0,
        startDate: _startDate,
        endDate: _endDate,
        periodType: _periodType,
        note: _noteController.text.trim(),
        status: 'SAFE',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _budgetController.createBudget(newBudget);
      
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tạo ngân sách thành công!'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Thêm Ngân Sách', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Giới hạn ngân sách *', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
                          decoration: const InputDecoration(
                            hintText: '0',
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      const Text('đ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text('Tên ngân sách', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                    decoration: const InputDecoration(
                      hintText: 'VD: Ngân sách tháng này',
                      hintStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.normal),
                      border: InputBorder.none,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text('Danh mục *', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 12),
                  _buildCategoryList(),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text('Chu kỳ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  DropdownButton<String>(
                    value: _periodType,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'DAILY', child: Text('Hàng ngày')),
                      DropdownMenuItem(value: 'WEEKLY', child: Text('Hàng tuần')),
                      DropdownMenuItem(value: 'MONTHLY', child: Text('Hàng tháng')),
                      DropdownMenuItem(value: 'YEARLY', child: Text('Hàng năm')),
                      DropdownMenuItem(value: 'CUSTOM', child: Text('Tùy chỉnh')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _periodType = val;
                          _updateDatesBasedOnPeriod();
                        });
                      }
                    },
                  ),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Từ ngày', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            InkWell(
                              onTap: () => _selectDate(context, true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Text(DateFormat('dd/MM/yyyy').format(_startDate)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Đến ngày', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            InkWell(
                              onTap: () => _selectDate(context, false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Text(DateFormat('dd/MM/yyyy').format(_endDate)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text('Ghi chú', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  TextField(
                    controller: _noteController,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                    decoration: const InputDecoration(
                      hintText: 'Nhập ghi chú (tùy chọn)',
                      hintStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.normal),
                      border: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, -2),
              blurRadius: 10,
            )
          ]
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveBudget,
            style: ElevatedButton.styleFrom(
              backgroundColor: momoPink,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              minimumSize: const Size.fromHeight(56),
            ),
            child: _isLoading 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Lưu Ngân Sách', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    return StreamBuilder<List<CategoryModel>>(
      stream: _categoryController.getCategories('expense'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final categories = snapshot.data ?? [];
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: categories.map((cat) {
              final isSelected = _selectedCategory?.id == cat.id;
              final catColor = Color(int.parse(cat.colorHex.replaceFirst('#', ''), radix: 16));
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
                          color: isSelected ? const Color(0xFFFFF0F6) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? momoPink : Colors.transparent, width: 1),
                        ),
                        child: Icon(catIcon, color: isSelected ? momoPink : catColor, size: 24),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cat.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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
    );
  }
}
