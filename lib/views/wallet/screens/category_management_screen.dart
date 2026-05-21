import 'package:flutter/material.dart';
import '../../../controllers/category_controller.dart';
import '../../../models/category_model.dart';
import 'create_category_screen.dart';
import 'edit_category_screen.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final CategoryController _categoryController = CategoryController();
  bool _isExpenseTab = true;

  @override
  void initState() {
    super.initState();
    _categoryController.setupDefaultCategoriesIfNeeded();
  }

  // Parse color string (e.g., FFF44336) to Color
  Color _parseColor(String colorHex) {
    try {
      final String cleanHex = colorHex.replaceFirst('#', '');
      return Color(int.parse(cleanHex, radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  // Parse icon code point string to IconData
  IconData _parseIcon(String iconCode) {
    try {
      return IconData(int.parse(iconCode, radix: 16), fontFamily: 'MaterialIcons');
    } catch (e) {
      return Icons.category;
    }
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
          'Quản lý danh mục',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.support_agent, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.home, color: Colors.black87),
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isExpenseTab = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _isExpenseTab ? const Color(0xFFB2006A) : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.trending_up,
                            color: _isExpenseTab ? const Color(0xFFB2006A) : Colors.grey,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Chi tiêu',
                            style: TextStyle(
                              color: _isExpenseTab ? const Color(0xFFB2006A) : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isExpenseTab = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: !_isExpenseTab ? const Color(0xFFB2006A) : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.trending_down,
                            color: !_isExpenseTab ? const Color(0xFFB2006A) : Colors.grey,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Thu nhập',
                            style: TextStyle(
                              color: !_isExpenseTab ? const Color(0xFFB2006A) : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Add Category Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateCategoryScreen(
                      initialType: _isExpenseTab ? 'expense' : 'income',
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.add_circle, color: Color(0xFFB2006A), size: 28),
                        const SizedBox(width: 12),
                        const Text(
                          'Danh mục mới',
                          style: TextStyle(
                            color: Color(0xFFB2006A),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Categories Grid
          Expanded(
            child: StreamBuilder<List<CategoryModel>>(
              stream: _categoryController.getCategories(_isExpenseTab ? 'expense' : 'income'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFB2006A)));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }

                final categories = snapshot.data ?? [];

                if (categories.isEmpty) {
                  return const Center(
                    child: Text('Chưa có danh mục nào', style: TextStyle(color: Colors.grey)),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditCategoryScreen(category: category),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _parseColor(category.colorHex).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _parseIcon(category.iconCode),
                                color: _parseColor(category.colorHex),
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              category.name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
