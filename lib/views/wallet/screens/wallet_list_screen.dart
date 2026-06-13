import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../models/wallet_model.dart';
import '../services/wallet_service.dart';
import 'add_wallet_screen.dart';
import 'transfer_money_screen.dart';
import 'wallet_detail_screen.dart';

class WalletListScreen extends StatefulWidget {
  const WalletListScreen({super.key});

  @override
  State<WalletListScreen> createState() => _WalletListScreenState();
}

class _WalletListScreenState extends State<WalletListScreen> {
  final WalletService _walletService = WalletService();
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ₫';
  }

  void _showEditWalletDialog(WalletModel wallet) {
    final TextEditingController nameController = TextEditingController(text: wallet.name);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Đổi tên ví'),
          content: TextField(
            controller: nameController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Tên ví'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tên ví không được để trống'), backgroundColor: Colors.redAccent));
                  return;
                }
                if (newName.length > 30) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tên ví tối đa 30 ký tự'), backgroundColor: Colors.redAccent));
                  return;
                }
                if (newName != wallet.name) {
                  await _walletService.updateWalletName(wallet.id, newName);
                }
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Lưu', style: TextStyle(color: Color(0xFFB02A76))),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteWallet(WalletModel wallet) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xóa ví?'),
          content: Text('Bạn có chắc chắn muốn xóa ví "${wallet.name}" không? Toàn bộ giao dịch trong ví này cũng sẽ bị xóa.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                await _walletService.deleteWallet(wallet.id);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Xóa', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const Center(child: Text('Vui lòng đăng nhập'));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FF),
      body: StreamBuilder<List<WalletModel>>(
        stream: _walletService.getWallets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFB02A76)),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final wallets = snapshot.data ?? [];

          if (wallets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_balance_wallet_outlined, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Bạn chưa có ví nào', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AddWalletScreen()));
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm ví mới'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB02A76),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  )
                ],
              ),
            );
          }

          final totalBalance = wallets.fold(0.0, (sum, wallet) => sum + wallet.balance);

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            const Text(
                              'Tổng số dư',
                              style: TextStyle(color: Colors.black54, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatCurrency(totalBalance),
                              style: const TextStyle(
                                color: Color(0xFFB02A76),
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 18),
                            FilledButton.icon(
                              onPressed: wallets.length < 2
                                  ? null
                                  : () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const TransferMoneyScreen(),
                                      ),
                                    ),
                              icon: const Icon(Icons.swap_horiz),
                              label: Text(
                                wallets.length < 2
                                    ? 'Cần ít nhất 2 ví'
                                    : 'Chuyển tiền giữa các ví',
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFB02A76),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: wallets.length,
                  itemBuilder: (context, index) {
                    final wallet = wallets[index];

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WalletDetailScreen(wallet: wallet),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.only(left: 20, right: 8, top: 16, bottom: 20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFB02A76), Color(0xFFE56A9D)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Tên ví',
                                          style: TextStyle(color: Colors.white70, fontSize: 14),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          wallet.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, color: Colors.white),
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showEditWalletDialog(wallet);
                                      } else if (value == 'delete') {
                                        _confirmDeleteWallet(wallet);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, color: Colors.black54, size: 20),
                                            SizedBox(width: 8),
                                            Text('Đổi tên ví'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                            SizedBox(width: 8),
                                            Text('Xóa ví', style: TextStyle(color: Colors.redAccent)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      wallet.type,
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        'Số dư',
                                        style: TextStyle(color: Colors.white70, fontSize: 14),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatCurrency(wallet.balance),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddWalletScreen()));
        },
        backgroundColor: const Color(0xFFB02A76),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm ví', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
