import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'views/auth/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Always sign out on every cold start.
  // The phone number input screen is the single, unconditional entry point.
  // Routing to HomeView only happens AFTER the user successfully authenticates
  // through the phone → OTP/Password → onboarding flow during THIS session.
  await FirebaseAuth.instance.signOut();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tinora',
      theme: ThemeData(
        useMaterial3: false,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFFFF7FF),
      ),
      // LoginScreen is always the first screen — no session restore, no auto-login.
      home: const LoginScreen(),
    );
  }
}
