import 'package:flutter/material.dart';
import '../../wallet/screens/wallet_list_screen.dart';

class QuickActionsWidget extends StatelessWidget {
  const QuickActionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          ActionItem(
            icon: Icons.add_circle_outline,
            text: 'Nhập',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WalletListScreen()),
              );
            },
          ),
          ActionItem(
            icon: Icons.bar_chart,
            text: 'Biến động',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Chuyển tới tab Báo cáo để xem biến động'),
                  backgroundColor: Colors.teal,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
          ),
          ActionItem(
            icon: Icons.label_outline,
            text: 'Phân loại',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Tính năng phân loại sẽ sớm được cập nhật'),
                  backgroundColor: Colors.teal,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
          ),
          ActionItem(
            icon: Icons.apps,
            text: 'Tiện ích',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Mở tab Tiện ích ở thanh điều hướng bên dưới'),
                  backgroundColor: Colors.teal,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ActionItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const ActionItem({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFE0F2F1),
              child: Icon(
                icon,
                color: Colors.teal,
                size: 26,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF444444),
              ),
            ),
          ],
        ),
      ),
    );
  }
}