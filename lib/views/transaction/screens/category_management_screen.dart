import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/category_model.dart';
import '../../../controllers/category_controller.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> with SingleTickerProviderStateMixin {
  final CategoryController _categoryController = CategoryController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _showAddCategoryDialog(String type) {
    final nameController = TextEditingController();
    String selectedColor = '#FFB2006A';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(type == 'income' ? 'Thêm mục Thu nhập' : 'Thêm mục Chi tiêu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Tên danh mục'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                final newCat = CategoryModel(
                  id: FirebaseFirestore.instance.collection('dummy').doc().id,
                  userId: user.uid,
                  name: nameController.text.trim(),
                  type: type,
                  iconCode: 'e5fc',
                  colorHex: selectedColor,
                  isDefault: false,
                );
                await _categoryController.addCategory(newCat);
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý danh mục', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFB2006A),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFB2006A),
          tabs: const [
            Tab(text: 'Chi tiêu'),
            Tab(text: 'Thu nhập'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoryList('expense'),
          _buildCategoryList('income'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddCategoryDialog(_tabController.index == 0 ? 'expense' : 'income');
        },
        backgroundColor: const Color(0xFFB2006A),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryList(String type) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Chưa đăng nhập'));

    return StreamBuilder<List<CategoryModel>>(
      stream: _categoryController.getCategories(type),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final cats = snapshot.data!;
        
        return ListView.builder(
          itemCount: cats.length,
          itemBuilder: (context, index) {
            final cat = cats[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(int.parse(cat.colorHex.replaceFirst('#', '0xFF'), radix: 16)).withValues(alpha: 0.2),
                child: Icon(Icons.category, color: Color(int.parse(cat.colorHex.replaceFirst('#', '0xFF'), radix: 16))),
              ),
              title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w500)),
              trailing: !cat.isDefault ? IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  _categoryController.deleteCategory(cat.id);
                },
              ) : null,
            );
          },
        );
      },
    );
  }
}
