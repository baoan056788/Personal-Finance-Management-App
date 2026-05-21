import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/goal_model.dart';
import '../../../controllers/goal_controller.dart';
import '../../goal/screens/goal_list_screen.dart';
import '../../goal/screens/goal_detail_screen.dart';

class GoalSummaryWidget extends StatefulWidget {
  const GoalSummaryWidget({super.key});

  @override
  State<GoalSummaryWidget> createState() => _GoalSummaryWidgetState();
}

class _GoalSummaryWidgetState extends State<GoalSummaryWidget> {
  final GoalController _goalController = GoalController();
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  bool _isExpanded = false;

  void _sortGoals(List<GoalModel> goals) {
    goals.sort((a, b) {
      if (a.progressPercent != b.progressPercent) {
        return b.progressPercent.compareTo(a.progressPercent);
      }
      if (a.targetDate != b.targetDate) {
        return a.targetDate.compareTo(b.targetDate);
      }
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<GoalModel>>(
      stream: _goalController.getGoals(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final goals = snapshot.data!;
        _sortGoals(goals);

        final displayGoals = _isExpanded ? goals.take(3).toList() : goals.take(1).toList();
        final hasMore = goals.length > 1;

        return Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC2185B).withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.savings_rounded, color: Color(0xFFC2185B), size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Mục tiêu tiết kiệm',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalListScreen()));
                      },
                      child: const Text(
                        'Xem tất cả',
                        style: TextStyle(color: Color(0xFFC2185B), fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Column(
                  children: displayGoals.map((goal) => _buildGoalItem(goal)).toList(),
                ),
              ),
              if (hasMore)
                InkWell(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey[100]!)),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_isExpanded ? 'Thu gọn' : 'Xem thêm', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        Icon(_isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                      ],
                    ),
                  ),
                )
            ],
          ),
        );
      },
    );
  }

  Widget _buildGoalItem(GoalModel goal) {
    Color mainColor = Color(int.parse(goal.colorHex, radix: 16));
    
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GoalDetailScreen(goal: goal))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: mainColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    IconData(int.parse(goal.iconCode, radix: 16), fontFamily: 'MaterialIcons'),
                    color: mainColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              goal.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text('${(goal.progressPercent * 100).toStringAsFixed(0)}%', style: TextStyle(color: mainColor, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('${_currencyFormat.format(goal.currentAmount)} / ${_currencyFormat.format(goal.targetAmount)}', style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: goal.progressPercent.clamp(0.0, 1.0),
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(mainColor),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
