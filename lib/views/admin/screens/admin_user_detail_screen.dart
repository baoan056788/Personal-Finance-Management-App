import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/admin_user_model.dart';

class AdminUserDetailScreen extends StatelessWidget {
  final AdminUserModel user;

  const AdminUserDetailScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Chi tiết người dùng'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFFFFE2F0),
                  backgroundImage:
                      user.avatarUrl != null &&
                          user.avatarUrl!.startsWith('http')
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child:
                      user.avatarUrl == null ||
                          !user.avatarUrl!.startsWith('http')
                      ? const Icon(
                          Icons.person,
                          size: 42,
                          color: Color(0xFFB02A76),
                        )
                      : null,
                ),
                const SizedBox(height: 14),
                Text(
                  user.fullName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(user.email, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 16),
                _RoleChip(isAdmin: user.isAdmin),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _InfoPanel(
            children: [
              _InfoRow(label: 'UID', value: user.uid),
              _InfoRow(label: 'Nhà cung cấp', value: user.loginProvider),
              _InfoRow(
                label: 'Ngày đăng ký',
                value: _formatDate(user.createdAt),
              ),
              _InfoRow(
                label: 'Đăng nhập gần nhất',
                value: _formatDate(user.lastSignInAt, includeTime: true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? value, {bool includeTime = false}) {
    if (value == null) return 'Chưa có dữ liệu';
    return DateFormat(
      includeTime ? 'dd/MM/yyyy HH:mm' : 'dd/MM/yyyy',
    ).format(value.toLocal());
  }
}

class _RoleChip extends StatelessWidget {
  final bool isAdmin;

  const _RoleChip({required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF4F6BED);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAdmin
                ? Icons.admin_panel_settings_outlined
                : Icons.person_outline,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            isAdmin ? 'Admin' : 'Người dùng',
            style: const TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final List<Widget> children;

  const _InfoPanel({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
