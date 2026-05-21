import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/transaction_model.dart';
import '../../../models/category_model.dart';
import '../../wallet/services/transaction_service.dart';
import '../../../controllers/category_controller.dart';
import '../screens/transaction_detail_screen.dart';

class RecentTransactionsWidget extends StatefulWidget {
  final VoidCallback? onViewAll;
  const RecentTransactionsWidget({super.key, this.onViewAll});

  @override
  State<RecentTransactionsWidget> createState() =>
      _RecentTransactionsWidgetState();
}

class _RecentTransactionsWidgetState extends State<RecentTransactionsWidget> {
  final TransactionService _transactionService = TransactionService();
  final CategoryController _categoryController = CategoryController();

  List<CategoryModel> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await _categoryController.getAllCategories();
    if (mounted) setState(() => _categories = cats);
  }

  CategoryModel? _findCategory(String? id, String? name) {
    String? targetId = id;
    if ((targetId == null || targetId.isEmpty) && name != null && !name.contains(' ') && name.length > 15) {
      targetId = name;
    }

    if (targetId != null && targetId.isNotEmpty) {
      try {
        return _categories.firstWhere((c) => c.id == targetId);
      } catch (_) {}
    }
    if (name != null && name.isNotEmpty) {
      final lc = name.toLowerCase().trim();
      try {
        return _categories.firstWhere((c) => c.name.toLowerCase().trim() == lc);
      } catch (_) {}
      
      try {
        return _categories.firstWhere((c) {
          final cName = c.name.toLowerCase();
          if (lc.contains(cName) || cName.contains(lc)) return true;
          if (cName.contains("ăn") && (lc.contains("tra") || lc.contains("sua") || lc.contains("com") || lc.contains("food"))) return true;
          if ((cName.contains("hóa đơn") || cName.contains("bill")) && (lc.contains("nước") || lc.contains("điện") || lc.contains("wifi") || lc.contains("water"))) return true;
          return false;
        });
      } catch (_) {}
    }
    return null;
  }

  Widget _categoryIconWidget(String? catId, String? catName, {bool isIncome = false}) {
    final cat = _findCategory(catId, catName);
    Color bg, iconColor;
    IconData icon;

    if (cat != null) {
      try {
        final hex = cat.colorHex.replaceFirst('#', '');
        iconColor = Color(int.parse(hex, radix: 16));
        bg = iconColor.withValues(alpha: 0.12);
        icon = IconData(int.parse(cat.iconCode, radix: 16),
            fontFamily: 'MaterialIcons');
      } catch (_) {
        iconColor = isIncome ? Colors.green : const Color(0xFFE0248A);
        bg = iconColor.withValues(alpha: 0.12);
        icon = isIncome ? Icons.add : Icons.remove;
      }
    } else {
      // Robust fallback for milk tea / water
      if (catName?.toLowerCase().contains("tra sua") ?? false) {
          final fallback = _findCategory(null, "Ăn uống");
          if (fallback != null) return _categoryIconWidget(fallback.id, fallback.name, isIncome: isIncome);
      }
      if (catName?.toLowerCase().contains("tien nuoc") ?? false) {
          final fallback = _findCategory(null, "Hóa đơn");
          if (fallback != null) return _categoryIconWidget(fallback.id, fallback.name, isIncome: isIncome);
      }

      iconColor = isIncome ? Colors.green : const Color(0xFFE0248A);
      bg = iconColor.withValues(alpha: 0.12);
      icon = isIncome
          ? Icons.account_balance_wallet
          : Icons.attach_money;
    }

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: iconColor, size: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Lịch sử giao dịch',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              GestureDetector(
                onTap: widget.onViewAll,
                child: const Text(
                  'Xem tất cả',
                  style: TextStyle(
                    color: Color(0xFFE0248A),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<TransactionModel>>(
            future: _transactionService.getAllTransactionsGlobal(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                      child:
                          CircularProgressIndicator(strokeWidth: 2)),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text('Chưa có giao dịch nào',
                        style: TextStyle(color: Colors.grey)),
                  ),
                );
              }

              final txs = snapshot.data!.take(3).toList();

              return Column(
                children: txs.map((tx) {
                  final bool isIncome = tx.type == 'income';
                  final cat = _findCategory(tx.categoryId, tx.category);
                  final String realCategoryName = cat?.name ?? (tx.category.length > 15 ? "Khác" : tx.category);
                  final String displayName = (tx.note.isNotEmpty && tx.note.length < 50) ? tx.note : realCategoryName;

                  return InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionDetailScreen(transaction: tx))).then((_) => setState(() {})),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          _categoryIconWidget(tx.categoryId, tx.category,
                              isIncome: isIncome),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  DateFormat('dd/MM/yyyy • HH:mm')
                                      .format(tx.createdAt),
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${isIncome ? '+' : '-'}${NumberFormat('#,###').format(tx.amount)}đ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isIncome ? Colors.green : Colors.red,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
