import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../wallet/services/wallet_service.dart';
import '../widgets/quick_actions_widget.dart';
import '../widgets/summary_widget.dart';
import '../widgets/recent_transactions_widget.dart';
import '../widgets/budget_summary_widget.dart';
import '../widgets/goal_summary_widget.dart';

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
  static const Color _primaryPink = Color(0xFFE0248A);
  Key _refreshKey = UniqueKey();
  final WalletService _walletService = WalletService();

  Future<void> _handleRefresh() async {
    setState(() {
      _refreshKey = UniqueKey();
    });
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
            _buildWelcomeCard(),
            const SizedBox(height: 18),
            QuickActionsWidget(
              onInput: () => widget.onTabRequested?.call(1),
              onReport: () => widget.onTabRequested?.call(3),
              onCategory: () => widget.onTabRequested?.call(2),
              onUtility: () => widget.onTabRequested?.call(4),
            ),
            const SizedBox(height: 20),
            SummaryWidget(key: _refreshKey),
            const SizedBox(height: 20),
            RecentTransactionsWidget(
              key: ValueKey('recent_$_refreshKey'),
              onViewAll: widget.onViewAllTransactions,
            ),
            const SizedBox(height: 20),
            BudgetSummaryWidget(key: ValueKey('budget_$_refreshKey')),
            const SizedBox(height: 20),
            GoalSummaryWidget(key: ValueKey('goal_$_refreshKey')),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final user = FirebaseAuth.instance.currentUser;
    final profileStream = user == null
        ? null
        : FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: profileStream,
      builder: (context, profileSnapshot) {
        final data = profileSnapshot.data?.data();
        final fullName = (data?['fullName'] as String? ?? '').trim();
        final firstName = fullName.isEmpty
            ? 'bạn'
            : fullName.split(RegExp(r'\s+')).last;

        return StreamBuilder(
          stream: _walletService.getWallets(),
          builder: (context, walletSnapshot) {
            final wallets = walletSnapshot.data ?? const [];
            final totalBalance = wallets.fold<double>(
              0,
              (total, wallet) => total + wallet.balance,
            );
            final currency = NumberFormat.currency(
              locale: 'vi_VN',
              symbol: 'đ',
              decimalDigits: 0,
            );

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFAD276F), _primaryPink, Color(0xFFF06292)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: _primaryPink.withValues(alpha: 0.22),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Xin chào, $firstName',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Cùng kiểm soát tài chính hôm nay',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'Tổng tài sản',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      walletSnapshot.connectionState == ConnectionState.waiting
                          ? 'Đang tải...'
                          : currency.format(totalBalance),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.wallet_outlined,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          '${wallets.length} ví đang quản lý',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
}
