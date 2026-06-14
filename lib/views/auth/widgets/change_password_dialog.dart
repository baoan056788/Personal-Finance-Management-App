import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../utils/input_constraints.dart';

class ChangePasswordDialog extends StatefulWidget {
  final User user;

  const ChangePasswordDialog({super.key, required this.user});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final email = widget.user.email;
    if (email == null || email.isEmpty) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: _currentController.text,
      );
      await widget.user.reauthenticateWithCredential(credential);
      await widget.user.updatePassword(_newController.text);
      if (!mounted) return;
      Navigator.pop(context, true);
    } on FirebaseAuthException catch (e) {
      String message = 'Không thể đổi mật khẩu.';
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'Mật khẩu hiện tại không chính xác.';
      } else if (e.code == 'weak-password') {
        message = 'Mật khẩu mới quá yếu.';
      } else if (e.code == 'requires-recent-login') {
        message = 'Vui lòng đăng nhập lại rồi đổi mật khẩu.';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSaving,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đổi mật khẩu'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _currentController,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu hiện tại',
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Vui lòng nhập mật khẩu hiện tại'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _newController,
                  obscureText: true,
                  inputFormatters: newPasswordInputFormatters(),
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
                  validator: (value) {
                    final password = value ?? '';
                    if (password.length < 8) {
                      return 'Mật khẩu mới phải có ít nhất 8 ký tự';
                    }
                    if (password.length > 32) {
                      return 'Mật khẩu mới không vượt quá 32 ký tự';
                    }
                    if (!RegExp(
                      r'^(?=.*[A-Z])(?=.*[a-z])(?=.*[0-9])[A-Za-z0-9@]{8,32}$',
                    ).hasMatch(password)) {
                      return 'Cần chữ hoa, chữ thường, số; chỉ dùng a-z, A-Z, 0-9, @';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmController,
                  obscureText: true,
                  inputFormatters: newPasswordInputFormatters(),
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (!_isSaving) _save();
                  },
                  decoration: const InputDecoration(
                    labelText: 'Xác nhận mật khẩu mới',
                  ),
                  validator: (value) => value != _newController.text
                      ? 'Mật khẩu xác nhận không khớp'
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF06292),
            ),
            child: _isSaving
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
      ),
    );
  }
}
