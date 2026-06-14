import 'package:flutter/material.dart';

import 'enter_balance_screen.dart';

class CreateWalletScreen extends StatefulWidget {
  const CreateWalletScreen({super.key});

  @override
  State<CreateWalletScreen> createState() => _CreateWalletScreenState();
}

class _CreateWalletScreenState extends State<CreateWalletScreen> {
  static const Color _primaryPink = Color(0xFFB02A76);

  final TextEditingController _nameController = TextEditingController(
    text: 'Ví tiền mặt',
  );
  String _selectedType = 'Tiền mặt';

  static const List<({String type, IconData icon})> _walletTypes = [
    (type: 'Tiền mặt', icon: Icons.payments_rounded),
    (type: 'Ngân hàng', icon: Icons.account_balance_rounded),
    (type: 'Ví điện tử', icon: Icons.account_balance_wallet_rounded),
    (type: 'Thẻ tín dụng', icon: Icons.credit_card_rounded),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _selectType(String type) {
    setState(() {
      _selectedType = type;
      if (_nameController.text.trim().isEmpty ||
          _walletTypes.any(
            (option) =>
                _nameController.text.trim() == _defaultName(option.type),
          )) {
        _nameController.text = _defaultName(type);
      }
    });
  }

  String _defaultName(String type) {
    return switch (type) {
      'Ngân hàng' => 'Tài khoản ngân hàng',
      'Ví điện tử' => 'Ví điện tử',
      'Thẻ tín dụng' => 'Thẻ tín dụng',
      _ => 'Ví tiền mặt',
    };
  }

  IconData get _selectedIcon =>
      _walletTypes.firstWhere((option) => option.type == _selectedType).icon;

  void _continue() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên ví đầu tiên.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EnterBalanceScreen(name: name, type: _selectedType),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FF),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Thiết lập ví đầu tiên',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      _primaryPink,
                      Color(0xFFE0248A),
                      Color(0xFFF06292),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryPink.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(_selectedIcon, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bắt đầu quản lý tài chính',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tạo một ví để ghi nhận thu, chi và số dư của bạn.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Chọn loại ví',
                style: TextStyle(
                  color: Color(0xFF332B31),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.45,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _walletTypes.length,
                itemBuilder: (context, index) {
                  final option = _walletTypes[index];
                  final selected = option.type == _selectedType;
                  return InkWell(
                    onTap: () => _selectType(option.type),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFFFE4F1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? _primaryPink
                              : const Color(0xFFF0E7ED),
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            option.icon,
                            color: selected ? _primaryPink : Colors.black45,
                            size: 22,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              option.type,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: selected ? _primaryPink : Colors.black54,
                                fontSize: 13,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Tên ví',
                style: TextStyle(
                  color: Color(0xFF332B31),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _nameController,
                maxLength: 30,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Ví dụ: Tiền mặt, Vietcombank...',
                  prefixIcon: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: _primaryPink,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFF0E7ED)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: _primaryPink,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDF6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: _primaryPink, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Bạn có thể nhập số dư bằng 0đ và thêm các ví khác sau khi hoàn tất.',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _continue,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text(
                    'TIẾP TỤC NHẬP SỐ DƯ',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryPink,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
