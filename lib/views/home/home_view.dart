import 'package:flutter/material.dart';

import '../../models/app_nav_item.dart';
import '../../services/notification_center_service.dart';
import '../notification/screens/notification_center_screen.dart';
import '../transaction/screens/transaction_menu_screen.dart';
import '../wallet/screens/wallet_list_screen.dart';
import 'screens/home_screen.dart';
import 'screens/report_screen.dart';
import 'screens/utility_screen.dart';
import 'widgets/bottom_nav_widget.dart';
import 'widgets/header_widget.dart';

class HomeView extends StatefulWidget {
  final bool isAdmin;

  const HomeView({super.key, required this.isAdmin});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int currentIndex = 0;
  int _transactionInitialTab = 0;
  bool _isLoadingNotifications = false;
  int _notificationCount = 0;

  @override
  void initState() {
    super.initState();
    _refreshNotificationCount();
  }

  void _goToTab(int index, {int subTab = 0}) {
    setState(() {
      currentIndex = index;
      if (index == 2) _transactionInitialTab = subTab;
    });
  }

  void onTabChanged(int index) {
    _goToTab(index);
    if (index == 0) _refreshNotificationCount();
  }

  Future<void> _refreshNotificationCount() async {
    if (_isLoadingNotifications) return;
    setState(() => _isLoadingNotifications = true);
    try {
      final data = await NotificationCenterService().load();
      if (mounted) setState(() => _notificationCount = data.reminderCount);
    } catch (_) {
      // Keep the latest successful badge value when the network is unavailable.
    } finally {
      if (mounted) setState(() => _isLoadingNotifications = false);
    }
  }

  Future<void> onNotificationPressed() async {
    if (_isLoadingNotifications) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const NotificationCenterScreen()),
    );
    await _refreshNotificationCount();
  }

  @override
  Widget build(BuildContext context) {
    final navItems = [
      AppNavItem(
        label: 'Trang chủ',
        title: 'Quản lý chi tiêu',
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        screen: HomeScreen(
          onViewAllTransactions: () => _goToTab(2, subTab: 0),
          onTabRequested: (idx) => _goToTab(idx),
        ),
        showNotification: true,
      ),
      AppNavItem(
        label: 'Ví',
        title: 'Ví của tôi',
        icon: Icons.account_balance_wallet_outlined,
        activeIcon: Icons.account_balance_wallet,
        screen: const WalletListScreen(),
      ),
      AppNavItem(
        label: 'Giao dịch',
        title: 'Giao dịch',
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long,
        screen: TransactionMenuScreen(initialTabIndex: _transactionInitialTab),
      ),
      AppNavItem(
        label: 'Biến động',
        title: 'Biến động thu chi',
        icon: Icons.pie_chart_outline,
        activeIcon: Icons.pie_chart,
        screen: const ReportScreen(),
      ),
      AppNavItem(
        label: 'Tiện ích',
        title: 'Tiện ích',
        icon: Icons.grid_view_outlined,
        activeIcon: Icons.grid_view,
        screen: UtilityScreen(isAdmin: widget.isAdmin),
      ),
    ];

    final AppNavItem currentItem = navItems[currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FF),
      appBar: AppHeaderWidget(
        title: currentItem.title,
        showNotification: currentItem.showNotification,
        onNotificationPressed: onNotificationPressed,
        notificationCount: _notificationCount,
        isNotificationLoading: _isLoadingNotifications,
      ),
      body: IndexedStack(
        index: currentIndex,
        children: navItems.map((item) => item.screen).toList(),
      ),
      bottomNavigationBar: BottomNavWidget(
        currentIndex: currentIndex,
        items: navItems,
        onTap: onTabChanged,
      ),
    );
  }
}
