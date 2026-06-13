import 'package:flutter/material.dart';

import '../../../models/system_default_category_model.dart';
import '../../../services/admin_service.dart';
import '../../../utils/category_name_normalizer.dart';

class AdminDefaultCategoriesTab extends StatefulWidget {
  const AdminDefaultCategoriesTab({super.key});

  @override
  State<AdminDefaultCategoriesTab> createState() =>
      _AdminDefaultCategoriesTabState();
}

class _AdminDefaultCategoriesTabState extends State<AdminDefaultCategoriesTab> {
  final AdminService _service = AdminService();
  String _type = 'expense';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SystemDefaultCategoryModel>>(
      stream: _service.watchDefaultCategories(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ErrorState(
            message: 'Không thể tải danh mục nền: ${snapshot.error}',
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final categories = snapshot.data!
            .where((category) => category.type == _type)
            .toList();
        return Column(
          children: [
            Material(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'expense',
                            icon: Icon(Icons.trending_down),
                            label: Text('Chi'),
                          ),
                          ButtonSegment(
                            value: 'income',
                            icon: Icon(Icons.trending_up),
                            label: Text('Thu'),
                          ),
                        ],
                        selected: {_type},
                        showSelectedIcon: false,
                        onSelectionChanged: (value) {
                          setState(() => _type = value.first);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filled(
                      tooltip: 'Thêm danh mục nền',
                      onPressed: () => _openEditor(type: _type),
                      icon: const Icon(Icons.add),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFB02A76),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: categories.isEmpty
                  ? _EmptyState(onAdd: () => _openEditor(type: _type))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        return _CategoryTile(
                          category: category,
                          onEdit: () => _openEditor(category: category),
                          onToggle: (value) => _toggle(category, value),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggle(SystemDefaultCategoryModel category, bool value) async {
    try {
      await _service.setDefaultCategoryActive(category, value);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể cập nhật danh mục: $error'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _openEditor({
    SystemDefaultCategoryModel? category,
    String? type,
  }) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CategoryEditorSheet(
        service: _service,
        category: category,
        initialType: type ?? category?.type ?? 'expense',
      ),
    );
    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu danh mục nền.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

class _CategoryTile extends StatelessWidget {
  final SystemDefaultCategoryModel category;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggle;

  const _CategoryTile({
    required this.category,
    required this.onEdit,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(category.colorHex);
    final icon = IconData(
      int.tryParse(category.iconCode, radix: 16) ?? Icons.category.codePoint,
      fontFamily: 'MaterialIcons',
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: onEdit,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(
          category.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: category.isActive ? Colors.black87 : Colors.black38,
          ),
        ),
        subtitle: Text(
          'Thứ tự ${category.order} • ${category.isActive ? 'Đang cấp cho tài khoản mới' : 'Đã ẩn'}',
        ),
        trailing: Switch(
          value: category.isActive,
          onChanged: onToggle,
          activeTrackColor: const Color(0xFFB02A76),
        ),
      ),
    );
  }
}

class _CategoryEditorSheet extends StatefulWidget {
  final AdminService service;
  final SystemDefaultCategoryModel? category;
  final String initialType;

  const _CategoryEditorSheet({
    required this.service,
    required this.initialType,
    this.category,
  });

  @override
  State<_CategoryEditorSheet> createState() => _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends State<_CategoryEditorSheet> {
  static const _icons = [
    'e532',
    'e531',
    'e8cc',
    'e8b0',
    'e53d',
    'e838',
    'e873',
    'e52f',
    'eb3f',
    'e8f9',
    'e333',
    'e156',
  ];
  static const _colors = [
    'FFB02A76',
    'FFF44336',
    'FFE91E63',
    'FF9C27B0',
    'FF3F51B5',
    'FF2196F3',
    'FF00BCD4',
    'FF009688',
    'FF4CAF50',
    'FFFFC107',
    'FFFF9800',
    'FF795548',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _orderController;
  late String _type;
  late String _iconCode;
  late String _colorHex;
  late bool _isActive;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    _nameController = TextEditingController(text: category?.name ?? '');
    _orderController = TextEditingController(
      text: (category?.order ?? 10).toString(),
    );
    _type = category?.type ?? widget.initialType;
    _iconCode = category?.iconCode ?? _icons.first;
    _colorHex = category?.colorHex ?? _colors.first;
    _isActive = category?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final name = _nameController.text.trim().replaceAll(RegExp(r'\s+'), ' ');
      await widget.service.saveDefaultCategory(
        SystemDefaultCategoryModel(
          id: widget.category?.id ?? '',
          name: name,
          normalizedName: normalizeCategoryName(name),
          type: _type,
          iconCode: _iconCode,
          colorHex: _colorHex,
          order: int.parse(_orderController.text),
          isActive: _isActive,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.category == null
                          ? 'Thêm danh mục nền'
                          : 'Chỉnh sửa danh mục nền',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                maxLength: 40,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Tên danh mục',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final name = value?.trim() ?? '';
                  if (name.length < 2) return 'Tên phải có ít nhất 2 ký tự';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'expense', label: Text('Chi tiêu')),
                  ButtonSegment(value: 'income', label: Text('Thu nhập')),
                ],
                selected: {_type},
                showSelectedIcon: false,
                onSelectionChanged: (value) {
                  setState(() => _type = value.first);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _orderController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Thứ tự hiển thị',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final order = int.tryParse(value ?? '');
                  if (order == null || order < 0 || order > 999) {
                    return 'Nhập số từ 0 đến 999';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Biểu tượng',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _icons.map((code) {
                  final selected = code == _iconCode;
                  return IconButton(
                    tooltip: 'Chọn biểu tượng',
                    onPressed: () => setState(() => _iconCode = code),
                    icon: Icon(
                      IconData(
                        int.parse(code, radix: 16),
                        fontFamily: 'MaterialIcons',
                      ),
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: selected
                          ? _parseColor(_colorHex).withValues(alpha: 0.16)
                          : Colors.grey.shade100,
                      foregroundColor: selected
                          ? _parseColor(_colorHex)
                          : Colors.black54,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text(
                'Màu sắc',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _colors.map((hex) {
                  final selected = hex == _colorHex;
                  return InkWell(
                    onTap: () => setState(() => _colorHex = hex),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _parseColor(hex),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? Colors.black87 : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: selected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 18,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Cấp cho tài khoản mới'),
                subtitle: const Text(
                  'Tắt để ẩn danh mục mà không ảnh hưởng dữ liệu người dùng cũ.',
                ),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Lưu danh mục'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: const Color(0xFFB02A76),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _parseColor(String value) {
  final clean = value.replaceFirst('#', '');
  return Color(int.tryParse(clean, radix: 16) ?? 0xFF9E9E9E);
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.category_outlined, size: 56, color: Colors.black38),
          const SizedBox(height: 12),
          const Text('Chưa có danh mục nền cho loại này.'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Thêm danh mục'),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}
