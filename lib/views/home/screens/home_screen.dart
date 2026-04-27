import 'package:flutter/material.dart';

import '../widgets/quick_actions_widget.dart';
import '../widgets/summary_widget.dart';
import '../widgets/warning_widget.dart';
import '../widgets/chart_widget.dart';
import '../widgets/budget_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          QuickActionsWidget(),
          SizedBox(height: 20),
          SummaryWidget(),
          SizedBox(height: 20),
          WarningWidget(),
          SizedBox(height: 20),
          ChartWidget(),
          SizedBox(height: 20),
          BudgetWidget(),
        ],
      ),
    );
  }
}