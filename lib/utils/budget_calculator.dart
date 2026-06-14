import '../models/budget_model.dart';
import '../models/transaction_model.dart';

class BudgetCalculation {
  final double spentAmount;
  final double remainAmount;
  final double progressPercent;
  final String status;

  const BudgetCalculation({
    required this.spentAmount,
    required this.remainAmount,
    required this.progressPercent,
    required this.status,
  });
}

BudgetCalculation calculateBudget(double limitAmount, double spentAmount) {
  final normalizedSpent = spentAmount < 0 ? 0.0 : spentAmount;
  final progress = limitAmount > 0 ? normalizedSpent / limitAmount : 0.0;

  var status = 'SAFE';
  if (progress > 1) {
    status = 'OVER_LIMIT';
  } else if (progress >= 0.9) {
    status = 'DANGER';
  } else if (progress >= 0.8) {
    status = 'WARNING';
  }

  return BudgetCalculation(
    spentAmount: normalizedSpent,
    remainAmount: limitAmount - normalizedSpent,
    progressPercent: progress,
    status: status,
  );
}

bool isWithinBudgetPeriod(DateTime date, DateTime start, DateTime end) {
  return !date.isBefore(start) && !date.isAfter(end);
}

String? budgetCategoryIdForTransaction(TransactionModel transaction) {
  final categoryId = transaction.categoryId;
  if (categoryId != null && categoryId.isNotEmpty) return categoryId;
  if (transaction.category.isNotEmpty &&
      !transaction.category.contains(' ') &&
      transaction.category.length > 15) {
    return transaction.category;
  }
  return null;
}

bool transactionCountsTowardBudget(
  BudgetModel budget,
  TransactionModel transaction,
) {
  if (!transaction.isExpense) return false;
  if (budgetCategoryIdForTransaction(transaction) != budget.categoryId) {
    return false;
  }
  if (budget.walletId != null && budget.walletId != transaction.walletId) {
    return false;
  }
  return isWithinBudgetPeriod(
    transaction.createdAt,
    budget.startDate,
    budget.endDate,
  );
}
