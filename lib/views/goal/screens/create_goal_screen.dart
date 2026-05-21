import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../../models/goal_model.dart';
import '../../../controllers/goal_controller.dart';

class CreateGoalScreen extends StatefulWidget {
  final GoalModel? editGoal;
  const CreateGoalScreen({super.key, this.editGoal});

  @override
  State<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends State<CreateGoalScreen> {
  final GoalController _goalController = GoalController();
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  
  DateTime _targetDate = DateTime.now().add(const Duration(days: 30));
  Color _selectedColor = const Color(0xFFE91E63); // Pink
  IconData _selectedIcon = Icons.savings_rounded;

  bool _isLoading = false;

  final List<IconData> _iconList = [
    Icons.savings_rounded, Icons.phone_iphone_rounded, Icons.directions_car_rounded,
    Icons.flight_takeoff_rounded, Icons.computer_rounded, Icons.school_rounded,
    Icons.home_rounded, Icons.health_and_safety_rounded, Icons.shopping_bag_rounded,
    Icons.cake_rounded, Icons.pets_rounded, Icons.fitness_center_rounded,
  ];

  final List<Color> _colorList = [
    const Color(0xFFE91E63), // Pink
    const Color(0xFF9C27B0), // Purple
    const Color(0xFF3F51B5), // Indigo
    const Color(0xFF2196F3), // Blue
    const Color(0xFF00BCD4), // Cyan
    const Color(0xFF4CAF50), // Green
    const Color(0xFFFF9800), // Orange
    const Color(0xFFFF5722), // Deep Orange
  ];

  @override
  void initState() {
    super.initState();
    if (widget.editGoal != null) {
      _nameController.text = widget.editGoal!.name;
      _amountController.text = NumberFormat.decimalPattern('vi_VN').format(widget.editGoal!.targetAmount);
      _noteController.text = widget.editGoal!.note;
      _targetDate = widget.editGoal!.targetDate;
      _selectedColor = Color(int.parse(widget.editGoal!.colorHex, radix: 16));
      _selectedIcon = IconData(int.parse(widget.editGoal!.iconCode, radix: 16), fontFamily: 'MaterialIcons');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _selectedColor,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _targetDate) {
      setState(() {
        _targetDate = picked;
      });
    }
  }

  void _showIconAndColorPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 20),
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                  const Text('Tùy chỉnh biểu tượng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  
                  // Color Picker
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Align(alignment: Alignment.centerLeft, child: Text('Màu sắc', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _colorList.length,
                      itemBuilder: (context, index) {
                        final color = _colorList[index];
                        final isSelected = _selectedColor == color;
                        return GestureDetector(
                          onTap: () {
                            setModalState(() => _selectedColor = color);
                            setState(() => _selectedColor = color);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            width: isSelected ? 40 : 32,
                            height: isSelected ? 40 : 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected ? Border.all(color: Colors.black12, width: 3) : null,
                              boxShadow: isSelected ? [BoxShadow(color: color.withAlpha(100), blurRadius: 8, offset: const Offset(0, 4))] : null,
                            ),
                            child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  // Icon Picker
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Align(alignment: Alignment.centerLeft, child: Text('Biểu tượng', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _iconList.length,
                      itemBuilder: (context, index) {
                        final icon = _iconList[index];
                        final isSelected = _selectedIcon == icon;
                        return GestureDetector(
                          onTap: () {
                            setModalState(() => _selectedIcon = icon);
                            setState(() => _selectedIcon = icon);
                            Future.delayed(const Duration(milliseconds: 200), () { 
                              if (context.mounted) Navigator.pop(context); 
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isSelected ? _selectedColor : _selectedColor.withAlpha(20),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(icon, color: isSelected ? Colors.white : _selectedColor, size: 28),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final amount = double.parse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), ''));
      
      final goal = GoalModel(
        id: widget.editGoal?.id ?? '',
        userId: widget.editGoal?.userId ?? '',
        name: _nameController.text.trim(),
        targetAmount: amount,
        targetDate: _targetDate,
        note: _noteController.text.trim(),
        colorHex: _selectedColor.toARGB32().toRadixString(16).padLeft(8, '0'),
        iconCode: _selectedIcon.codePoint.toRadixString(16),
        createdAt: widget.editGoal?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.editGoal == null) {
        await _goalController.createGoal(goal);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tạo mục tiêu thành công!')));
      } else {
        await _goalController.updateGoal(goal);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật mục tiêu thành công!')));
      }
      
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    void Function(String)? onChanged,
    Widget? prefixText,
    TextStyle? style,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withAlpha(15), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        style: style ?? const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(icon, color: _selectedColor),
          prefix: prefixText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int remainingDays = _targetDate.difference(DateTime.now()).inDays;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(widget.editGoal == null ? 'Tạo mục tiêu mới' : 'Sửa mục tiêu', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator(color: _selectedColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Picker Hero
                    Center(
                      child: GestureDetector(
                        onTap: _showIconAndColorPicker,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 100, height: 100,
                          decoration: BoxDecoration(
                            color: _selectedColor.withAlpha(25),
                            shape: BoxShape.circle,
                            border: Border.all(color: _selectedColor, width: 3),
                            boxShadow: [
                              BoxShadow(color: _selectedColor.withAlpha(40), blurRadius: 20, offset: const Offset(0, 10)),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(_selectedIcon, size: 48, color: _selectedColor),
                              Positioned(
                                bottom: 0, right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                  child: Icon(Icons.edit, size: 16, color: _selectedColor),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    _buildTextField(
                      controller: _nameController,
                      label: 'Tên mục tiêu',
                      hintText: 'Ví dụ: Mua iPhone 15 Pro, Du lịch...',
                      icon: Icons.flag_rounded,
                      validator: (val) => val == null || val.isEmpty ? 'Vui lòng nhập tên mục tiêu' : null,
                    ),
                    const SizedBox(height: 20),
                    
                    _buildTextField(
                      controller: _amountController,
                      label: 'Số tiền cần đạt',
                      hintText: '10.000.000',
                      icon: Icons.monetization_on_rounded,
                      keyboardType: TextInputType.number,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _selectedColor),
                      onChanged: (value) {
                        String clean = value.replaceAll(RegExp(r'[^0-9]'), '');
                        if (clean.isNotEmpty) {
                          String formatted = NumberFormat.decimalPattern('vi_VN').format(int.parse(clean));
                          _amountController.value = TextEditingValue(
                            text: formatted,
                            selection: TextSelection.collapsed(offset: formatted.length),
                          );
                        }
                      },
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Vui lòng nhập số tiền';
                        if (double.tryParse(val.replaceAll(RegExp(r'[^0-9]'), '')) == null || double.parse(val.replaceAll(RegExp(r'[^0-9]'), '')) <= 0) return 'Số tiền phải lớn hơn 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.grey.withAlpha(15), blurRadius: 10, offset: const Offset(0, 5)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, color: _selectedColor),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Ngày hoàn thành mục tiêu', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('dd/MM/yyyy').format(_targetDate),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: _selectedColor.withAlpha(20), borderRadius: BorderRadius.circular(10)),
                              child: Text(
                                remainingDays > 0 ? 'Còn $remainingDays ngày' : 'Quá hạn',
                                style: TextStyle(color: _selectedColor, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildTextField(
                      controller: _noteController,
                      label: 'Ghi chú (Tùy chọn)',
                      hintText: 'Thêm vài dòng động lực cho bản thân...',
                      icon: Icons.edit_note_rounded,
                    ),
                    const SizedBox(height: 32),

                    // Motivation Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha(20),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue.withAlpha(50)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lightbulb_rounded, color: Colors.blue, size: 28),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Mọi ước mơ lớn đều bắt đầu từ một khoản tiết kiệm nhỏ. Bắt đầu ngay hôm nay!',
                              style: TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.w500, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _saveGoal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 8,
                          shadowColor: _selectedColor.withAlpha(100),
                        ),
                        child: Text(widget.editGoal == null ? 'Tạo Mục Tiêu' : 'Lưu Thay Đổi', style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}
