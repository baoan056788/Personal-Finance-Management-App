import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../controllers/goal_controller.dart';
import '../../../models/goal_contribution_model.dart';
import '../../../models/goal_model.dart';
import '../../../models/wallet_model.dart';
import '../../../utils/currency_input_formatter.dart';
import '../../../utils/finance_error_message.dart';
import '../../../utils/goal_money_validator.dart';
import '../../../widgets/finance_status_dialog.dart';
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
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  void _showContributionDialog(
    GoalModel goal,
    Color color, {
    required bool isWithdrawal,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _AddContributionForm(
          goalId: goal.id,
          goalController: _goalController,
          walletService: _walletService,
          mainColor: color,
          isWithdrawal: isWithdrawal,
          availableAmount: isWithdrawal
              ? goal.currentAmount
              : goal.remainAmount,
        ),
      ),
    );
  }

  Future<void> _deleteGoal(GoalModel goal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Xóa mục tiêu',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          goal.currentAmount > 0
              ? 'Mục tiêu vẫn còn tiền. Hãy rút toàn bộ số tiền về ví trước khi xóa.'
              : 'Mục tiêu và lịch sử nạp/rút liên quan sẽ bị xóa vĩnh viễn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: goal.currentAmount > 0
                ? null
                : () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _goalController.deleteGoal(goal.id);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể xóa mục tiêu: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<GoalModel>>(
      stream: _goalController.getGoals(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final goals = snapshot.data ?? const <GoalModel>[];
        final index = goals.indexWhere((goal) => goal.id == widget.goal.id);
        if (index == -1 && snapshot.hasData) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.pop(context);
          });
          return const Scaffold();
        }

        final goal = index >= 0 ? goals[index] : widget.goal;
        final color = _goalColor(goal);
        return _buildScaffold(goal, color);
      },
    );
  }

  Widget _buildScaffold(GoalModel goal, Color color) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(
      goal.targetDate.year,
      goal.targetDate.month,
      goal.targetDate.day,
    );
    final dayDifference = targetDate.difference(today).inDays;
    final remainingDays = dayDifference >= 0
        ? dayDifference + 1
        : dayDifference;
    final completed = goal.currentAmount >= goal.targetAmount;
    final exceededAmount = completed
        ? (goal.currentAmount - goal.targetAmount).clamp(0.0, double.infinity)
        : 0.0;
    final expired = !completed && dayDifference < 0;
    final visualProgress = goal.progressPercent.clamp(0.0, 1.0);
    final remainingAmount = (goal.targetAmount - goal.currentAmount).clamp(
      0.0,
      double.infinity,
    );
    final dailyAmount = remainingDays > 0 && remainingAmount > 0
        ? remainingAmount / remainingDays
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8FC),
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.black87,
        iconTheme: const IconThemeData(color: Colors.black87),
        actionsIconTheme: const IconThemeData(color: Colors.black87),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: Text(
          goal.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Chỉnh sửa',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreateGoalScreen(editGoal: goal),
              ),
            ),
            icon: const Icon(Icons.edit_outlined, color: Colors.black87),
          ),
          IconButton(
            tooltip: 'Xóa',
            onPressed: () => _deleteGoal(goal),
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
        children: [
          _buildHeroCard(
            goal: goal,
            color: color,
            completed: completed,
            expired: expired,
            exceededAmount: exceededAmount,
            visualProgress: visualProgress,
          ),
          const SizedBox(height: 16),
          _buildPlanCard(
            goal: goal,
            color: color,
            completed: completed,
            expired: expired,
            exceededAmount: exceededAmount,
            remainingAmount: remainingAmount,
            remainingDays: remainingDays,
            dailyAmount: dailyAmount,
          ),
          if (goal.note.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildNoteCard(goal.note, color),
          ],
          const SizedBox(height: 22),
          const Text(
            'Lịch sử tích lũy',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _buildContributionHistory(goal, color),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: goal.currentAmount <= 0
                    ? null
                    : () => _showContributionDialog(
                        goal,
                        color,
                        isWithdrawal: true,
                      ),
                icon: const Icon(Icons.south_west_rounded),
                label: const Text('Rút tiền'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: BorderSide(color: color),
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: goal.remainAmount <= 0
                    ? null
                    : () => _showContributionDialog(
                        goal,
                        color,
                        isWithdrawal: false,
                      ),
                icon: const Icon(Icons.savings_outlined),
                label: const Text('Nạp tiền'),
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard({
    required GoalModel goal,
    required Color color,
    required bool completed,
    required bool expired,
    required double exceededAmount,
    required double visualProgress,
  }) {
    final statusColor = completed
        ? const Color(0xFF159447)
        : expired
        ? const Color(0xFFD94343)
        : color;
    final statusTitle = completed
        ? 'Mục tiêu đã hoàn thành'
        : expired
        ? 'Mục tiêu đã quá hạn'
        : goal.status == 'NEAR_TARGET'
        ? 'Bạn sắp đạt mục tiêu'
        : 'Đang tiến tới mục tiêu';
    final statusDescription = completed
        ? exceededAmount > 0
              ? 'Tuyệt vời, bạn đã vượt mục tiêu ${_currencyFormat.format(exceededAmount)}.'
              : 'Tuyệt vời, bạn đã tích lũy đủ số tiền đặt ra.'
        : expired
        ? 'Bạn còn thiếu ${_currencyFormat.format(goal.remainAmount)} khi thời hạn đã kết thúc.'
        : 'Đã tích lũy ${_currencyFormat.format(goal.currentAmount)} trên ${_currencyFormat.format(goal.targetAmount)}.';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor,
            Color.lerp(statusColor, const Color(0xFFE91E63), 0.42)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.25),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  completed ? Icons.emoji_events_rounded : _goalIcon(goal),
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      goal.name,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Text(
            completed && exceededAmount > 0
                ? 'Tổng đã tích lũy'
                : 'Tiến độ hiện tại',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _currencyFormat.format(goal.currentAmount),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: visualProgress,
              minHeight: 12,
              backgroundColor: Colors.white.withValues(alpha: 0.22),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            completed
                ? 'Đã đạt 100% mục tiêu'
                : 'Đã hoàn thành ${(goal.progressPercent * 100).clamp(0, 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              statusDescription,
              style: const TextStyle(color: Colors.white, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required GoalModel goal,
    required Color color,
    required bool completed,
    required bool expired,
    required double exceededAmount,
    required double remainingAmount,
    required int remainingDays,
    required double dailyAmount,
  }) {
    return _buildCard(
      title: 'Kế hoạch mục tiêu',
      icon: Icons.track_changes_rounded,
      color: color,
      children: [
        _buildStatRow(
          label: 'Số tiền mục tiêu',
          value: _currencyFormat.format(goal.targetAmount),
          icon: Icons.flag_outlined,
          color: color,
        ),
        const Divider(height: 28),
        _buildStatRow(
          label: completed ? 'Vượt mục tiêu' : 'Còn cần tích lũy',
          value: _currencyFormat.format(
            completed ? exceededAmount : remainingAmount,
          ),
          icon: completed
              ? Icons.workspace_premium_outlined
              : Icons.savings_outlined,
          color: completed ? const Color(0xFF159447) : Colors.orange,
        ),
        const Divider(height: 28),
        _buildStatRow(
          label: 'Thời hạn',
          value: completed
              ? 'Đã hoàn thành'
              : expired
              ? 'Đã quá hạn'
              : 'Còn $remainingDays ngày',
          icon: completed
              ? Icons.check_circle_outline_rounded
              : Icons.calendar_month_outlined,
          color: completed
              ? const Color(0xFF159447)
              : expired
              ? Colors.red
              : Colors.blue,
        ),
        if (dailyAmount > 0) ...[
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Gợi ý: tích lũy khoảng ${_currencyFormat.format(dailyAmount)} mỗi ngày để kịp thời hạn.',
              style: TextStyle(color: color, height: 1.4),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNoteCard(String note, Color color) {
    return _buildCard(
      title: 'Ghi chú',
      icon: Icons.notes_rounded,
      color: color,
      children: [
        Text(note, style: TextStyle(color: Colors.grey.shade700, height: 1.5)),
      ],
    );
  }

  Widget _buildContributionHistory(GoalModel goal, Color color) {
    return StreamBuilder<List<GoalContributionModel>>(
      stream: _goalController.getContributions(goal.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final contributions = snapshot.data ?? const <GoalContributionModel>[];
        if (contributions.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                Icon(Icons.history_rounded, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 10),
                const Text(
                  'Chưa có lần nạp hoặc rút tiền nào',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: contributions.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final contribution = contributions[index];
              final isWithdrawal = contribution.isWithdrawal;
              final amount = contribution.amount.abs();
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 7),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isWithdrawal ? Colors.orange : color).withValues(
                      alpha: 0.1,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isWithdrawal
                        ? Icons.south_west_rounded
                        : Icons.north_east_rounded,
                    color: isWithdrawal ? Colors.orange : color,
                  ),
                ),
                title: Text(
                  '${isWithdrawal ? '-' : '+'}${_currencyFormat.format(amount)}',
                  style: TextStyle(
                    color: isWithdrawal
                        ? Colors.orange
                        : const Color(0xFF159447),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Text(
                  contribution.note.isEmpty
                      ? DateFormat(
                          'dd/MM/yyyy HH:mm',
                        ).format(contribution.createdAt)
                      : '${contribution.note} • ${DateFormat('dd/MM/yyyy HH:mm').format(contribution.createdAt)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 21),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(label, style: TextStyle(color: Colors.grey.shade700)),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Color _goalColor(GoalModel goal) {
    try {
      return Color(int.parse(goal.colorHex.replaceFirst('#', ''), radix: 16));
    } catch (_) {
      return const Color(0xFFE91E63);
    }
  }

  IconData _goalIcon(GoalModel goal) {
    try {
      return IconData(
        int.parse(goal.iconCode, radix: 16),
        fontFamily: 'MaterialIcons',
      );
    } catch (_) {
      return Icons.savings_rounded;
    }
  }
}

class _AddContributionForm extends StatefulWidget {
  final String goalId;
  final GoalController goalController;
  final WalletService walletService;
  final Color mainColor;
  final bool isWithdrawal;
  final double availableAmount;

  const _AddContributionForm({
    required this.goalId,
    required this.goalController,
    required this.walletService,
    required this.mainColor,
    required this.isWithdrawal,
    required this.availableAmount,
  });

  @override
  State<_AddContributionForm> createState() => _AddContributionFormState();
}

class _AddContributionFormState extends State<_AddContributionForm> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String? _selectedWalletId;
  WalletModel? _selectedWallet;
  bool _isLoading = false;

  String _formatMoney(double amount) {
    return NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    ).format(amount);
  }

  Future<bool> _validateAmount(double amount) async {
    final violation = validateGoalMoney(
      amount: amount,
      availableGoalAmount: widget.availableAmount,
      isWithdrawal: widget.isWithdrawal,
      walletBalance: _selectedWallet?.balance,
    );
    if (violation == null) return true;

    final (title, message) = switch (violation) {
      GoalMoneyViolation.invalidAmount => (
        'Số tiền chưa hợp lệ',
        'Vui lòng nhập số tiền lớn hơn 0.',
      ),
      GoalMoneyViolation.exceedsGoalAmount => (
        widget.isWithdrawal ? 'Số tiền rút quá lớn' : 'Số tiền nạp quá lớn',
        widget.isWithdrawal
            ? 'Mục tiêu hiện chỉ có ${_formatMoney(widget.availableAmount)}, nhưng bạn đang muốn rút ${_formatMoney(amount)}.'
            : 'Mục tiêu chỉ còn thiếu ${_formatMoney(widget.availableAmount)}, nhưng bạn đang muốn nạp ${_formatMoney(amount)}.',
      ),
      GoalMoneyViolation.insufficientWalletBalance => (
        'Số dư ví không đủ',
        'Ví ${_selectedWallet?.name ?? ''} hiện có ${_formatMoney(_selectedWallet?.balance ?? 0)}, không đủ để nạp ${_formatMoney(amount)}.',
      ),
    };
    await showFinanceStatusDialog(
      context,
      success: false,
      title: title,
      message: message,
      buttonText: 'Nhập lại',
    );
    return false;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedWalletId == null) {
      await showFinanceStatusDialog(
        context,
        success: false,
        title: 'Chưa chọn ví',
        message: widget.isWithdrawal
            ? 'Vui lòng chọn ví sẽ nhận tiền từ mục tiêu.'
            : 'Vui lòng chọn ví dùng để nạp tiền vào mục tiêu.',
      );
      return;
    }
    final amountText = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(amountText);
    if (amount == null || !await _validateAmount(amount)) return;

    setState(() => _isLoading = true);
    try {
      if (widget.isWithdrawal) {
        await widget.goalController.withdrawContribution(
          goalId: widget.goalId,
          walletId: _selectedWalletId!,
          amount: amount,
          note: _noteController.text.trim(),
        );
      } else {
        await widget.goalController.addContribution(
          goalId: widget.goalId,
          walletId: _selectedWalletId!,
          amount: amount,
          note: _noteController.text.trim(),
        );
      }
      if (!mounted) return;
      await showFinanceStatusDialog(
        context,
        success: true,
        title: widget.isWithdrawal
            ? 'Rút tiền thành công'
            : 'Nạp tiền thành công',
        message: widget.isWithdrawal
            ? 'Số tiền đã được hoàn về ví, ghi nhận là khoản thu và cập nhật tiến độ mục tiêu.'
            : 'Số tiền đã được trừ khỏi ví, ghi nhận là khoản chi Tiết Kiệm và cập nhật tiến độ.',
        buttonText: 'Hoàn tất',
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      await showFinanceStatusDialog(
        context,
        success: false,
        title: widget.isWithdrawal ? 'Chưa thể rút tiền' : 'Chưa thể nạp tiền',
        message: financeErrorMessage(error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Icon(
                  widget.isWithdrawal
                      ? Icons.south_west_rounded
                      : Icons.savings_rounded,
                  color: widget.mainColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  widget.isWithdrawal
                      ? 'Rút tiền từ mục tiêu'
                      : 'Nạp tiền vào mục tiêu',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: widget.mainColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '${widget.isWithdrawal ? 'Có thể rút' : 'Còn cần'}: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(widget.availableAmount)}',
                style: TextStyle(
                  color: widget.mainColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<WalletModel>>(
              stream: widget.walletService.getWallets(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final wallets = snapshot.data!;
                return DropdownButtonFormField<String>(
                  initialValue: _selectedWalletId,
                  isExpanded: true,
                  decoration: _inputDecoration(
                    widget.isWithdrawal ? 'Ví nhận tiền' : 'Ví nguồn',
                    Icons.account_balance_wallet_outlined,
                  ),
                  items: wallets.map((wallet) {
                    return DropdownMenuItem(
                      value: wallet.id,
                      child: Text(
                        '${wallet.name} (${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(wallet.balance)})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedWalletId = value;
                      _selectedWallet = wallets
                          .where((wallet) => wallet.id == value)
                          .firstOrNull;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: widget.mainColor,
              ),
              decoration: _inputDecoration('Số tiền', Icons.payments_outlined),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDecoration('Ghi chú', Icons.notes_rounded),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: widget.mainColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.add_rounded),
                label: Text(
                  _isLoading
                      ? 'Đang xử lý...'
                      : widget.isWithdrawal
                      ? 'Xác nhận rút'
                      : 'Xác nhận nạp',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: widget.mainColor),
      filled: true,
      fillColor: const Color(0xFFF8F8FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: widget.mainColor),
      ),
    );
  }
}
