import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/goal_model.dart';
import '../../../models/goal_contribution_model.dart';
import '../../../models/wallet_model.dart';
import '../../../controllers/goal_controller.dart';
import '../../wallet/services/wallet_service.dart';
import 'create_goal_screen.dart';

class GoalDetailScreen extends StatefulWidget {
  final GoalModel goal;
  const GoalDetailScreen({super.key, required this.goal});

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  final GoalController _goalController = GoalController();
  final WalletService _walletService = WalletService();
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  void _showAddContributionDialog(Color color) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: _AddContributionForm(
            goalId: widget.goal.id,
            goalController: _goalController,
            walletService: _walletService,
            mainColor: color,
          ),
        );
      },
    );
  }

  void _deleteGoal() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xóa Mục Tiêu', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc chắn muốn xóa mục tiêu này? Lưu ý: Tiền đã nạp (nếu có) sẽ không được hoàn tự động vào ví.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _goalController.deleteGoal(widget.goal.id);
        if (!mounted) return;
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<GoalModel>>(
      stream: _goalController.getGoals(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        final goals = snapshot.data ?? [];
        final currentGoalIndex = goals.indexWhere((g) => g.id == widget.goal.id);
        
        if (currentGoalIndex == -1 && snapshot.hasData) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.of(context).pop();
          });
          return const Scaffold();
        }

        final goal = currentGoalIndex != -1 ? goals[currentGoalIndex] : widget.goal;
        final color = Color(int.parse(goal.colorHex, radix: 16));
        final remainingDays = goal.targetDate.difference(DateTime.now()).inDays;
        
        double avgNeeded = 0;
        if (remainingDays > 0 && goal.remainAmount > 0) {
          avgNeeded = goal.remainAmount / remainingDays;
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 380,
                pinned: true,
                backgroundColor: color,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateGoalScreen(editGoal: goal))),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: _deleteGoal,
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withAlpha(200)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          // Premium Circular Progress
                          SizedBox(
                            width: 180,
                            height: 180,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CircularProgressIndicator(
                                  value: goal.progressPercent.clamp(0.0, 1.0),
                                  backgroundColor: Colors.white.withAlpha(50),
                                  color: Colors.white,
                                  strokeWidth: 12,
                                  strokeCap: StrokeCap.round,
                                ),
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(color: Colors.white.withAlpha(50), shape: BoxShape.circle),
                                        child: Icon(IconData(int.parse(goal.iconCode, radix: 16), fontFamily: 'MaterialIcons'), size: 28, color: Colors.white),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${(goal.progressPercent * 100).toStringAsFixed(1)}%',
                                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(goal.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                          if (goal.note.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: Text(goal.note, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -20),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats Panel
                        Container(
                          margin: const EdgeInsets.all(20),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 20, offset: const Offset(0, 10))],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(child: _buildStatItem('Đã tiết kiệm', _currencyFormat.format(goal.currentAmount), color)),
                                  Container(width: 1, height: 40, color: Colors.grey[200]),
                                  Expanded(child: _buildStatItem('Mục tiêu', _currencyFormat.format(goal.targetAmount), Colors.black87)),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Divider(height: 1),
                              ),
                              Row(
                                children: [
                                  Expanded(child: _buildStatItem('Còn lại', _currencyFormat.format(goal.remainAmount), Colors.orange)),
                                  Container(width: 1, height: 40, color: Colors.grey[200]),
                                  Expanded(
                                    child: _buildStatItem(
                                      'Thời gian', 
                                      remainingDays > 0 ? '$remainingDays ngày' : (remainingDays == 0 ? 'Hôm nay' : 'Quá hạn'), 
                                      remainingDays < 0 ? Colors.red : Colors.black87
                                    )
                                  ),
                                ],
                              ),
                              if (avgNeeded > 0) ...[
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Divider(height: 1),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.lightbulb_outline, color: Colors.orange, size: 20),
                                    const SizedBox(width: 8),
                                    Text('Cần tiết kiệm ${_currencyFormat.format(avgNeeded)}/ngày', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ]
                            ],
                          ),
                        ),

                        // History
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          child: Text('Lịch sử nạp', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                        ),
                        
                        StreamBuilder<List<GoalContributionModel>>(
                          stream: _goalController.getContributions(goal.id),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                            }
                            final contributions = snapshot.data ?? [];
                            if (contributions.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    children: [
                                      Icon(Icons.history_rounded, size: 64, color: Colors.grey[300]),
                                      const SizedBox(height: 16),
                                      const Text('Chưa có giao dịch nạp tiền nào', style: TextStyle(color: Colors.grey, fontSize: 16)),
                                    ],
                                  ),
                                ),
                              );
                            }
                            
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              itemCount: contributions.length,
                              itemBuilder: (context, index) {
                                final c = contributions[index];
                                bool isLast = index == contributions.length - 1;
                                return _buildTimelineItem(c, color, isLast);
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: color,
            elevation: 4,
            onPressed: () => _showAddContributionDialog(color),
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text('Nạp Tiền', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        );
      }
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valueColor, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTimelineItem(GoalContributionModel contribution, Color color, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 16, height: 16,
              decoration: BoxDecoration(
                color: color.withAlpha(50),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 4),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 50,
                color: Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(contribution.createdAt),
                      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      '+${_currencyFormat.format(contribution.amount)}',
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                if (contribution.note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(contribution.note, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ]
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AddContributionForm extends StatefulWidget {
  final String goalId;
  final GoalController goalController;
  final WalletService walletService;
  final Color mainColor;

  const _AddContributionForm({required this.goalId, required this.goalController, required this.walletService, required this.mainColor});

  @override
  State<_AddContributionForm> createState() => _AddContributionFormState();
}

class _AddContributionFormState extends State<_AddContributionForm> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _selectedWalletId;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_selectedWalletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn ví nguồn')));
      return;
    }
    final amountStr = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (amountStr.isEmpty || double.parse(amountStr) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Số tiền không hợp lệ')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.goalController.addContribution(
        goalId: widget.goalId,
        walletId: _selectedWalletId!,
        amount: double.parse(amountStr),
        note: _noteController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context); // Close sheet
      
      // Success snackbar
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text('Nạp tiền thành công!'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(Icons.savings_rounded, color: widget.mainColor, size: 28),
                const SizedBox(width: 12),
                const Text('Nạp tiền vào mục tiêu', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: StreamBuilder<List<WalletModel>>(
              stream: widget.walletService.getWallets(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final wallets = snapshot.data!;
                if (wallets.isEmpty) return const Text('Bạn chưa có ví nào!');
                
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text('Chọn ví nguồn'),
                      value: _selectedWalletId,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      items: wallets.map((w) => DropdownMenuItem(
                        value: w.id,
                        child: Text('${w.name} (${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(w.balance)})', style: const TextStyle(fontWeight: FontWeight.w500)),
                      )).toList(),
                      onChanged: (val) => setState(() => _selectedWalletId = val),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: widget.mainColor),
              onChanged: (value) {
                String clean = value.replaceAll(RegExp(r'[^0-9]'), '');
                if (clean.isNotEmpty) {
                  String formatted = NumberFormat.decimalPattern('vi_VN').format(int.parse(clean));
                  _amountController.value = TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(offset: formatted.length),
                  );
                }
              },
              decoration: InputDecoration(
                labelText: 'Số tiền',
                prefixIcon: Icon(Icons.attach_money_rounded, color: widget.mainColor),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: widget.mainColor)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextFormField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Ghi chú',
                prefixIcon: const Icon(Icons.edit_note_rounded),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.mainColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Xác nhận nạp', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
