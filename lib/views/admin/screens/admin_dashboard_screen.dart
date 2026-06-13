import 'package:flutter/material.dart';

import '../../../services/admin_access_service.dart';
import 'admin_app_config_tab.dart';
import 'admin_audit_log_tab.dart';
import 'admin_default_categories_tab.dart';
import 'admin_notifications_tab.dart';
import 'admin_overview_tab.dart';
import 'admin_users_tab.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AdminAccessService().isCurrentUserAdmin(forceRefresh: true),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data != true) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Quản trị hệ thống'),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              elevation: 0,
            ),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.gpp_bad_outlined, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'Bạn không có quyền truy cập khu vực quản trị.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return const _AdminDashboardBody();
      },
    );
  }
}

class _AdminDashboardBody extends StatelessWidget {
  const _AdminDashboardBody();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        appBar: AppBar(
          title: const Text(
            'Quản trị hệ thống',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: Color(0xFFB02A76),
            unselectedLabelColor: Colors.black54,
            indicatorColor: Color(0xFFB02A76),
            tabs: [
              Tab(icon: Icon(Icons.dashboard_outlined), text: 'Tổng quan'),
              Tab(icon: Icon(Icons.people_outline), text: 'Người dùng'),
              Tab(icon: Icon(Icons.campaign_outlined), text: 'Thông báo'),
              Tab(icon: Icon(Icons.tune), text: 'Cấu hình'),
              Tab(icon: Icon(Icons.category_outlined), text: 'Dữ liệu nền'),
              Tab(icon: Icon(Icons.history), text: 'Nhật ký'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AdminOverviewTab(),
            AdminUsersTab(),
            AdminNotificationsTab(),
            AdminAppConfigTab(),
            AdminDefaultCategoriesTab(),
            AdminAuditLogTab(),
          ],
        ),
      ),
    );
  }
}
