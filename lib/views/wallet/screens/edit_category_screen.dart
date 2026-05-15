import 'package:flutter/material.dart';
import '../../../controllers/category_controller.dart';
import '../../../models/category_model.dart';

class EditCategoryScreen extends StatefulWidget {
  final CategoryModel category;

  const EditCategoryScreen({super.key, required this.category});

  @override
  State<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends State<EditCategoryScreen> {
  final CategoryController _categoryController = CategoryController();
  late TextEditingController _nameController;
  
  late String _selectedType;
  late String _selectedIconCode;
  late String _selectedColorHex;

  final List<String> _iconOptions = [
    'e532', 'e531', 'e8cc', 'e8b0', 'e53d', 'e838', 
    'e873', 'e52f', 'eb3f', 'e8f9', 'e333', 'e156',
  ];

  final List<String> _colorOptions = [
    'FFB2006A', 'FFF44336', 'FFE91E63', 'FF9C27B0', 'FF673AB7', 'FF3F51B5', 
    'FF2196F3', 'FF03A9F4', 'FF00BCD4', 'FF009688', 'FF4CAF50', 'FF8BC34A', 
    'FFCDDC39', 'FFFFEB3B', 'FFFFC107', 'FFFF9800', 'FFFF5722', 'FF795548',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category.name);
    _selectedType = widget.category.type;
    _selectedIconCode = widget.category.iconCode;
    _selectedColorHex = widget.category.colorHex;
  }

  void _updateCategory() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên danh mục'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final updatedCategory = CategoryModel(
      id: widget.category.id,
      userId: widget.category.userId,
      name: name,
      type: _selectedType,
      iconCode: _selectedIconCode,
      colorHex: _selectedColorHex,
      isDefault: widget.category.isDefault,
    );

    await _categoryController.updateCategory(updatedCategory);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _deleteCategory() async {
    if (widget.category.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể xóa danh mục mặc định'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa danh mục'),
          content: const Text('Bạn có chắc chắn muốn xóa danh mục này?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                await _categoryController.deleteCategory(widget.category.id);
                if (mounted) {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // close screen
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Xóa', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
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
          'Chỉnh sửa danh mục',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          if (!widget.category.isDefault)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: _deleteCategory,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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
                        color: Color(int.parse(_selectedColorHex.replaceFirst('#', ''), radix: 16)).withOpacity(0.1),
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
                  TextField(
                    controller: _nameController,
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
            onPressed: _updateCategory,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB2006A),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Lưu thay đổi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ),
    );
  }
}
