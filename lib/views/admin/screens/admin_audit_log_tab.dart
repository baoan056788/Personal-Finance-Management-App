import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../services/admin_service.dart';

class AdminAuditLogTab extends StatelessWidget {
  const AdminAuditLogTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: AdminService().watchAuditLogs(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Không thể tải nhật ký: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history, size: 56, color: Colors.black38),
                SizedBox(height: 12),
                Text('Chưa có thay đổi quản trị nào.'),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final action = data['action'] as String? ?? 'unknown';
            final createdAt = data['createdAt'] is Timestamp
                ? (data['createdAt'] as Timestamp).toDate()
                : null;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(
                    0xFF4F6BED,
                  ).withValues(alpha: 0.1),
                  child: Icon(_iconFor(action), color: const Color(0xFF4F6BED)),
                ),
                title: Text(
                  _labelFor(action),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${data['summary'] ?? data['targetId'] ?? 'Không rõ'}\n'
                  '${data['actorEmail'] ?? data['actorUid'] ?? 'Admin'}',
                ),
                isThreeLine: true,
                trailing: createdAt == null
                    ? null
                    : Text(
                        DateFormat('dd/MM\nHH:mm').format(createdAt.toLocal()),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black45,
                        ),
                      ),
              ),
            );
          },
        );
      },
    );
  }

  static IconData _iconFor(String action) {
    if (action.contains('notification')) return Icons.campaign_outlined;
    if (action.contains('config')) return Icons.tune;
    return Icons.category_outlined;
  }

  static String _labelFor(String action) {
    const labels = {
      'create_system_notification': 'Tạo thông báo',
      'update_system_notification': 'Sửa thông báo',
      'publish_system_notification': 'Phát hành thông báo',
      'unpublish_system_notification': 'Ẩn thông báo',
      'delete_system_notification': 'Xóa thông báo',
      'update_app_config': 'Cập nhật cấu hình',
      'create_default_category': 'Tạo danh mục nền',
      'update_default_category': 'Sửa danh mục nền',
      'activate_default_category': 'Hiện danh mục nền',
      'deactivate_default_category': 'Ẩn danh mục nền',
    };
    return labels[action] ?? action;
  }
}
