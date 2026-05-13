import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'create_password_screen.dart';

class OtpScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;
  final bool isResetPassword;

  const OtpScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    this.isResetPassword = false,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  String _otp = '';
  bool _isLoading = false;
  int _secondsRemaining = 59;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

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
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    // ── Guard: only run when exactly 6 digits and not already loading ────────
    if (_otp.length != 6 || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: _otp,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !widget.isResetPassword) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (!doc.exists) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'phoneNumber': widget.phoneNumber,
            'passwordCreated': false,
            'onboardingCompleted': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      if (!mounted) return;

      // Loading resets automatically when we leave this screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => CreatePasswordScreen(
            isResetPassword: widget.isResetPassword,
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      // Reset OTP and loading so user can re-enter
      setState(() {
        _isLoading = false;
        _otp = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mã OTP không đúng hoặc đã hết hạn'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _onKeyPressed(String value) {
    // ── Guard: ignore input while verifying or when OTP is already full ──────
    if (_isLoading || _otp.length >= 6) return;
    setState(() => _otp += value);
    // Auto-verify the moment the 6th digit is entered
    if (_otp.length == 6) _verifyOtp();
  }

  void _onBackspace() {
    if (_isLoading || _otp.isEmpty) return;
    setState(() => _otp = _otp.substring(0, _otp.length - 1));
  }

  Widget _buildOtpBox(int index) {
    final bool isFilled = index < _otp.length;
    final bool isCurrent = index == _otp.length && !_isLoading;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 45,
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent
              ? const Color(0xFFB02A76)
              : isFilled
                  ? const Color(0xFFB02A76).withValues(alpha: 0.6)
                  : Colors.grey.shade200,
          width: isCurrent ? 2 : 1.5,
        ),
        boxShadow: [
          if (isCurrent)
            BoxShadow(
              color: const Color(0xFFB02A76).withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      alignment: Alignment.center,
      child: _isLoading && isFilled
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                color: Color(0xFFB02A76),
                strokeWidth: 2,
              ),
            )
          : Text(
              isFilled ? _otp[index] : '',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB02A76),
              ),
            ),
    );
  }

  Widget _buildKeypadButton(String text) {
    return InkWell(
      onTap: _isLoading ? null : () => _onKeyPressed(text),
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        width: 64,
        height: 52,
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: _isLoading ? Colors.black26 : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return InkWell(
      onTap: _isLoading ? null : _onBackspace,
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        width: 64,
        height: 52,
        child: Center(
          child: Icon(
            Icons.backspace_outlined,
            color: _isLoading ? Colors.black26 : Colors.black87,
            size: 24,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ensure keyboard is dismissed — OTP uses custom keypad
    FocusScope.of(context).unfocus();

    final bool canConfirm = _otp.length == 6 && !_isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFB02A76)),
          onPressed: _isLoading
              ? null
              : () {
                  if (Navigator.canPop(context)) Navigator.pop(context);
                },
        ),
        title: const Text(
          'Xác thực OTP',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Scrollable content ────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDEBEE),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.security, color: Color(0xFFB02A76), size: 32),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Nhập mã OTP',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black54, height: 1.5),
                        children: [
                          const TextSpan(text: 'Mã đã được gửi đến số '),
                          TextSpan(
                            text: widget.phoneNumber,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // ── OTP boxes ─────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, _buildOtpBox),
                    ),
                    const SizedBox(height: 24),
                    // ── Resend timer ─────────────────────────────────────
                    GestureDetector(
                      onTap: _secondsRemaining == 0 && !_isLoading
                          ? () {
                              setState(() => _otp = '');
                              _startTimer();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Quay lại để nhập số điện thoại và gửi lại mã'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          : null,
                      child: Text(
                        _secondsRemaining > 0
                            ? 'Gửi lại mã (${_secondsRemaining}s)'
                            : 'Gửi lại mã',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _secondsRemaining == 0 ? const Color(0xFFB02A76) : Colors.grey,
                          decoration: _secondsRemaining == 0
                              ? TextDecoration.underline
                              : TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ── Fixed bottom keypad ───────────────────────────────────────
            Container(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 32, top: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFB02A76).withValues(alpha: 0.05),
                    blurRadius: 40,
                    offset: const Offset(0, -20),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // ── Confirm button — active only when 6 digits entered ──
                  SizedBox(
                    width: double.infinity,
                    child: AnimatedOpacity(
                      opacity: canConfirm ? 1.0 : 0.5,
                      duration: const Duration(milliseconds: 200),
                      child: ElevatedButton(
                        onPressed: canConfirm ? _verifyOtp : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB02A76),
                          disabledBackgroundColor: const Color(0xFFB02A76),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Xác nhận',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // ── Keypad rows ───────────────────────────────────────
                  for (final row in [
                    ['1', '2', '3'],
                    ['4', '5', '6'],
                    ['7', '8', '9'],
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: row.map(_buildKeypadButton).toList(),
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(width: 64),
                      _buildKeypadButton('0'),
                      _buildBackspaceButton(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
