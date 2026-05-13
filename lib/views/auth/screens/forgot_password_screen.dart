import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // ── Step control ──────────────────────────────────────────────────────────
  int _step = 1; // 1 = phone, 2 = otp, 3 = new password

  // ── Step 1: Phone ─────────────────────────────────────────────────────────
  final _phoneFormKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isSendingOtp = false;

  // ── Step 2: OTP ───────────────────────────────────────────────────────────
  String _otp = '';
  String _verificationId = '';
  bool _isVerifyingOtp = false;
  int _secondsRemaining = 59;
  Timer? _timer;

  // ── Step 3: Password ──────────────────────────────────────────────────────
  final _passwordFormKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSavingPassword = false;

  // ── Derived ───────────────────────────────────────────────────────────────
  String get _fullPhone {
    final local = _phoneController.text.trim();
    if (local.startsWith('0')) {
      return '+84${local.substring(1)}';
    }
    return '+84$local';
  }

  // ── Timer ─────────────────────────────────────────────────────────────────
  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsRemaining = 59);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ── Step 1: Send OTP ──────────────────────────────────────────────────────
  Future<void> _sendOtp() async {
    // Guard against double-tap
    if (_isSendingOtp) return;
    if (!_phoneFormKey.currentState!.validate()) return;

    setState(() => _isSendingOtp = true);
    try {
      // Verify phone exists in Firestore BEFORE sending OTP
      final docs = await FirebaseFirestore.instance
          .collection('users')
          .where('phoneNumber', isEqualTo: _fullPhone)
          .limit(1)
          .get();

      if (docs.docs.isEmpty) {
        if (!mounted) return;
        setState(() => _isSendingOtp = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Số điện thoại này chưa đăng ký tài khoản'),
          backgroundColor: Colors.redAccent,
        ));
        return;
      }

      // Keep _isSendingOtp = true — only reset in callbacks below
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _fullPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          if (!mounted) return;
          setState(() { _isSendingOtp = false; _step = 3; });
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          setState(() => _isSendingOtp = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Gửi OTP thất bại: ${e.message}'),
            backgroundColor: Colors.redAccent,
          ));
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _isSendingOtp = false;
            _step = 2;
          });
          _startTimer();
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSendingOtp = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Lỗi: $e'),
        backgroundColor: Colors.redAccent,
      ));
    }
    // No finally — callbacks above manage the loading state
  }

  // ── Step 2: Verify OTP ────────────────────────────────────────────────────
  Future<void> _verifyOtp() async {
    if (_otp.length != 6 || _isVerifyingOtp) return; // guard double-fire
    setState(() => _isVerifyingOtp = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otp,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (!mounted) return;
      setState(() { _isVerifyingOtp = false; _step = 3; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _isVerifyingOtp = false; _otp = ''; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Mã OTP không đúng hoặc đã hết hạn'),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  void _onKeyPressed(String value) {
    if (_isVerifyingOtp || _isSendingOtp || _otp.length >= 6) return;
    setState(() => _otp += value);
    if (_otp.length == 6) _verifyOtp();
  }

  void _onBackspace() {
    if (_otp.isEmpty) return;
    setState(() => _otp = _otp.substring(0, _otp.length - 1));
  }

  // ── Step 3: Save new password ─────────────────────────────────────────────
  Future<void> _savePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    setState(() => _isSavingPassword = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Phiên đăng nhập hết hạn');

      // Update Firebase Auth password
      await user.updatePassword(_newPasswordController.text);

      // Update Firestore updatedAt — do NOT create a new document
      final docs = await FirebaseFirestore.instance
          .collection('users')
          .where('phoneNumber', isEqualTo: _fullPhone)
          .limit(1)
          .get();
      if (docs.docs.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(docs.docs.first.id)
            .update({'updatedAt': FieldValue.serverTimestamp()});
      }

      // Sign out — user must log in with new password
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      Navigator.pop(context, true); // signal success to caller
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingPassword = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Lỗi đổi mật khẩu: $e'),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  // ── UI helpers ────────────────────────────────────────────────────────────
  static const _pink = Color(0xFFB02A76);

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final active = i + 1 == _step;
        final done = i + 1 < _step;
        return Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: active ? 32 : 12,
              height: 12,
              decoration: BoxDecoration(
                color: (active || done) ? _pink : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            if (i < 2) const SizedBox(width: 6),
          ],
        );
      }),
    );
  }

  InputDecoration _inputDec(String hint, {Widget? suffix}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black26),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: suffix,
      );

  BoxDecoration _fieldBox({Color? borderColor}) => BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor ?? Colors.grey.shade200),
      );

  // ── Step 1 widget ─────────────────────────────────────────────────────────
  Widget _buildStep1() {
    return Form(
      key: _phoneFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Số điện thoại\ncủa bạn',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, height: 1.2, color: _pink)),
          const SizedBox(height: 12),
          const Text('Nhập số điện thoại đã đăng ký để nhận mã OTP đặt lại mật khẩu.',
              style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5)),
          const SizedBox(height: 36),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _pink, width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('🇻🇳', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 8),
                    Text('+84', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ]),
                ),
                Container(width: 1, height: 24, color: Colors.grey.shade300),
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    decoration: const InputDecoration(
                      hintText: 'Nhập 9 chữ số (VD: 377648013)',
                      hintStyle: TextStyle(color: Colors.black26, fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Vui lòng nhập số điện thoại';
                      final p = v.trim();
                      if (!RegExp(r'^[0-9]+$').hasMatch(p)) return 'Chỉ được nhập chữ số';
                      if (p.length != 9) return 'Phải nhập đúng 9 chữ số (bỏ số 0 đầu)';
                      if (!RegExp(r'^[35789]').hasMatch(p)) return 'Không hợp lệ (bắt đầu bằng 3,5,7,8,9)';
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text('Ví dụ: 0377648013 → nhập 377648013',
              style: TextStyle(fontSize: 12, color: Colors.black38)),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _isSendingOtp ? null : _sendOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: _pink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 0,
            ),
            child: _isSendingOtp
                ? const SizedBox(height: 24, width: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Gửi mã OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Step 2 widget ─────────────────────────────────────────────────────────
  Widget _buildOtpBox(int index) {
    final filled = index < _otp.length;
    final current = index == _otp.length;
    return Container(
      width: 44, height: 54,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: filled || current ? _pink : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        filled ? _otp[index] : '',
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _pink),
      ),
    );
  }

  Widget _buildKeyBtn(String label) => InkWell(
        onTap: () => _onKeyPressed(label),
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(width: 60, height: 48,
            child: Center(child: Text(label,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500)))),
      );

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Nhập mã OTP',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _pink)),
        const SizedBox(height: 12),
        Text('Mã đã gửi đến +84${_phoneController.text.trim()}',
            style: const TextStyle(fontSize: 14, color: Colors.black54)),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, _buildOtpBox),
        ),
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: _secondsRemaining == 0 && !_isSendingOtp
                ? () {
                    setState(() { _otp = ''; _isSendingOtp = true; });
                    _sendOtp();
                  }
                : null,
            child: Text(
              _secondsRemaining > 0 ? 'Gửi lại mã (${_secondsRemaining}s)' : 'Gửi lại mã',
              style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold,
                color: _secondsRemaining == 0 ? _pink : Colors.grey,
                decoration: _secondsRemaining == 0 ? TextDecoration.underline : TextDecoration.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (_isVerifyingOtp) const Center(child: CircularProgressIndicator(color: _pink)),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _otp.length == 6 && !_isVerifyingOtp ? _verifyOtp : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _pink,
            disabledBackgroundColor: Color.fromRGBO(176, 42, 118, 0.4),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 0,
          ),
          child: const Text('Xác nhận OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 24),
        // Custom keypad
        for (final row in [['1','2','3'],['4','5','6'],['7','8','9']])
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map(_buildKeyBtn).toList(),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 60),
            _buildKeyBtn('0'),
            InkWell(
              onTap: _onBackspace,
              borderRadius: BorderRadius.circular(24),
              child: const SizedBox(width: 60, height: 48,
                  child: Icon(Icons.backspace_outlined, color: Colors.black87)),
            ),
          ],
        ),
      ],
    );
  }

  // ── Step 3 widget ─────────────────────────────────────────────────────────
  Widget _buildStep3() {
    return Form(
      key: _passwordFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Tạo mật khẩu mới',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _pink)),
          const SizedBox(height: 12),
          const Text('Nhập mật khẩu mới cho tài khoản của bạn.',
              style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5)),
          const SizedBox(height: 36),
          const Text('Mật khẩu mới', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            decoration: _fieldBox(),
            child: TextFormField(
              controller: _newPasswordController,
              obscureText: _obscureNew,
              onChanged: (_) => setState(() {}),
              decoration: _inputDec('Nhập mật khẩu mới',
                  suffix: IconButton(
                    icon: Icon(_obscureNew ? Icons.visibility : Icons.visibility_off,
                        color: Colors.black45),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  )),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
                if (v.contains(' ')) return 'Mật khẩu không được chứa khoảng trắng';
                if (v.length < 8) return 'Tối thiểu 8 ký tự';
                if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Cần ít nhất 1 chữ hoa';
                if (!RegExp(r'[a-z]').hasMatch(v)) return 'Cần ít nhất 1 chữ thường';
                if (!RegExp(r'[0-9]').hasMatch(v)) return 'Cần ít nhất 1 chữ số';
                return null;
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.check_circle,
                size: 14,
                color: _newPasswordController.text.length >= 8 ? Colors.green : Colors.grey),
            const SizedBox(width: 6),
            Text('Tối thiểu 8 ký tự',
                style: TextStyle(fontSize: 11,
                    color: _newPasswordController.text.length >= 8 ? Colors.green : Colors.grey)),
          ]),
          const SizedBox(height: 20),
          const Text('Xác nhận mật khẩu', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            decoration: _fieldBox(),
            child: TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              decoration: _inputDec('Nhập lại mật khẩu',
                  suffix: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility,
                        color: Colors.black45),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  )),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Vui lòng xác nhận mật khẩu';
                if (v != _newPasswordController.text) return 'Mật khẩu không khớp';
                return null;
              },
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _isSavingPassword ? null : _savePassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: _pink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 0,
            ),
            child: _isSavingPassword
                ? const SizedBox(height: 24, width: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Lưu mật khẩu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _pink),
          onPressed: () {
            if (_step > 1) {
              setState(() {
                _otp = '';
                _step--;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text('Quên mật khẩu',
            style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStepIndicator(),
              const SizedBox(height: 32),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: _step == 1
                      ? _buildStep1()
                      : _step == 2
                          ? _buildStep2()
                          : _buildStep3(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
