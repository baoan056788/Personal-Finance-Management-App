import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsignin;

import 'firebase_options.dart';
import 'models/app_config_model.dart';
import 'services/app_config_service.dart';
import 'views/auth/screens/login_screen.dart';
import 'views/home/home_view.dart';
import 'services/admin_access_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('vi_VN', null);

  await gsignin.GoogleSignIn.instance.initialize(
    serverClientId:
        '1047440854342-pc7k3vq881ce48i97l8up5b6oup4st8e.apps.googleusercontent.com',
  );

  final prefs = await SharedPreferences.getInstance();
  final rememberMe = prefs.getBool('remember_me') ?? true;

  if (!rememberMe) {
    await FirebaseAuth.instance.signOut();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppConfigModel>(
      stream: AppConfigService().watchConfig(),
      builder: (context, snapshot) {
        final config = snapshot.data ?? const AppConfigModel();
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: config.appName,
          theme: ThemeData(
            useMaterial3: false,
            fontFamily: 'Roboto',
            scaffoldBackgroundColor: const Color(0xFFFFF7FF),
          ),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('vi', 'VN'), Locale('en', 'US')],
          locale: const Locale('vi', 'VN'),
          home: const AuthWrapper(),
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          if (user == null) {
            return const LoginScreen();
          }
          return AccountGate(key: ValueKey(user.uid));
        }
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFFB02A76)),
          ),
        );
      },
    );
  }
}

class AccountGate extends StatefulWidget {
  const AccountGate({super.key});

  @override
  State<AccountGate> createState() => _AccountGateState();
}

class _AccountGateState extends State<AccountGate> {
  final AdminAccessService _accessService = AdminAccessService();
  Object? _setupError;
  bool _isReady = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _ensureProfile();
  }

  Future<void> _ensureProfile() async {
    try {
      await _accessService.ensureCurrentUserProfile();
      final isAdmin = await _accessService.isCurrentUserAdmin(
        forceRefresh: true,
      );
      if (mounted) {
        setState(() {
          _setupError = null;
          _isReady = true;
          _isAdmin = isAdmin;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _setupError = error;
          _isReady = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_setupError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 52, color: Colors.redAccent),
                const SizedBox(height: 16),
                const Text(
                  'Không thể chuẩn bị hồ sơ người dùng.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_setupError',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _ensureProfile,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isReady) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFB02A76)),
        ),
      );
    }
    return StreamBuilder<AppConfigModel>(
      stream: AppConfigService().watchConfig(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFB02A76)),
            ),
          );
        }
        final config = snapshot.data!;
        if (config.maintenanceMode && !_isAdmin) {
          return MaintenanceScreen(config: config);
        }
        return HomeView(isAdmin: _isAdmin);
      },
    );
  }
}

class MaintenanceScreen extends StatelessWidget {
  final AppConfigModel config;

  const MaintenanceScreen({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.construction_outlined,
                  size: 72,
                  color: Color(0xFFB02A76),
                ),
                const SizedBox(height: 20),
                Text(
                  '${config.appName} đang bảo trì',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Hệ thống đang được cập nhật. Vui lòng quay lại sau.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, height: 1.5),
                ),
                const SizedBox(height: 20),
                Text(
                  '${config.supportEmail}\n${config.supportPhone}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF4F6BED), height: 1.6),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: FirebaseAuth.instance.signOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Đăng xuất'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
