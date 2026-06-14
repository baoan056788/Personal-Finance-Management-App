import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/goal_model.dart';
import '../../../controllers/goal_controller.dart';
import 'create_goal_screen.dart';
import 'goal_detail_screen.dart';

class GoalListScreen extends StatefulWidget {
  const GoalListScreen({super.key});

  @override
  State<GoalListScreen> createState() => _GoalListScreenState();
}

class _GoalListScreenState extends State<GoalListScreen> {
  final GoalController _goalController = GoalController();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
  );
  bool _isExpanded = false;
  bool _isFabPressed = false;

  Color _getStatusColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return const Color(0xFF4CAF50); // Green
      case 'FAILED':
        return const Color(0xFFF44336); // Red
      case 'NEAR_TARGET':
        return const Color(0xFFFF9800); // Orange
      case 'ON_GOING':
      default:
        return const Color(0xFF2196F3); // Blue
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'COMPLETED':
        return 'Hoàn thành';
      case 'FAILED':
        return 'Thất bại';
      case 'NEAR_TARGET':
        return 'Sắp đạt';
      case 'ON_GOING':
      default:
        return 'Đang thực hiện';
    }
  }

  void _sortGoals(List<GoalModel> goals) {
    goals.sort((a, b) {
      // 1. Gần hoàn thành nhất
      if (a.progressPercent != b.progressPercent) {
        return b.progressPercent.compareTo(a.progressPercent);
      }
      // 2. Gần tới deadline
      if (a.targetDate != b.targetDate) {
        return a.targetDate.compareTo(b.targetDate);
      }
      // 3. Mới tạo
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Mục tiêu tiết kiệm',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: StreamBuilder<List<GoalModel>>(
        stream: _goalController.getGoals(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Đã xảy ra lỗi khi tải dữ liệu.'));
          }

          final goals = snapshot.data ?? [];

          if (goals.isEmpty) {
            return _buildEmptyState();
          }

          _sortGoals(goals);

          double totalSaved = goals.fold(
            0,
            (sum, item) => sum + item.currentAmount,
          );
          double totalTarget = goals.fold(
            0,
            (sum, item) => sum + item.targetAmount,
          );
          double avgProgress = totalTarget > 0 ? totalSaved / totalTarget : 0;

          final displayGoals = _isExpanded
              ? goals.take(3).toList()
              : goals.take(1).toList();
          final hasMore = goals.length > 1;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderCard(totalSaved, goals.length, avgProgress),
                      const SizedBox(height: 24),
                      const Text(
                        'Danh sách mục tiêu',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: Column(
                          children: displayGoals
                              .map((goal) => _buildGoalCard(goal))
                              .toList(),
                        ),
                      ),
                      if (hasMore)
                        Center(
                          child: TextButton.icon(
                            onPressed: () =>
                                setState(() => _isExpanded = !_isExpanded),
                            icon: Icon(
                              _isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: const Color(0xFFC2185B),
                            ),
                            label: Text(
                              _isExpanded ? 'Thu gọn' : 'Xem thêm mục tiêu',
                              style: const TextStyle(
                                color: Color(0xFFC2185B),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              backgroundColor: const Color(
                                0xFFC2185B,
                              ).withAlpha(15),
                            ),
                          ),
                        ),
                      const SizedBox(height: 80), // FAB spacer
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF80AB), Color(0xFFC2185B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFC2185B).withAlpha(50),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(Icons.stars, size: 80, color: Colors.white),
          ),
          const SizedBox(height: 24),
          const Text(
            'Chưa có mục tiêu nào',
            style: TextStyle(
              fontSize: 22,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Bắt đầu mục tiêu đầu tiên của bạn ngay hôm nay để xây dựng thói quen tiết kiệm!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateGoalScreen()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC2185B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              elevation: 4,
            ),
            child: const Text(
              'Tạo Mục Tiêu Ngay',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(
    double totalSaved,
    int totalGoals,
    double avgProgress,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE91E63), Color(0xFF880E4F)], // Magenta gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF880E4F).withAlpha(60),
            blurRadius: 20,
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(50),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.savings_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Tổng tiền đã tiết kiệm',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _currencyFormat.format(totalSaved),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Số mục tiêu',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalGoals',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.white.withAlpha(50),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Tiến độ trung bình',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(avgProgress * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tiếp tục phát huy nhé! 🚀',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(GoalModel goal) {
    Color mainColor = Color(int.parse(goal.colorHex, radix: 16));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(
      goal.targetDate.year,
      goal.targetDate.month,
      goal.targetDate.day,
    );
    int remainingDays = target.difference(today).inDays;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GoalDetailScreen(goal: goal)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: mainColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    IconData(
                      int.parse(goal.iconCode, radix: 16),
                      fontFamily: 'MaterialIcons',
                    ),
                    color: mainColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(goal.status).withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _getStatusText(goal.status),
                          style: TextStyle(
                            color: _getStatusColor(goal.status),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _currencyFormat.format(goal.currentAmount),
                  style: TextStyle(
                    color: mainColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _currencyFormat.format(goal.targetAmount),
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: goal.progressPercent.clamp(0.0, 1.0),
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(mainColor),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  goal.currentAmount >= goal.targetAmount
                      ? 'Đã hoàn thành'
                      : '${(goal.progressPercent * 100).clamp(0, 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      remainingDays >= 0
                          ? 'Còn ${remainingDays + 1} ngày'
                          : 'Quá hạn',
                      style: TextStyle(
                        color: remainingDays < 0 ? Colors.red : Colors.black54,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isFabPressed = true),
      onTapUp: (_) {
        setState(() => _isFabPressed = false);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateGoalScreen()),
        );
      },
      onTapCancel: () => setState(() => _isFabPressed = false),
      child: AnimatedScale(
        scale: _isFabPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE91E63), Color(0xFF880E4F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE91E63).withAlpha(80),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 32),
        ),
      ),
    );
  }
}
