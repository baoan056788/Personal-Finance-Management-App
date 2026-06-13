import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/admin_user_model.dart';
import '../../../services/admin_service.dart';
import 'admin_user_detail_screen.dart';

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  final AdminService _service = AdminService();
  final TextEditingController _searchController = TextEditingController();
  List<AdminUserModel> _users = const [];
  Timer? _debounce;
  bool _isLoading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String _) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _loadUsers);
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final users = await _service.listUsers(query: _searchController.text);
      if (!mounted) return;
      setState(() => _users = users);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Tìm theo họ tên hoặc email',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Xóa tìm kiếm',
                        onPressed: () {
                          _searchController.clear();
                          _loadUsers();
                        },
                        icon: const Icon(Icons.clear),
                      ),
                filled: true,
                fillColor: const Color(0xFFF5F6F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
        if (_isLoading) const LinearProgressIndicator(minHeight: 2),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading && _users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _users.isEmpty) {
      return _MessageState(
        icon: Icons.cloud_off_outlined,
        title: 'Không thể tải người dùng',
        detail: '$_error',
        onRetry: _loadUsers,
      );
    }
    if (_users.isEmpty) {
      return _MessageState(
        icon: Icons.person_search_outlined,
        title: 'Không tìm thấy người dùng',
        detail: 'Hãy thử từ khóa khác.',
        onRetry: _loadUsers,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length + 1,
        itemBuilder: (context, index) {
          if (index == _users.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Đã hiển thị ${_users.length} tài khoản',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black45),
              ),
            );
          }
          return _UserTile(
            user: _users[index],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AdminUserDetailScreen(user: _users[index]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final AdminUserModel user;
  final VoidCallback onTap;

  const _UserTile({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final createdAt = user.createdAt == null
        ? 'Không rõ ngày tạo'
        : DateFormat('dd/MM/yyyy').format(user.createdAt!.toLocal());
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFFE2F0),
          backgroundImage:
              user.avatarUrl != null && user.avatarUrl!.startsWith('http')
              ? NetworkImage(user.avatarUrl!)
              : null,
          child: user.avatarUrl == null || !user.avatarUrl!.startsWith('http')
              ? Text(
                  user.fullName.isEmpty ? '?' : user.fullName[0].toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFB02A76),
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (user.isAdmin)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(
                  Icons.admin_panel_settings,
                  size: 18,
                  color: Color(0xFF4F6BED),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text(
              'Đăng ký $createdAt',
              style: const TextStyle(fontSize: 12, color: Colors.black45),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  final Future<void> Function() onRetry;

  const _MessageState({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onRetry,
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
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tải lại'),
            ),
          ],
        ),
      ),
    );
  }
}
