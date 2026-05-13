import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../home/home_view.dart';
import 'create_profile_screen.dart';

class CreatePasswordScreen extends StatefulWidget {
  final bool isResetPassword;

  const CreatePasswordScreen({
    super.key,
    this.isResetPassword = false,
  });

  @override
  State<CreatePasswordScreen> createState() => _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends State<CreatePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _savePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Chưa đăng nhập');

      String phoneStr = user.phoneNumber ?? '';
      if (phoneStr.startsWith('+84')) {
        phoneStr = phoneStr.substring(3);
      } else if (phoneStr.startsWith('0')) {
        phoneStr = phoneStr.substring(1);
      }
      final syntheticEmail = '$phoneStr@tinora.local';

      if (widget.isResetPassword) {
        await user.updatePassword(_passwordController.text);
      } else {
        // Link new password to the phone authenticated account
        try {
          AuthCredential credential = EmailAuthProvider.credential(
            email: syntheticEmail,
            password: _passwordController.text,
          );
          await user.linkWithCredential(credential);
        } catch (linkError) {
          // If linking fails (maybe already linked or other error), we can fallback to update
          await user.updatePassword(_passwordController.text);
        }
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'phoneNumber': user.phoneNumber,
        'passwordCreated': true,
        'onboardingCompleted': false,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      if (widget.isResetPassword) {
        // Just go to Home
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeView()),
          (route) => false,
        );
      } else {
        // Go to profile creation for new users
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CreateProfileScreen()),
        );
      }

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFB02A76)),
          onPressed: () {
            if (Navigator.canPop(context)) Navigator.pop(context);
          },
        ),
        title: const Text('Create Password', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Tạo mật khẩu',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFFB02A76)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Thiết lập mật khẩu để bảo vệ tài khoản\ncủa bạn',
                  style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
                ),
                const SizedBox(height: 40),
                const Text('Mật khẩu', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Nhập mật khẩu',
                      hintStyle: const TextStyle(color: Colors.black26),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Colors.black45),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    onChanged: (val) => setState(() {}),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu';
                      if (value.contains(' ')) return 'Mật khẩu không được chứa khoảng trắng';
                      if (value.length < 8) return 'Mật khẩu phải có ít nhất 8 ký tự';
                      if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) return 'Mật khẩu phải chứa ít nhất 1 chữ in hoa';
                      if (!RegExp(r'(?=.*[a-z])').hasMatch(value)) return 'Mật khẩu phải chứa ít nhất 1 chữ thường';
                      if (!RegExp(r'(?=.*[0-9])').hasMatch(value)) return 'Mật khẩu phải chứa ít nhất 1 chữ số';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 14,
                      color: _passwordController.text.length >= 8 ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Mật khẩu phải có ít nhất 8 ký tự',
                      style: TextStyle(
                        fontSize: 11,
                        color: _passwordController.text.length >= 8 ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Xác nhận mật khẩu', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _confirmPasswordController.text.isNotEmpty && _confirmPasswordController.text != _passwordController.text
                            ? Colors.redAccent
                            : Colors.grey.shade200),
                  ),
                  child: TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Nhập lại mật khẩu',
                      hintStyle: const TextStyle(color: Colors.black26),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: Colors.black45),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                    ),
                    onChanged: (val) => setState(() {}),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Vui lòng xác nhận mật khẩu';
                      if (value != _passwordController.text) return 'Mật khẩu không khớp';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 8),
                if (_confirmPasswordController.text.isNotEmpty && _confirmPasswordController.text != _passwordController.text)
                  const Text(
                    'Mật khẩu không khớp',
                    style: TextStyle(fontSize: 11, color: Colors.redAccent),
                  ),
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFDEBEE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.security, color: Color(0xFFB02A76), size: 16),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bảo mật đa tầng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                            SizedBox(height: 4),
                            Text(
                              'Tài khoản của bạn được bảo vệ bởi công nghệ\nmã hóa chuẩn ngân hàng.',
                              style: TextStyle(fontSize: 11, color: Colors.black54, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: _isLoading ? null : _savePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB02A76),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Tiếp tục', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 20),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
