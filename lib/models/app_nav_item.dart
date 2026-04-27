import 'package:flutter/material.dart';

class AppNavItem {
  final String label;
  final String title;
  final IconData icon;
  final IconData activeIcon;
  final Widget screen;
  final bool showNotification;

  const AppNavItem({
    required this.label,
    required this.title,
    required this.icon,
    required this.activeIcon,
    required this.screen,
    this.showNotification = false,
  });
}