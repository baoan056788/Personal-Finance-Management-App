import 'package:flutter/material.dart';
import '../../../controllers/category_controller.dart';
import '../../../models/category_model.dart';

class CreateCategoryScreen extends StatefulWidget {
  final String initialType; // 'expense' or 'income'

  const CreateCategoryScreen({super.key, required this.initialType});

  @override
  State<CreateCategoryScreen> createState() => _CreateCategoryScreenState();
}

class _CreateCategoryScreenState extends State<CreateCategoryScreen> {
  final CategoryController _categoryController = CategoryController();
  final TextEditingController _nameController = TextEditingController();
  
  late String _selectedType;
  String _selectedIconCode = 'e532'; // Default receipt icon
  String _selectedColorHex = 'FFB2006A'; // Default Primary color

  final List<String> _iconOptions = [
    'e532', // receipt
    'e531', // directions_car
    'e8cc', // shopping_cart
    'e8b0', // receipt_long
    'e53d', // attach_money
    'e838', // star
    'e873', // home
    'e52f', // restaurant
    'eb3f', // family_restroom
    'e8f9', // work
    'e333', // phone
    'e156', // local_hospital
  ];

  final List<String> _colorOptions = [
    'FFB2006A', // Primary Pink
    'FFF44336', // Red
    'FFE91E63', // Pink
    'FF9C27B0', // Purple
    'FF673AB7', // Deep Purple
    'FF3F51B5', // Indigo
    'FF2196F3', // Blue
    'FF03A9F4', // Light Blue
    'FF00BCD4', // Cyan
    'FF009688', // Teal
    'FF4CAF50', // Green
    'FF8BC34A', // Light Green
    'FFCDDC39', // Lime
    'FFFFEB3B', // Yellow
    'FFFFC107', // Amber
    'FFFF9800', // Orange
    'FFFF5722', // Deep Orange
    'FF795548', // Brown
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  void _saveCategory() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên danh mục'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final newCategory = CategoryModel(
      id: '',
      userId: '', // Will be set in controller
      name: name,
      type: _selectedType,
      iconCode: _selectedIconCode,
      colorHex: _selectedColorHex,
      isDefault: false,
    );

    await _categoryController.addCategory(newCategory);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _showIconPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 300,
          child: Column(
            children: [
              const Text('Chọn biểu tượng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _iconOptions.length,
                  itemBuilder: (context, index) {
                    final iconCode = _iconOptions[index];
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedIconCode = iconCode;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          IconData(int.parse(iconCode, radix: 16), fontFamily: 'MaterialIcons'),
                          color: Color(int.parse(_selectedColorHex.replaceFirst('#', ''), radix: 16)),
                        ),
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
  }

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 300,
          child: Column(
            children: [
              const Text('Chọn màu sắc', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _colorOptions.length,
                  itemBuilder: (context, index) {
                    final colorHex = _colorOptions[index];
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedColorHex = colorHex;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(int.parse(colorHex.replaceFirst('#', ''), radix: 16)),
                          shape: BoxShape.circle,
                        ),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCEEF5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tạo danh mục',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Tabs cho loại thu/chi
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedType = 'expense'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _selectedType == 'expense' ? const Color(0xFFB2006A) : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Chi tiêu',
                            style: TextStyle(
                              color: _selectedType == 'expense' ? const Color(0xFFB2006A) : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedType = 'income'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _selectedType == 'income' ? const Color(0xFFB2006A) : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Thu nhập',
                            style: TextStyle(
                              color: _selectedType == 'income' ? const Color(0xFFB2006A) : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Khối chọn icon và màu
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: _showIconPicker,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Color(int.parse(_selectedColorHex.replaceFirst('#', ''), radix: 16)).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        IconData(int.parse(_selectedIconCode, radix: 16), fontFamily: 'MaterialIcons'),
                        color: Color(int.parse(_selectedColorHex.replaceFirst('#', ''), radix: 16)),
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: _showIconPicker,
                        child: const Text('Đổi biểu tượng', style: TextStyle(color: Color(0xFFB2006A), fontWeight: FontWeight.bold)),
                      ),
                      TextButton(
                        onPressed: _showColorPicker,
                        child: const Text('Đổi màu', style: TextStyle(color: Color(0xFFB2006A), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Input tên danh mục
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Tên danh mục*',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFB2006A), width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _saveCategory,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB2006A),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Xác nhận', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ),
    );
  }
}
