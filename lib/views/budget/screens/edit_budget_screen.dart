import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/budget_model.dart';
import '../../../models/category_model.dart';
import '../../../controllers/budget_controller.dart';
import '../../../controllers/category_controller.dart';

class EditBudgetScreen extends StatefulWidget {
  final BudgetModel budget;
  const EditBudgetScreen({super.key, required this.budget});

  @override
  State<EditBudgetScreen> createState() => _EditBudgetScreenState();
}

class _EditBudgetScreenState extends State<EditBudgetScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  
  final BudgetController _budgetController = BudgetController();
  final CategoryController _categoryController = CategoryController();
  
  CategoryModel? _selectedCategory;
  String _periodType = 'MONTHLY'; 
  late DateTime _startDate;
  late DateTime _endDate; 
  
  bool _isLoading = false;
  final Color momoPink = const Color(0xFFE91E63);

  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '');
  
  @override
  void initState() {
    super.initState();
    _amountController.addListener(_formatCurrency);
    
    // Initialize with existing budget data
    _nameController.text = widget.budget.name;
    final String amountStr = widget.budget.limitAmount.toInt().toString();
    _amountController.value = TextEditingValue(
      text: _currencyFormat.format(int.parse(amountStr)).trim(),
    );
    _noteController.text = widget.budget.note;
    _periodType = widget.budget.periodType;
    _startDate = widget.budget.startDate;
    _endDate = widget.budget.endDate;
    
    _loadCategory();
  }

  Future<void> _loadCategory() async {
    final cat = await _categoryController.getCategoryById(widget.budget.categoryId);
    if (mounted && cat != null) {
      setState(() => _selectedCategory = cat);
    }
  }
  
  void _formatCurrency() {
    String text = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.isNotEmpty) {
      final formatted = _currencyFormat.format(int.parse(text)).trim();
      if (_amountController.text != formatted) {
        _amountController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    }
  }

  @override
  void dispose() {
    _amountController.removeListener(_formatCurrency);
    _amountController.dispose();
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
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

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCategoryBottomSheet(),
    );
  }

  Widget _buildCategoryBottomSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          const Text('Chọn danh mục', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<CategoryModel>>(
              stream: _categoryController.getCategories('expense'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final categories = snapshot.data ?? [];
                
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 24,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final catColor = Color(int.parse(cat.colorHex.replaceFirst('#', ''), radix: 16));
                    final catIcon = IconData(int.parse(cat.iconCode, radix: 16), fontFamily: 'MaterialIcons');
                    final isSelected = _selectedCategory?.id == cat.id;

                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedCategory = cat);
                        Navigator.pop(context);
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 56, height: 56,
                            decoration: BoxDecoration(
                              color: isSelected ? momoPink : catColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: isSelected ? [BoxShadow(color: momoPink.withAlpha(80), blurRadius: 10, offset: const Offset(0, 4))] : null,
                            ),
                            child: Icon(catIcon, color: isSelected ? Colors.white : catColor, size: 28),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cat.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? momoPink : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveBudget() async {
    final amountText = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
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
      
      final updatedBudget = widget.budget.copyWith(
        categoryId: _selectedCategory!.id,
        name: name,
        limitAmount: limitAmount,
        startDate: _startDate,
        endDate: _endDate,
        periodType: _periodType,
        note: _noteController.text.trim(),
        updatedAt: DateTime.now(),
      );

      await _budgetController.updateBudget(updatedBudget);
      
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật ngân sách thành công!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Sửa Ngân Sách', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Column(
                children: [
                  const Text('Số tiền hạn mức', style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      IntrinsicWidth(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.black87),
                          decoration: InputDecoration(
                            hintText: '0',
                            hintStyle: TextStyle(color: Colors.grey.shade300),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text('đ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                    ],
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Tên ngân sách (Tùy chọn)'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: _nameController,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      decoration: const InputDecoration(
                        hintText: 'VD: Chi tiêu tháng này',
                        hintStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.normal),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('Danh mục *'),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _showCategoryPicker,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _selectedCategory != null ? momoPink.withAlpha(15) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _selectedCategory != null ? momoPink.withAlpha(50) : Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          if (_selectedCategory != null) ...[
                            Icon(
                              IconData(int.parse(_selectedCategory!.iconCode, radix: 16), fontFamily: 'MaterialIcons'),
                              color: Color(int.parse(_selectedCategory!.colorHex.replaceFirst('#', ''), radix: 16)),
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(_selectedCategory!.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
                              child: const Icon(Icons.grid_view_rounded, color: Colors.grey, size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(child: Text('Đang tải danh mục...', style: TextStyle(fontSize: 16, color: Colors.grey))),
                          ],
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('Chu kỳ'),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: momoPink.withAlpha(20),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: DropdownButton<String>(
                          value: _periodType,
                          underline: const SizedBox(),
                          icon: Icon(Icons.keyboard_arrow_down, color: momoPink),
                          style: TextStyle(color: momoPink, fontWeight: FontWeight.bold, fontSize: 14),
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectDate(context, true),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Từ ngày', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16, color: Colors.black87),
                                    const SizedBox(width: 8),
                                    Text(DateFormat('dd/MM/yy').format(_startDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectDate(context, false),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Đến ngày', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.event, size: 16, color: Colors.black87),
                                    const SizedBox(width: 8),
                                    Text(DateFormat('dd/MM/yy').format(_endDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('Ghi chú (Tùy chọn)'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: _noteController,
                      maxLines: 3,
                      minLines: 1,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      decoration: const InputDecoration(
                        hintText: 'Thêm ghi chú của bạn',
                        hintStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.normal),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveBudget,
            style: ElevatedButton.styleFrom(
              backgroundColor: momoPink,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              shadowColor: momoPink.withAlpha(100),
            ),
            child: _isLoading 
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
              : const Text('Lưu Thay Đổi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
    );
  }
}
