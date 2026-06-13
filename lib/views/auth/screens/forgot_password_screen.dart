import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../utils/auth_validation.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const int _resendDelaySeconds = 30;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  Timer? _countdownTimer;
  bool _isSending = false;
  bool _emailSent = false;
  int _secondsUntilResend = 0;
  String _submittedEmail = '';

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: widget.initialEmail.trim().toLowerCase(),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim().toLowerCase();
    if (_isSending) return;
    if (validateEmailAddress(email) != null) {
      _formKey.currentState?.validate();
      return;
    }

    setState(() => _isSending = true);
    try {

      // Remove setLanguageCode('vi') as it might cause issues if the localized template is missing or invalid in Firebase Console
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi yêu cầu. Vui lòng kiểm tra hộp thư đến và Thư rác (Spam).'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      setState(() {
        _submittedEmail = email;
        _emailSent = true;
      });
      _startResendCountdown();
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      // Do not reveal whether an account exists for the supplied email.
      if (error.code == 'user-not-found') {
        setState(() {
          _submittedEmail = email;
          _emailSent = true;
        });
        _startResendCountdown();
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(passwordResetErrorMessage(error.code)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lỗi: ${e.toString()}',
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _startResendCountdown() {
    _countdownTimer?.cancel();
    setState(() => _secondsUntilResend = _resendDelaySeconds);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsUntilResend <= 1) {
        timer.cancel();
        setState(() => _secondsUntilResend = 0);
      } else {
        setState(() => _secondsUntilResend--);
      }
    });
  }

  void _changeEmail() {
    _countdownTimer?.cancel();
    setState(() {
      _emailSent = false;
      _secondsUntilResend = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Khôi phục mật khẩu'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _emailSent ? _buildEmailSentState() : _buildEmailForm(),
        ),
      ),
    );
  }

  Widget _buildEmailForm() {
    return SingleChildScrollView(
      key: const ValueKey('email-form'),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.lock_reset, size: 72, color: Color(0xFFB02A76)),
            const SizedBox(height: 24),
            const Text(
              'Quên mật khẩu?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Nhập email đã dùng để đăng ký. Chúng tôi sẽ gửi liên kết tạo mật khẩu mới.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, height: 1.5),
            ),
            const SizedBox(height: 28),
            TextFormField(
              controller: _emailController,
              autofocus: widget.initialEmail.trim().isEmpty,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              maxLength: 100,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'name@example.com',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              validator: validateEmailAddress,
              onFieldSubmitted: (_) => _sendResetEmail(),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isSending ? null : _sendResetEmail,
              icon: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(_isSending ? 'Đang gửi...' : 'Gửi liên kết'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: const Color(0xFFB02A76),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Quay lại đăng nhập'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailSentState() {
    return SingleChildScrollView(
      key: const ValueKey('email-sent'),
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.mark_email_read_outlined,
            size: 82,
            color: Colors.green,
          ),
          const SizedBox(height: 24),
          const Text(
            'Kiểm tra hộp thư của bạn',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Nếu tài khoản tồn tại, liên kết tạo mật khẩu mới đã được gửi đến\n$_submittedEmail',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, height: 1.5),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Không thấy email? Hãy kiểm tra thư rác hoặc chờ vài phút. Liên kết trong email sẽ mở trang bảo mật của Firebase để bạn đặt mật khẩu mới.',
              style: TextStyle(height: 1.5),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: const Color(0xFFB02A76),
            ),
            child: const Text('Quay lại đăng nhập'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _secondsUntilResend == 0 && !_isSending
                ? _sendResetEmail
                : null,
            child: Text(
              _secondsUntilResend > 0
                  ? 'Gửi lại sau $_secondsUntilResend giây'
                  : 'Gửi lại email',
            ),
          ),
          TextButton(
            onPressed: _isSending ? null : _changeEmail,
            child: const Text('Dùng email khác'),
          ),
        ],
      ),
    );
  }
}
