import 'package:flutter/material.dart';

import '../../models/app_nav_item.dart';
import 'screens/home_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/report_screen.dart';
import 'screens/utility_screen.dart';
import 'widgets/header_widget.dart';
import 'widgets/bottom_nav_widget.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int currentIndex = 0;

  final List<AppNavItem> navItems = const [
    AppNavItem(
      label: 'Trang chủ',
      title: 'Quản lý chi tiêu',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      screen: HomeScreen(),
      showNotification: true,
    ),
    AppNavItem(
      label: 'Ví',
      title: 'Ví của tôi',
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet,
      screen: WalletScreen(),
    ),
    AppNavItem(
      label: 'Báo cáo',
      title: 'Báo cáo',
      icon: Icons.pie_chart_outline,
      activeIcon: Icons.pie_chart,
      screen: ReportScreen(),
    ),
    AppNavItem(
      label: 'Tiện ích',
      title: 'Tiện ích',
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view,
      screen: UtilityScreen(),
    ),
  ];

  void onTabChanged(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  void onNotificationPressed() {
    debugPrint('Mở màn hình thông báo');
  }

  @override
  Widget build(BuildContext context) {
    final AppNavItem currentItem = navItems[currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FF),
      appBar: AppHeaderWidget(
        title: currentItem.title,
        showNotification: currentItem.showNotification,
        onNotificationPressed: onNotificationPressed,
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