import 'package:flutter/material.dart';
import '../../../models/app_nav_item.dart';


class BottomNavWidget extends StatelessWidget {
  final int currentIndex;
  final List<AppNavItem> items;
  final ValueChanged<int> onTap;

  const BottomNavWidget({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: Colors.pink,
      unselectedItemColor: Colors.grey,
      currentIndex: currentIndex,
      onTap: onTap,
      selectedLabelStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 13,
      ),
      items: items.map((item) {
        return BottomNavigationBarItem(
          icon: Icon(item.icon),
          activeIcon: Icon(item.activeIcon),
          label: item.label,
        );
      }).toList(),
    );
  }
}