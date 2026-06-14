import 'package:flutter/material.dart';

class AppHeaderWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showNotification;
  final VoidCallback? onNotificationPressed;
  final int notificationCount;
  final bool isNotificationLoading;

  const AppHeaderWidget({
    super.key,
    required this.title,
    this.showNotification = false,
    this.onNotificationPressed,
    this.notificationCount = 0,
    this.isNotificationLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFFFF7FF),
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 20,
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF333333),
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      actions: [
        if (showNotification)
          IconButton(
            onPressed: onNotificationPressed,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  notificationCount > 0
                      ? Icons.notifications_rounded
                      : Icons.notifications_none_rounded,
                  color: const Color(0xFFE0248A),
                ),
                if (notificationCount > 0)
                  Positioned(
                    right: -7,
                    top: -7,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 18),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: const Color(0xFFFFF7FF)),
                      ),
                      child: Text(
                        notificationCount > 99 ? '99+' : '$notificationCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                if (isNotificationLoading)
                  const Positioned.fill(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFE0248A),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(width: 10),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
