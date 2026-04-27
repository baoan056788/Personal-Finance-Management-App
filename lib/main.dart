import 'package:flutter/material.dart';
import 'views/home/home_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quản lý chi tiêu',
      theme: ThemeData(
        useMaterial3: false,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFFFF7FF),
      ),
      home: const HomeView(),
    );
  }
}