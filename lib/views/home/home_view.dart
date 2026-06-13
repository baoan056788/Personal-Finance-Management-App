import 'package:flutter/material.dart';

import '../../controllers/debt_controller.dart';
import '../../controllers/recurring_transaction_controller.dart';
import '../../models/app_nav_item.dart';
import '../../models/debt_model.dart';
import '../../models/recurring_transaction_model.dart';
import '../../services/notification_settings_service.dart';
import '../../services/system_notification_service.dart';
import '../transaction/screens/transaction_menu_screen.dart';
import '../wallet/screens/wallet_list_screen.dart';
import 'screens/home_screen.dart';
import 'screens/report_screen.dart';
import 'screens/utility_screen.dart';
import 'widgets/bottom_nav_widget.dart';
import 'widgets/header_widget.dart';
import 'widgets/notification_reminder_content.dart';

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

  void _goToTab(int index, {int subTab = 0}) {
    setState(() {
      currentIndex = index;
      if (index == 2) _transactionInitialTab = subTab;
    });
  }

  void onTabChanged(int index) => _goToTab(index);

  Future<void> onNotificationPressed() async {
    if (_isLoadingNotifications) return;
    setState(() => _isLoadingNotifications = true);

    try {
      final systemNotifications = await SystemNotificationService()
          .getActiveNotifications();
      final settings = await NotificationSettingsService().load();
      if (!mounted) return;

      final debts = settings.enabled && settings.debtReminders
          ? await DebtController().getDueReminders(
              daysAhead: settings.advanceDays,
            )
          : <DebtModel>[];

      var upcomingRecurring = <RecurringTransactionModel>[];
      if (settings.enabled && settings.recurringReminders) {
        final recurring = await RecurringTransactionController()
            .getRecurringTransactions()
            .first;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final limit = today.add(Duration(days: settings.advanceDays));
        upcomingRecurring = recurring.where((tx) {
          final due = DateTime(
            tx.nextDueDate.year,
            tx.nextDueDate.month,
            tx.nextDueDate.day,
          );
          return due.isBefore(limit) || due.isAtSameMomentAs(limit);
        }).toList();
        upcomingRecurring.sort(
          (a, b) => a.nextDueDate.compareTo(b.nextDueDate),
        );
      }

      if (!mounted) return;
      if (systemNotifications.isEmpty &&
          debts.isEmpty &&
          upcomingRecurring.isEmpty &&
          !settings.enabled) {
        await _showNotificationMessage(
          'Thông báo đang tắt',
          'Bạn có thể bật lại trong Tiện ích > Thông báo.',
        );
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.notifications, color: Color(0xFFF06292)),
              SizedBox(width: 8),
              Text('Thông báo'),
            ],
          ),
          content: NotificationReminderContent(
            systemNotifications: systemNotifications,
            debts: debts,
            recurring: upcomingRecurring,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Đóng',
                style: TextStyle(color: Color(0xFFF06292)),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tải thông báo: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoadingNotifications = false);
    }
  }

  Future<void> _showNotificationMessage(String title, String message) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
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
