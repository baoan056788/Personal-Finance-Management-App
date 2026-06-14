import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsignin;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/app_config_model.dart';
import '../../../services/app_config_service.dart';
import '../../../utils/auth_validation.dart';
import '../../../utils/input_constraints.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = true;
  AppConfigModel _appConfig = const AppConfigModel();
  StreamSubscription<AppConfigModel>? _configSubscription;

  @override
  void initState() {
    super.initState();
    _loadRememberMePreference();
    _configSubscription = AppConfigService().watchConfig().listen((config) {
      if (mounted) setState(() => _appConfig = config);
    });
  }

  Future<void> _loadRememberMePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('remember_me') ?? true;
    });
  }

  Future<void> _saveRememberMePreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', value);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _configSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loginEmail() async {
    FocusScope.of(context).unfocus();
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String email = _emailController.text.trim().toLowerCase();
    String password = _passwordController.text;

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _saveRememberMePreference(_rememberMe);

      // Routing to HomeView is handled by AuthWrapper in main.dart
    } on FirebaseAuthException catch (e) {
      String message = 'Đã xảy ra lỗi.';
      if (e.code == 'user-not-found') {
        message = 'Tài khoản không tồn tại.';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'Email hoặc mật khẩu không chính xác.';
      } else if (e.code == 'network-request-failed') {
        message = 'Không thể kết nối mạng.';
      } else if (e.code == 'too-many-requests') {
        message = 'Bạn đã thử quá nhiều lần. Vui lòng thử lại sau.';
      } else if (e.code == 'user-disabled') {
        message =
            'Tài khoản đã bị khóa. Vui lòng liên hệ quản trị viên để được hỗ trợ.';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xảy ra lỗi: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openForgotPassword() async {
    FocusScope.of(context).unfocus();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ForgotPasswordScreen(initialEmail: _emailController.text.trim()),
      ),
    );
  }

  Future<void> _loginGoogle() async {
    FocusScope.of(context).unfocus();
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final gsignin.GoogleSignInAccount googleUser = await gsignin
          .GoogleSignIn
          .instance
          .authenticate();

      final gsignin.GoogleSignInAuthentication googleAuth =
          googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final user = userCredential.user;

      if (user != null) {
        if (userCredential.additionalUserInfo?.isNewUser == true &&
            !_appConfig.registrationEnabled) {
          await user.delete();
          await FirebaseAuth.instance.signOut();
          throw Exception('Hệ thống đang tạm dừng đăng ký tài khoản mới.');
        }
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);
        final docSnapshot = await docRef.get();

        if (!docSnapshot.exists) {
          await docRef.set({
            'fullName': user.displayName ?? 'Người dùng',
            'email': user.email,
            'createdAt': FieldValue.serverTimestamp(),
            'lastLoginAt': FieldValue.serverTimestamp(),
            'onboardingCompleted': false,
            'loginProvider': 'google',
            'avatarUrl': user.photoURL,
            'role': 'user',
            'status': 'active',
          }, SetOptions(merge: true));
        } else {
          await docRef.set({
            'lastLoginAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }

      await _saveRememberMePreference(_rememberMe);
    } on FirebaseAuthException catch (e) {
      String message = 'Đăng nhập Google thất bại.';
      if (e.code == 'network-request-failed') {
        message = 'Không thể kết nối mạng.';
      } else if (e.code == 'user-disabled') {
        message =
            'Tài khoản đã bị khóa. Vui lòng liên hệ quản trị viên để được hỗ trợ.';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi đăng nhập Google: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading:
            false, // Ensure no back button on base login screen
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Chào mừng bạn',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                    color: Color(0xFFB02A76),
                  ),
                ),
                Text(
                  'đến với ${_appConfig.appName}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                    color: Color(0xFFB02A76),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Vui lòng đăng nhập để tiếp tục trải nghiệm.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),

                // Email Field
                CustomTextField(
                  label: 'Email',
                  hint: 'Nhập email',
                  controller: _emailController,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  maxLength: 100,
                  inputFormatters: emailInputFormatters(),
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: const [AutofillHints.email],
                  validator: (value) {
                    return validateEmailAddress(value);
                  },
                ),
                const SizedBox(height: 16),

                // Password Field
                CustomTextField(
                  label: 'Mật khẩu',
                  hint: 'Nhập mật khẩu',
                  controller: _passwordController,
                  prefixIcon: Icons.lock_outline,
                  isPassword: _obscurePassword,
                  maxLength: 32,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // Remember Me
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: _isLoading
                          ? null
                          : (value) {
                              setState(() {
                                _rememberMe = value ?? true;
                              });
                            },
                      activeColor: const Color(0xFFB02A76),
                    ),
                    const Text(
                      'Ghi nhớ đăng nhập',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _isLoading ? null : _openForgotPassword,
                      child: const Text(
                        'Quên mật khẩu?',
                        style: TextStyle(
                          color: Color(0xFFB02A76),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Login Button
                CustomButton(
                  text: 'ĐĂNG NHẬP',
                  onPressed: _isLoading ? () {} : _loginEmail,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 16),

                // Divider
                const Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'HOẶC',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 16),

                // Google Login Button
                OutlinedButton(
                  onPressed: _isLoading ? null : _loginGoogle,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    side: const BorderSide(color: Colors.grey, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Google Icon
                      Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png',
                        height: 24,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.g_mobiledata,
                              size: 32,
                              color: Colors.blue,
                            ),
                      ),
                      const SizedBox(width: 12),
                      const Flexible(
                        child: Text(
                          'Đăng nhập bằng Google',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Chưa có tài khoản? ',
                      style: TextStyle(color: Colors.black54),
                    ),
                    TextButton(
                      onPressed: _isLoading || !_appConfig.registrationEnabled
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                            },
                      child: const Text(
                        'Đăng ký ngay',
                        style: TextStyle(
                          color: Color(0xFFB02A76),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!_appConfig.registrationEnabled)
                  const Text(
                    'Hệ thống đang tạm dừng đăng ký tài khoản mới.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
