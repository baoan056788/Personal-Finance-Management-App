import 'package:flutter/material.dart';

import '../widgets/quick_actions_widget.dart';
import '../widgets/summary_widget.dart';
import '../widgets/recent_transactions_widget.dart';
import '../widgets/budget_summary_widget.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onViewAllTransactions;
  final Function(int)? onTabRequested;

  const HomeScreen({
    super.key, 
    this.onViewAllTransactions,
    this.onTabRequested,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Key _refreshKey = UniqueKey();

  Future<void> _handleRefresh() async {
    setState(() {
      _refreshKey = UniqueKey();
    });
    // Wait a bit to show the animation
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: const Color(0xFFE0248A),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            QuickActionsWidget(
              onInput: () => widget.onTabRequested?.call(1),
              onReport: () => widget.onTabRequested?.call(3),
              onCategory: () => widget.onTabRequested?.call(2),
              onUtility: () => widget.onTabRequested?.call(4),
            ),
            const SizedBox(height: 20),
            SummaryWidget(key: _refreshKey),
            const SizedBox(height: 20),
            RecentTransactionsWidget(key: ValueKey('recent_$_refreshKey'), onViewAll: widget.onViewAllTransactions),
            const SizedBox(height: 20),
            BudgetSummaryWidget(key: ValueKey('budget_$_refreshKey')),
          ],
        ),
      ),
    );
  }
}