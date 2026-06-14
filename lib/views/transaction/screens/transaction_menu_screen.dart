import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/transaction_model.dart';
import '../../../models/recurring_transaction_model.dart';
import '../../../models/category_model.dart';
import '../../../models/wallet_model.dart';
import '../../wallet/services/transaction_service.dart';
import '../../wallet/services/wallet_service.dart';
import '../../../controllers/recurring_transaction_controller.dart';
import '../../../controllers/category_controller.dart';
import '../../wallet/screens/add_transaction_screen.dart';
import '../../wallet/screens/category_management_screen.dart';
import '../../wallet/screens/add_recurring_transaction_screen.dart';
import '../../wallet/screens/transfer_money_screen.dart';
import '../../home/screens/transaction_detail_screen.dart';
import '../../../utils/recurring_schedule.dart';

class TransactionMenuScreen extends StatefulWidget {
  final int initialTabIndex;
  const TransactionMenuScreen({super.key, this.initialTabIndex = 0});

  @override
  State<TransactionMenuScreen> createState() => _TransactionMenuScreenState();
}

class _TransactionMenuScreenState extends State<TransactionMenuScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TransactionService _transactionService = TransactionService();
  final WalletService _walletService = WalletService();
  final RecurringTransactionController _recurringController =
      RecurringTransactionController();
  final CategoryController _categoryController = CategoryController();

  List<CategoryModel> _categories = [];
  List<WalletModel> _wallets = [];
  final Set<String> _payingIds = {};
  late final Stream<List<TransactionModel>> _transactionsStream;
  StreamSubscription<List<WalletModel>>? _walletSubscription;
  final Color momoPink = const Color(0xFFE0248A);
  final Color _pageBackground = const Color(0xFFFFF7FF);
  final Color _transferPurple = const Color(0xFF7C4DFF);
  final TextEditingController _searchController = TextEditingController();
  String _typeFilter = 'all';
  String _periodFilter = 'all';
  String? _categoryFilterId;
  String? _walletFilterId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _transactionsStream = _transactionService.watchAllTransactionsGlobal();
    _loadCategories();
    _watchWallets();
  }

  Future<void> _refreshTransactions() async {
    await Future.wait([
      _transactionService.getAllTransactionsGlobal(),
      _loadCategories(),
    ]);
  }

  @override
  void didUpdateWidget(TransactionMenuScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTabIndex != oldWidget.initialTabIndex) {
      _tabController.index = widget.initialTabIndex;
    }
  }

  Future<void> _loadCategories() async {
    final cats = await _categoryController.getAllCategories();
    if (mounted) setState(() => _categories = cats);
  }

  void _watchWallets() {
    _walletSubscription = _walletService.getWallets().listen((wallets) {
      if (mounted) setState(() => _wallets = wallets);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _walletSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ─── Find category by ID or Name (Robust) ──────────────────────────────────
  CategoryModel? _findCategory(String? id, String? name) {
    String? targetId = id;
    if ((targetId == null || targetId.isEmpty) &&
        name != null &&
        !name.contains(' ') &&
        name.length > 15) {
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
          if (cName.contains("ăn") &&
              (lc.contains("tra") ||
                  lc.contains("sua") ||
                  lc.contains("com") ||
                  lc.contains("food"))) {
            return true;
          }
          if ((cName.contains("hóa đơn") || cName.contains("bill")) &&
              (lc.contains("nước") ||
                  lc.contains("điện") ||
                  lc.contains("wifi") ||
                  lc.contains("water"))) {
            return true;
          }
          return false;
        });
      } catch (_) {}
    }
    return null;
  }

  Widget _categoryIcon(
    String? catId,
    String? catName, {
    double size = 22,
    double padding = 10,
    BorderRadius? radius,
  }) {
    final cat = _findCategory(catId, catName);
    Color bg, iconColor;
    IconData icon;

    if (cat != null) {
      try {
        final hex = cat.colorHex.replaceFirst('#', '');
        iconColor = Color(int.parse(hex, radix: 16));
        bg = iconColor.withValues(alpha: 0.12);
        icon = IconData(
          int.parse(cat.iconCode, radix: 16),
          fontFamily: 'MaterialIcons',
        );
      } catch (_) {
        iconColor = momoPink;
        bg = momoPink.withValues(alpha: 0.12);
        icon = Icons.attach_money;
      }
    } else {
      iconColor = const Color(0xFF9E9E9E);
      bg = const Color(0xFFF5F5F5);
      icon = Icons.attach_money;
    }

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius ?? BorderRadius.circular(12),
      ),
      child: Icon(icon, color: iconColor, size: size),
    );
  }

  void _showAddMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE0F7FA),
                child: Icon(Icons.add_task, color: Colors.blue),
              ),
              title: const Text(
                'Thêm giao dịch mới',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddTransactionScreen(),
                  ),
                ).then((_) => _refreshTransactions());
              },
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(Icons.swap_horiz, color: Colors.green),
              ),
              title: const Text(
                'Chuyển tiền giữa các ví',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TransferMoneyScreen(),
                  ),
                ).then((_) => _refreshTransactions());
              },
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFF3E5F5),
                child: Icon(Icons.schedule_send, color: Colors.purple),
              ),
              title: const Text(
                'Thêm hóa đơn định kỳ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddRecurringTransactionScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFFF0F6),
                child: Icon(Icons.grid_view_rounded, color: Color(0xFFE0248A)),
              ),
              title: const Text(
                'Quản lý danh mục',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CategoryManagementScreen(),
                  ),
                ).then((_) => _loadCategories());
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.black45,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: momoPink,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(text: 'Tất cả'),
                  Tab(text: 'Giao dịch'),
                  Tab(text: 'Định kỳ'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTransactionList(filter: 'all'),
                  _buildTransactionList(filter: 'normal'),
                  _buildRecurringTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMenu,
        backgroundColor: momoPink,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Thêm mới',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildTransactionList({required String filter}) {
    return StreamBuilder<List<TransactionModel>>(
      stream: _transactionsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }
        List<TransactionModel> txs = snapshot.data!;
        if (filter == 'normal') {
          txs = txs.where((tx) => !tx.isRecurring).toList();
        } else if (filter == 'recurring') {
          txs = txs.where((tx) => tx.isRecurring).toList();
        }
        final filteredTxs = _applyFilters(txs);
        final visibleTxs = _collapseTransferPairs(filteredTxs);
        return RefreshIndicator(
          color: momoPink,
          onRefresh: _refreshTransactions,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            itemCount: visibleTxs.isEmpty ? 3 : visibleTxs.length + 2,
            itemBuilder: (context, index) {
              if (index == 0) return _buildTransactionOverview(visibleTxs);
              if (index == 1) return _buildFilterPanel(visibleTxs);
              if (visibleTxs.isEmpty) return _buildNoFilterResults();
              return _buildTransactionCard(visibleTxs[index - 2]);
            },
          ),
        );
      },
    );
  }

  List<TransactionModel> _collapseTransferPairs(
    List<TransactionModel> transactions,
  ) {
    final result = <TransactionModel>[];
    final transferIndexes = <String, int>{};

    for (final tx in transactions) {
      final transferId = tx.transferId;
      if (!tx.isTransfer || transferId == null || transferId.isEmpty) {
        result.add(tx);
        continue;
      }

      final existingIndex = transferIndexes[transferId];
      if (existingIndex == null) {
        transferIndexes[transferId] = result.length;
        result.add(tx);
      } else if (!tx.isIncomingTransfer &&
          result[existingIndex].isIncomingTransfer) {
        result[existingIndex] = tx;
      }
    }

    return result;
  }

  String _walletName(String walletId) {
    for (final wallet in _wallets) {
      if (wallet.id == walletId) return wallet.name;
    }
    return 'Ví';
  }

  String _transactionTitle(TransactionModel tx) {
    if (tx.isTransfer) {
      final relatedWallet = tx.relatedWalletName?.trim();
      if (tx.isIncomingTransfer) {
        return relatedWallet == null || relatedWallet.isEmpty
            ? 'Nhận chuyển ví'
            : 'Nhận từ $relatedWallet';
      }
      return relatedWallet == null || relatedWallet.isEmpty
          ? 'Chuyển sang ví khác'
          : 'Chuyển đến $relatedWallet';
    }
    if (tx.note.isNotEmpty && tx.note.length < 50) return tx.note;
    return _categoryName(tx);
  }

  String _transactionSubtitle(TransactionModel tx) {
    final date = DateFormat('dd/MM/yyyy • HH:mm').format(tx.createdAt);
    if (!tx.isTransfer) return '${_walletName(tx.walletId)} • $date';

    final currentWallet = _walletName(tx.walletId);
    final relatedWallet = tx.relatedWalletName?.trim();
    if (relatedWallet == null || relatedWallet.isEmpty) {
      return '$currentWallet • $date';
    }
    final route = tx.isIncomingTransfer
        ? '$relatedWallet → $currentWallet'
        : '$currentWallet → $relatedWallet';
    return '$route • $date';
  }

  Color _transactionColor(TransactionModel tx) {
    if (tx.isTransfer) return _transferPurple;
    if (tx.isGoalMovement) return const Color(0xFFE0248A);
    if (tx.isDebtMovement) return const Color(0xFFFF8A3D);
    return tx.isCredit ? const Color(0xFF35A853) : const Color(0xFFFF5252);
  }

  Widget _buildTransactionOverview(List<TransactionModel> transactions) {
    final income = transactions
        .where((tx) => tx.isIncome)
        .fold<double>(0, (total, tx) => total + tx.amount);
    final expense = transactions
        .where((tx) => tx.isExpense)
        .fold<double>(0, (total, tx) => total + tx.amount);
    final transferCount = transactions.where((tx) => tx.isTransfer).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB02A76), Color(0xFFE0248A), Color(0xFFF06292)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: momoPink.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tổng quan đang xem',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Chuyển ví không được tính vào thu nhập hoặc chi tiêu',
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildOverviewItem(
                  label: 'Thu nhập',
                  value: '${NumberFormat('#,###').format(income)}đ',
                  icon: Icons.south_west_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildOverviewItem(
                  label: 'Chi tiêu',
                  value: '${NumberFormat('#,###').format(expense)}đ',
                  icon: Icons.north_east_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildOverviewItem(
                  label: 'Chuyển ví',
                  value: '$transferCount lần',
                  icon: Icons.swap_horiz_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(TransactionModel tx) {
    final color = _transactionColor(tx);
    final amountPrefix = tx.isTransfer ? '' : (tx.isCredit ? '+' : '-');

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TransactionDetailScreen(transaction: tx),
        ),
      ).then((_) => _refreshTransactions()),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF3EAF0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8C5A76).withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            tx.isInternalMovement
                ? Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      tx.isTransfer
                          ? Icons.swap_horiz_rounded
                          : tx.isGoalMovement
                          ? Icons.savings_outlined
                          : Icons.handshake_outlined,
                      color: color,
                      size: 24,
                    ),
                  )
                : _categoryIcon(
                    tx.categoryId,
                    tx.category,
                    padding: 12,
                    radius: BorderRadius.circular(15),
                  ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _transactionTitle(tx),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF332B31),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _transactionSubtitle(tx),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black38, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 118),
                  child: Text(
                    '$amountPrefix${NumberFormat('#,###').format(tx.amount)}đ',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (tx.isInternalMovement || tx.isRecurring) ...[
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tx.isTransfer
                          ? 'Chuyển ví'
                          : tx.isGoalMovement
                          ? 'Mục tiêu'
                          : tx.isDebtMovement
                          ? 'Công nợ'
                          : 'Định kỳ',
                      style: TextStyle(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<TransactionModel> _applyFilters(List<TransactionModel> txs) {
    final query = _searchController.text.trim().toLowerCase();
    final now = DateTime.now();

    return txs.where((tx) {
      if (_typeFilter != 'all' && tx.type != _typeFilter) return false;
      if (_categoryFilterId != null && tx.categoryId != _categoryFilterId) {
        return false;
      }
      if (_walletFilterId != null && tx.walletId != _walletFilterId) {
        return false;
      }

      if (_periodFilter == 'week') {
        final start = now.subtract(Duration(days: now.weekday - 1));
        final startDate = DateTime(start.year, start.month, start.day);
        final endDate = startDate.add(const Duration(days: 7));
        if (tx.createdAt.isBefore(startDate) ||
            !tx.createdAt.isBefore(endDate)) {
          return false;
        }
      } else if (_periodFilter == 'month') {
        if (tx.createdAt.month != now.month || tx.createdAt.year != now.year) {
          return false;
        }
      } else if (_periodFilter == 'year') {
        if (tx.createdAt.year != now.year) return false;
      }

      if (query.isNotEmpty) {
        final haystack =
            '${tx.note} ${tx.category} ${_categoryName(tx)} ${tx.relatedWalletName ?? ''}'
                .toLowerCase();
        if (!haystack.contains(query)) return false;
      }
      return true;
    }).toList();
  }

  Widget _buildFilterPanel(List<TransactionModel> visibleTxs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Tìm giao dịch...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    ),
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFF8F9FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _choiceChip(
                'Tất cả',
                _typeFilter == 'all',
                () => setState(() => _typeFilter = 'all'),
              ),
              _choiceChip(
                'Thu',
                _typeFilter == 'income',
                () => setState(() => _typeFilter = 'income'),
              ),
              _choiceChip(
                'Chi',
                _typeFilter == 'expense',
                () => setState(() => _typeFilter = 'expense'),
              ),
              _choiceChip(
                'Chuyển ví',
                _typeFilter == 'transfer',
                () => setState(() => _typeFilter = 'transfer'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _dropdown<String>(
                  value: _periodFilter,
                  items: const {
                    'all': 'Mọi thời gian',
                    'week': 'Tuần này',
                    'month': 'Tháng này',
                    'year': 'Năm nay',
                  },
                  onChanged: (value) =>
                      setState(() => _periodFilter = value ?? 'all'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _dropdown<String?>(
                  value: _categoryFilterId,
                  hint: 'Danh mục',
                  items: {
                    null: 'Tất cả danh mục',
                    for (final cat in _categories) cat.id: cat.name,
                  },
                  onChanged: (value) =>
                      setState(() => _categoryFilterId = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _dropdown<String?>(
            value: _walletFilterId,
            hint: 'Ví',
            items: {
              null: 'Tất cả ví',
              for (final wallet in _wallets) wallet.id: wallet.name,
            },
            onChanged: (value) => setState(() => _walletFilterId = value),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${visibleTxs.length} giao dịch phù hợp',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  bool get _hasActiveFilters {
    return _searchController.text.trim().isNotEmpty ||
        _typeFilter != 'all' ||
        _periodFilter != 'all' ||
        _categoryFilterId != null ||
        _walletFilterId != null;
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _typeFilter = 'all';
      _periodFilter = 'all';
      _categoryFilterId = null;
      _walletFilterId = null;
    });
  }

  Widget _buildNoFilterResults() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 42),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 58, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text(
            'Không có giao dịch phù hợp',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Thử đổi từ khóa, thời gian, ví hoặc danh mục để xem thêm kết quả.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black45, height: 1.4),
          ),
          if (_hasActiveFilters) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.filter_alt_off),
              label: const Text('Xóa bộ lọc'),
              style: OutlinedButton.styleFrom(
                foregroundColor: momoPink,
                side: BorderSide(color: momoPink.withValues(alpha: 0.45)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _choiceChip(String label, bool selected, VoidCallback onSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: momoPink.withValues(alpha: 0.14),
      labelStyle: TextStyle(
        color: selected ? momoPink : Colors.black54,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => onSelected(),
      side: BorderSide(color: selected ? momoPink : Colors.grey.shade200),
    );
  }

  Widget _dropdown<T>({
    required T value,
    required Map<T, String> items,
    required ValueChanged<T?> onChanged,
    String? hint,
  }) {
    return DropdownButtonFormField<T>(
      key: ValueKey<T>(value),
      initialValue: value,
      isExpanded: true,
      hint: hint == null ? null : Text(hint),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      items: items.entries
          .map(
            (entry) => DropdownMenuItem<T>(
              value: entry.key,
              child: Text(entry.value, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  String _categoryName(TransactionModel tx) {
    final categoryId = tx.categoryId;
    if (categoryId != null && categoryId.isNotEmpty) {
      for (final category in _categories) {
        if (category.id == categoryId) return category.name;
      }
    }
    return tx.category;
  }

  Widget _buildRecurringTab() {
    return StreamBuilder<List<RecurringTransactionModel>>(
      stream: _recurringController.getRecurringTransactions(),
      builder: (context, snapshot) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final allBills = (snapshot.data ?? [])
            .where(
              (tx) => isRecurringDateWithinSchedule(tx.nextDueDate, tx.endDate),
            )
            .toList();

        final pending = allBills.where((tx) {
          if (_payingIds.contains(tx.id)) return false;
          final dueDate = DateTime(
            tx.nextDueDate.year,
            tx.nextDueDate.month,
            tx.nextDueDate.day,
          );
          final threeDaysLater = today.add(const Duration(days: 3));
          return dueDate.isBefore(threeDaysLater) ||
              dueDate.isAtSameMomentAs(threeDaysLater);
        }).toList();

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Pending Section
              if (pending.isNotEmpty)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFEDD5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_active,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Chờ xử lý',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${pending.length} mục',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...pending.map((tx) => _buildPendingBill(tx, today)),
                    ],
                  ),
                ),

              // 2. Scheduled/Setup Section
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Text(
                  'Thiết lập định kỳ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (allBills.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildSmallEmptyState('Chưa có thiết lập nào'),
                )
              else
                ...allBills.map((tx) => _buildScheduledBillItem(tx)),

              // 3. History Section
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Text(
                  'Lịch sử giao dịch',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
              StreamBuilder<List<TransactionModel>>(
                stream: _transactionsStream,
                builder: (context, txSnapshot) {
                  if (txSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  final paid = (txSnapshot.data ?? [])
                      .where((tx) => tx.isRecurring)
                      .toList();
                  if (paid.isEmpty) {
                    return _buildSmallEmptyState('Chưa có lịch sử thanh toán');
                  }
                  return Column(
                    children: paid.map((tx) {
                      final bool isIncome = tx.type == 'income';
                      final displayName = tx.note.isNotEmpty
                          ? tx.note
                          : tx.category;
                      return InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                TransactionDetailScreen(transaction: tx),
                          ),
                        ).then((_) => _refreshTransactions()),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              _categoryIcon(tx.categoryId, tx.category),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      DateFormat(
                                        'dd/MM/yyyy • HH:mm',
                                      ).format(tx.createdAt),
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${isIncome ? '+' : '-'}${NumberFormat('#,###').format(tx.amount)}đ',
                                style: TextStyle(
                                  color: isIncome ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
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
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScheduledBillItem(RecurringTransactionModel tx) {
    final bool isIncome = tx.type == 'income';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          _categoryIcon(tx.categoryId, tx.name, padding: 8, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  tx.frequency,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'}${NumberFormat('#,###').format(tx.amount)}đ',
                style: TextStyle(
                  color: isIncome ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _deleteScheduled(tx),
                    child: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _editScheduled(tx),
                    child: Icon(Icons.edit_outlined, size: 18, color: momoPink),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingBill(RecurringTransactionModel tx, DateTime today) {
    final bool isIncome = tx.type == 'income';
    final dueDate = DateTime(
      tx.nextDueDate.year,
      tx.nextDueDate.month,
      tx.nextDueDate.day,
    );
    final daysLeft = dueDate.difference(today).inDays;
    String chipLabel;
    Color chipColor;
    if (daysLeft < 0) {
      chipLabel = 'Quá hạn ${daysLeft.abs()} ngày';
      chipColor = Colors.red;
    } else if (daysLeft == 0) {
      chipLabel = 'Hôm nay';
      chipColor = Colors.orange;
    } else {
      chipLabel = 'Còn $daysLeft ngày';
      chipColor = Colors.amber.shade700;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _categoryIcon(tx.categoryId, tx.name, padding: 10),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${isIncome ? '+' : '-'}${NumberFormat('#,###').format(tx.amount)}đ',
                  style: TextStyle(
                    color: isIncome ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      DateFormat('dd/MM/yyyy').format(tx.nextDueDate),
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: chipColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        chipLabel,
                        style: TextStyle(
                          color: chipColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _confirmPayment(tx),
            style: ElevatedButton.styleFrom(
              backgroundColor: isIncome
                  ? Colors.green
                  : (daysLeft < 0 ? Colors.red : Colors.orange),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              isIncome ? 'Thu thập' : 'Thanh toán',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editScheduled(RecurringTransactionModel tx) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddRecurringTransactionScreen(initialTransaction: tx),
      ),
    );
    if (result == true) {
      _refreshTransactions();
    }
  }

  void _deleteScheduled(RecurringTransactionModel tx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa thiết lập?'),
        content: Text(
          'Bạn có chắc chắn muốn dừng thiết lập định kỳ "${tx.name}" này không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _recurringController.deleteRecurringTransaction(tx.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa thiết lập định kỳ')),
        );
      }
    }
  }

  void _confirmPayment(RecurringTransactionModel recurringTx) async {
    if (!isRecurringDateWithinSchedule(
      recurringTx.nextDueDate,
      recurringTx.endDate,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giao dịch định kỳ này đã kết thúc')),
      );
      return;
    }

    setState(() => _payingIds.add(recurringTx.id));
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final String newTxId = FirebaseFirestore.instance
          .collection('dummy')
          .doc()
          .id;
      final nextDate = calculateNextRecurringDate(
        recurringTx.nextDueDate,
        recurringTx.frequency,
      );

      String categoryNameToSave = recurringTx.name;
      final matchedCat = _findCategory(recurringTx.categoryId, null);
      if (matchedCat != null) categoryNameToSave = matchedCat.name;

      final newTx = TransactionModel(
        id: newTxId,
        amount: recurringTx.amount,
        type: recurringTx.type,
        category: categoryNameToSave,
        categoryId: recurringTx.categoryId,
        note: recurringTx.name,
        createdAt: DateTime.now(),
        isRecurring: true,
        walletId: recurringTx.walletId,
      );

      if (recurringTx.walletId.isEmpty) {
        throw Exception('Hóa đơn này chưa có ví thanh toán');
      }
      await _transactionService.createTransactionAutoBalance(
        recurringTx.walletId,
        newTx,
      );
      await _recurringController.updateNextDueDate(recurringTx.id, nextDate);

      if (mounted) {
        Navigator.pop(context);
        setState(() {
          _payingIds.remove(recurringTx.id);
        });
        _refreshTransactions();
        final nextDateStr = DateFormat('dd/MM/yyyy').format(nextDate);
        final actionText = recurringTx.type == 'income'
            ? 'đã thu thập'
            : 'đã thanh toán';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đã $actionText "${recurringTx.name}"!\nKỳ tiếp theo: $nextDateStr',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        setState(() => _payingIds.remove(recurringTx.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildSmallEmptyState(String text) {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, color: Colors.grey.shade300, size: 32),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có giao dịch nào',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
