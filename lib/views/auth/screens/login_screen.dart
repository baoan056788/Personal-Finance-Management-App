import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'otp_screen.dart';
import 'password_login_screen.dart';
import 'create_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  // Single loading lock — prevents any double-tap from firing a second request.
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _processLogin() async {
    // ── Guard: ignore if already processing ─────────────────────────────────
    if (_isLoading) return;

    // ── Dismiss keyboard before validation so it doesn't absorb tap events ──
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final String localDigits = _phoneController.text.trim();
    final String fullPhoneNumber = '+84$localDigits';
    final String syntheticEmail = '$localDigits@tinora.local';

    try {
      // ── Source of truth: Firestore — NOT Firebase Auth ───────────────────
      final QuerySnapshot userDocs = await FirebaseFirestore.instance
          .collection('users')
          .where('phoneNumber', isEqualTo: fullPhoneNumber)
          .limit(1)
          .get();

      if (!mounted) return;

      final bool firestoreDocExists = userDocs.docs.isNotEmpty;
      final bool passwordCreated = firestoreDocExists &&
          (userDocs.docs.first.data() as Map<String, dynamic>)['passwordCreated'] == true;

      if (firestoreDocExists && passwordCreated) {
        // ── CASE: existing user → Password Login ────────────────────────────
        // Reset loading BEFORE push so the button is clean if user pops back.
        setState(() => _isLoading = false);
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PasswordLoginScreen(
              phoneNumber: fullPhoneNumber,
              syntheticEmail: syntheticEmail,
            ),
          ),
        );
      } else {
        // ── CASE: new / incomplete user → OTP ──────────────────────────────
        // Keep _isLoading = true until codeSent fires and we navigate.
        // _sendOtp callbacks are responsible for resetting loading on error.
        if (FirebaseAuth.instance.currentUser != null) {
          await FirebaseAuth.instance.signOut();
        }
        if (!mounted) return;
        await _sendOtp(fullPhoneNumber);
        // Do NOT reset _isLoading here — codeSent/verificationFailed manage it.
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xảy ra lỗi: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _sendOtp(String fullPhoneNumber) async {
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: fullPhoneNumber,
        // Android auto-retrieval: skip OTP screen, go straight to password creation
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          if (!mounted) return;
          setState(() => _isLoading = false);
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const CreatePasswordScreen(isResetPassword: false),
            ),
            (route) => route.isFirst,
          );
        },
        // OTP send failed — reset loading so user can retry
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Xác thực thất bại: ${e.message}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        },
        // OTP sent — navigate to OTP screen, reset loading there
        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtpScreen(
                verificationId: verificationId,
                phoneNumber: fullPhoneNumber,
                isResetPassword: false,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xảy ra lỗi gửi OTP: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: _isLoading
              ? null
              : () {
                  if (Navigator.canPop(context)) Navigator.pop(context);
                },
        ),
        title: const Text(
          'Nhập SĐT',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Số điện thoại\ncủa bạn',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                    color: Color(0xFFB02A76),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Vui lòng nhập số điện thoại của bạn\nđể tiếp tục trải nghiệm Tinora.',
                  style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
                ),
                const SizedBox(height: 40),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFB02A76), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🇻🇳', style: TextStyle(fontSize: 20)),
                            SizedBox(width: 8),
                            Text(
                              '+84',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 24, color: Colors.grey.shade300),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _processLogin(),
                          decoration: const InputDecoration(
                            hintText: 'Nhập 9 chữ số (VD: 377648013)',
                            hintStyle: TextStyle(color: Colors.black26, fontSize: 13),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập số điện thoại';
                            }
                            final String p = value.trim();
                            if (!RegExp(r'^[0-9]+$').hasMatch(p)) {
                              return 'Số điện thoại chỉ được chứa chữ số';
                            }
                            if (p.length != 9) {
                              return 'Phải nhập đúng 9 chữ số (bỏ số 0 đầu)';
                            }
                            if (!RegExp(r'^[35789]').hasMatch(p)) {
                              return 'Không hợp lệ (bắt đầu bằng 3, 5, 7, 8, 9)';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'Ví dụ: số 0377648013 → nhập 377648013',
                    style: TextStyle(fontSize: 12, color: Colors.black38),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(12),
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
                            Text(
                              'Bảo mật tuyệt đối',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Thông tin của bạn được mã hóa và bảo\nvệ theo tiêu chuẩn quốc tế PCI DSS.',
                              style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  // Disabled (null) while loading — prevents any double-tap
                  onPressed: _isLoading ? null : _processLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB02A76),
                    disabledBackgroundColor: const Color(0xFFB02A76).withValues(alpha: 0.6),
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
                            Text('Tiếp tục',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 20),
                          ],
                        ),
                ),
                const SizedBox(height: 24),
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.5),
                    children: [
                      TextSpan(text: 'Bằng việc tiếp tục, bạn đồng ý với '),
                      TextSpan(
                        text: 'Điều khoản dịch vụ',
                        style: TextStyle(
                            color: Color(0xFFB02A76), fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: ' &\n'),
                      TextSpan(
                        text: 'Chính sách bảo mật',
                        style: TextStyle(
                            color: Color(0xFFB02A76), fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: ' của chúng tôi.'),
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
