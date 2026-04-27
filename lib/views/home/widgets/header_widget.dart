import 'package:flutter/material.dart';

class AppHeaderWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showNotification;
  final VoidCallback? onNotificationPressed;

  const AppHeaderWidget({
    super.key,
    required this.title,
    this.showNotification = false,
    this.onNotificationPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.pink[100],
      elevation: 0,
      titleSpacing: 20,
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF333333),
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        if (showNotification)
          IconButton(
            onPressed: onNotificationPressed,
            icon: const Icon(
              Icons.notifications,
              color: Color(0xFF444444),
            ),
          ),
        const SizedBox(width: 10),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}