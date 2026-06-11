import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/screens/create_profile_screen.dart';
import '../../auth/widgets/change_password_dialog.dart';
import '../../budget/screens/budget_list_screen.dart';
import '../../debt/screens/debt_list_screen.dart';
import '../../goal/screens/goal_list_screen.dart';
import '../../notification/screens/notification_settings_screen.dart';
import '../../../services/demo_data_service.dart';

class UtilityScreen extends StatefulWidget {
  const UtilityScreen({super.key});

  @override
  State<UtilityScreen> createState() => _UtilityScreenState();
}

class _UtilityScreenState extends State<UtilityScreen> {
  final DemoDataService _demoDataService = DemoDataService();
  bool _isSeedingDemoData = false;

  Future<void> _seedDemoData(BuildContext context) async {
    if (_isSeedingDemoData) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tạo dữ liệu demo'),
        content: const Text(
          'Ứng dụng sẽ thêm bộ dữ liệu mẫu vào tài khoản hiện tại: ví, giao dịch, danh mục, ngân sách, mục tiêu và hóa đơn định kỳ. Bạn có muốn tiếp tục không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF06292),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Tạo dữ liệu',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSeedingDemoData = true);
    try {
      await _demoDataService.seedDemoDataForCurrentUser();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Đã tạo dữ liệu demo hoàn chỉnh cho tài khoản hiện tại.',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tạo dữ liệu demo: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSeedingDemoData = false);
      }
    }
  }

  Future<void> _openChangePasswordDialog(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (user == null || email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Tài khoản này chưa hỗ trợ đổi mật khẩu trực tiếp.',
          ),
          backgroundColor: const Color(0xFFF06292),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final hasPasswordProvider = user.providerData.any(
      (provider) => provider.providerId == 'password',
    );
    if (!hasPasswordProvider) {
      final shouldSendResetEmail = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Thiết lập mật khẩu'),
          content: Text(
            'Tài khoản $email đang đăng nhập bằng nhà cung cấp bên ngoài. '
            'Bạn có muốn nhận email thiết lập mật khẩu để có thể đăng nhập '
            'bằng email/mật khẩu không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF06292),
              ),
              child: const Text(
                'Gửi email',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );

      if (shouldSendResetEmail == true) {
        try {
          await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã gửi email thiết lập mật khẩu đến $email.'),
              backgroundColor: Colors.green,
            ),
          );
        } on FirebaseAuthException catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Không thể gửi email: ${e.message ?? e.code}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
      return;
    }

    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => ChangePasswordDialog(user: user),
    );

    if (changed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã đổi mật khẩu thành công.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ignore: unused_element
  Future<void> _changePassword(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (user == null || email == null || email.isEmpty) {
      _showComingSoon(
        context,
        'Tài khoản này chưa hỗ trợ đổi mật khẩu trực tiếp',
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Đổi mật khẩu'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: currentController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu hiện tại',
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Vui lòng nhập mật khẩu hiện tại'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu mới',
                    ),
                    validator: (value) {
                      if (value == null || value.length < 8) {
                        return 'Mật khẩu mới phải có ít nhất 8 ký tự';
                      }
                      if (!RegExp(
                        r'^(?=.*[A-Z])(?=.*[a-z])(?=.*[0-9])[A-Za-z0-9@]{8,32}$',
                      ).hasMatch(value)) {
                        return 'Cần chữ hoa, chữ thường, số; chỉ dùng a-z, A-Z, 0-9, @';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Xác nhận mật khẩu mới',
                    ),
                    validator: (value) => value != newController.text
                        ? 'Mật khẩu xác nhận không khớp'
                        : null,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => isSaving = true);
                        try {
                          final credential = EmailAuthProvider.credential(
                            email: email,
                            password: currentController.text,
                          );
                          await user.reauthenticateWithCredential(credential);
                          await user.updatePassword(newController.text);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã đổi mật khẩu thành công.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } on FirebaseAuthException catch (e) {
                          String message = 'Không thể đổi mật khẩu.';
                          if (e.code == 'wrong-password' ||
                              e.code == 'invalid-credential') {
                            message = 'Mật khẩu hiện tại không chính xác.';
                          } else if (e.code == 'weak-password') {
                            message = 'Mật khẩu mới quá yếu.';
                          } else if (e.code == 'requires-recent-login') {
                            message =
                                'Vui lòng đăng nhập lại rồi đổi mật khẩu.';
                          }
                          if (!ctx.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(message),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        } finally {
                          if (ctx.mounted) {
                            setDialogState(() => isSaving = false);
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF06292),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Lưu', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );

    currentController.dispose();
    newController.dispose();
    confirmController.dispose();
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF06292),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Đăng xuất',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // AuthWrapper in main.dart listens to authStateChanges and will handle routing
    // automatically when signOut is called. We just need to pop any pushed routes.
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
    await FirebaseAuth.instance.signOut();
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature sẽ sớm được cập nhật'),
        backgroundColor: const Color(0xFFF06292),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF06292).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFFF06292)),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          // Profile Header — tappable to edit profile
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreateProfileScreen(isEditing: true),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF06292), Color(0xFFF48FB1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseAuth.instance.currentUser != null
                        ? FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser!.uid)
                              .snapshots()
                        : null,
                    builder: (context, snapshot) {
                      String? avatarUrl;
                      String displayName = 'Người dùng';
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data =
                            snapshot.data!.data() as Map<String, dynamic>? ??
                            {};
                        avatarUrl = data['avatarUrl'] as String?;
                        displayName =
                            (data['fullName'] as String? ?? '').isNotEmpty
                            ? data['fullName'] as String
                            : 'Người dùng';
                      }
                      return Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              image:
                                  avatarUrl != null &&
                                      avatarUrl.startsWith('http')
                                  ? DecorationImage(
                                      image: NetworkImage(avatarUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child:
                                avatarUrl == null ||
                                    !avatarUrl.startsWith('http')
                                ? const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 36,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tài khoản của tôi',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.edit_outlined,
                    color: Colors.white70,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Cài đặt chung',
            style: TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingsTile(
            icon: _isSeedingDemoData ? Icons.hourglass_top : Icons.auto_awesome,
            title: _isSeedingDemoData
                ? 'Đang tạo dữ liệu demo...'
                : 'Tạo dữ liệu demo bán hàng',
            onTap: () => _seedDemoData(context),
          ),
          _buildSettingsTile(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Quản lý Ngân sách',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BudgetListScreen()),
            ),
          ),
          _buildSettingsTile(
            icon: Icons.savings_outlined,
            title: 'Quản lý Mục tiêu tiết kiệm',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GoalListScreen()),
            ),
          ),
          _buildSettingsTile(
            icon: Icons.handshake_outlined,
            title: 'Quản lý Sổ nợ',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DebtListScreen()),
            ),
          ),
          _buildSettingsTile(
            icon: Icons.person_outline,
            title: 'Chỉnh sửa hồ sơ',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CreateProfileScreen(isEditing: true),
              ),
            ),
          ),
          _buildSettingsTile(
            icon: Icons.lock_outline,
            title: 'Bảo mật & Mật khẩu',
            onTap: () => _openChangePasswordDialog(context),
          ),
          _buildSettingsTile(
            icon: Icons.notifications_none,
            title: 'Thông báo',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationSettingsScreen(),
              ),
            ),
          ),
          _buildSettingsTile(
            icon: Icons.help_outline,
            title: 'Trợ giúp & Hỗ trợ',
            onTap: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text('Trợ giúp & Hỗ trợ'),
                content: const Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📧 Email: support@finance.app'),
                    SizedBox(height: 8),
                    Text('📞 Hotline: 1800-xxxx'),
                    SizedBox(height: 8),
                    Text('⏰ Hỗ trợ 24/7'),
                  ],
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
            ),
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF06292).withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => _logout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF06292),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'ĐĂNG XUẤT',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
