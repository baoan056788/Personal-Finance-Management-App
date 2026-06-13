import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/system_notification_model.dart';
import '../../../services/admin_service.dart';

class AdminNotificationsTab extends StatefulWidget {
  const AdminNotificationsTab({super.key});

  @override
  State<AdminNotificationsTab> createState() => _AdminNotificationsTabState();
}

class _AdminNotificationsTabState extends State<AdminNotificationsTab> {
  final AdminService _service = AdminService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SystemNotificationModel>>(
      stream: _service.watchSystemNotifications(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _MessageState(
            icon: Icons.cloud_off_outlined,
            message: 'Không thể tải thông báo: ${snapshot.error}',
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final notifications = snapshot.data!;
        return Column(
          children: [
            Material(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thông báo hệ thống',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Nội dung đã phát hành sẽ xuất hiện trong chuông thông báo.',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filled(
                      tooltip: 'Tạo thông báo',
                      onPressed: () => _openEditor(),
                      icon: const Icon(Icons.add),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFB02A76),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: notifications.isEmpty
                  ? _MessageState(
                      icon: Icons.notifications_none,
                      message: 'Chưa có thông báo hệ thống.',
                      actionLabel: 'Tạo thông báo',
                      onAction: _openEditor,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return _NotificationTile(
                          notification: notification,
                          onEdit: () => _openEditor(notification),
                          onToggle: (value) => _toggle(notification, value),
                          onDelete: () => _delete(notification),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openEditor([SystemNotificationModel? notification]) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _NotificationEditorSheet(
        service: _service,
        notification: notification,
      ),
    );
    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu thông báo hệ thống.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _toggle(SystemNotificationModel notification, bool value) async {
    try {
      await _service.setSystemNotificationPublished(notification, value);
    } catch (error) {
      if (!mounted) return;
      _showError('Không thể cập nhật thông báo: $error');
    }
  }

  Future<void> _delete(SystemNotificationModel notification) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa thông báo?'),
        content: Text('Thông báo “${notification.title}” sẽ bị xóa vĩnh viễn.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.deleteSystemNotification(notification);
    } catch (error) {
      if (!mounted) return;
      _showError('Không thể xóa thông báo: $error');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final SystemNotificationModel notification;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const _NotificationTile({
    required this.notification,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final expired = notification.expiresAt.isBefore(DateTime.now());
    final color = expired
        ? Colors.grey
        : notification.isPublished
        ? Colors.green
        : Colors.orange;
    final status = expired
        ? 'Đã hết hạn'
        : notification.isPublished
        ? 'Đang phát hành'
        : 'Bản nháp';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: onEdit,
        contentPadding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(Icons.campaign_outlined, color: color),
        ),
        title: Text(
          notification.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Text(
              notification.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 5),
            Text(
              '$status • Hết hạn ${DateFormat('dd/MM/yyyy').format(notification.expiresAt)}',
              style: TextStyle(color: color, fontSize: 11),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          tooltip: 'Tùy chọn',
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'toggle') onToggle(!notification.isPublished);
            if (value == 'delete') onDelete();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
            PopupMenuItem(
              value: 'toggle',
              child: Text(
                notification.isPublished
                    ? 'Chuyển thành bản nháp'
                    : 'Phát hành',
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationEditorSheet extends StatefulWidget {
  final AdminService service;
  final SystemNotificationModel? notification;

  const _NotificationEditorSheet({required this.service, this.notification});

  @override
  State<_NotificationEditorSheet> createState() =>
      _NotificationEditorSheetState();
}

class _NotificationEditorSheetState extends State<_NotificationEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _messageController;
  late DateTime _expiresAt;
  late bool _isPublished;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.notification?.title ?? '',
    );
    _messageController = TextEditingController(
      text: widget.notification?.message ?? '',
    );
    _expiresAt =
        widget.notification?.expiresAt ??
        DateTime.now().add(const Duration(days: 7));
    _isPublished = widget.notification?.isPublished ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expiresAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (date != null) {
      setState(() {
        _expiresAt = DateTime(date.year, date.month, date.day, 23, 59, 59);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await widget.service.saveSystemNotification(
        SystemNotificationModel(
          id: widget.notification?.id ?? '',
          title: _titleController.text.trim(),
          message: _messageController.text.trim(),
          expiresAt: _expiresAt,
          isPublished: _isPublished,
          createdAt: widget.notification?.createdAt,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.notification == null
                          ? 'Tạo thông báo'
                          : 'Chỉnh sửa thông báo',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value?.trim().length ?? 0) < 3
                    ? 'Tiêu đề phải có ít nhất 3 ký tự'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _messageController,
                minLines: 4,
                maxLines: 6,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Nội dung',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value?.trim().length ?? 0) < 5
                    ? 'Nội dung phải có ít nhất 5 ký tự'
                    : null,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_outlined),
                title: const Text('Ngày hết hạn'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_expiresAt)),
                trailing: IconButton(
                  tooltip: 'Chọn ngày',
                  onPressed: _pickDate,
                  icon: const Icon(Icons.edit_calendar_outlined),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Phát hành ngay'),
                subtitle: const Text(
                  'Tắt để lưu bản nháp, người dùng sẽ chưa nhìn thấy.',
                ),
                value: _isPublished,
                onChanged: (value) => setState(() => _isPublished = value),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Lưu thông báo'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: const Color(0xFFB02A76),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MessageState({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.black38),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
