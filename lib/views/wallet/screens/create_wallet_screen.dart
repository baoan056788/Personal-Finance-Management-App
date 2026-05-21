import 'package:flutter/material.dart';
import 'enter_balance_screen.dart';
import '../../home/home_view.dart';

class CreateWalletScreen extends StatelessWidget {
  const CreateWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFB02A76)),
          onPressed: () {
            if (Navigator.canPop(context)) Navigator.pop(context);
          },
        ),
        title: const Text('Thiết lập ví', style: TextStyle(color: Color(0xFFB02A76), fontSize: 18, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined, color: Color(0xFFB02A76)),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeView()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, height: 1.2),
                  children: [
                    TextSpan(text: 'Thiết lập\n', style: TextStyle(color: Colors.black87)),
                    TextSpan(text: 'ví của bạn', style: TextStyle(color: Color(0xFFB02A76))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Hệ thống sẽ tạo một ví mặc định để bạn\nbắt đầu quản lý tài chính.',
                style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
              ),
              const SizedBox(height: 48),
              
              // Wallet Preview Card
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFFEBE4E8), // Light grayish-pink
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Stack(
                  children: [
                    // Bottom right circle decor
                    Positioned(
                      right: -30,
                      bottom: -30,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCC8D6).withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.account_balance_wallet, color: Color(0xFFB02A76), size: 28),
                              ),
                              const Text(
                                'DEFAULT WALLET',
                                style: TextStyle(color: Color(0xFFB02A76), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Text(
                            'Ví tiền mặt',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black87),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD6A5C0),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Active Account',
                                style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Info Box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.black54, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Bạn có thể thay đổi hoặc thêm ví khác\nsau khi hoàn tất thiết lập ban đầu.',
                        style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EnterBalanceScreen(
                        name: 'Ví tiền mặt',
                        type: 'Cash',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB02A76),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Tiếp tục', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
