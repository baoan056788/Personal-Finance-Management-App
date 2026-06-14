import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_management_app/models/budget_model.dart';
import 'package:personal_finance_management_app/models/transaction_model.dart';
import 'package:personal_finance_management_app/utils/budget_calculator.dart';

void main() {
  group('calculateBudget', () {
    test('calculates remaining amount and safe progress', () {
      final result = calculateBudget(1000000, 250000);

      expect(result.spentAmount, 250000);
      expect(result.remainAmount, 750000);
      expect(result.progressPercent, 0.25);
      expect(result.status, 'SAFE');
    });

    test('uses warning thresholds consistently', () {
      expect(calculateBudget(100, 80).status, 'WARNING');
      expect(calculateBudget(100, 90).status, 'DANGER');
      expect(calculateBudget(100, 100).status, 'DANGER');
      expect(calculateBudget(100, 101).status, 'OVER_LIMIT');
    });

    test('does not allow malformed negative spending to increase budget', () {
      final result = calculateBudget(100, -20);

      expect(result.spentAmount, 0);
      expect(result.remainAmount, 100);
      expect(result.status, 'SAFE');
    });
  });

  test('budget period includes both boundaries', () {
    final start = DateTime(2026, 6, 1);
    final end = DateTime(2026, 6, 30, 23, 59, 59);

    expect(isWithinBudgetPeriod(start, start, end), isTrue);
    expect(isWithinBudgetPeriod(end, start, end), isTrue);
    expect(isWithinBudgetPeriod(DateTime(2026, 5, 31), start, end), isFalse);
    expect(isWithinBudgetPeriod(DateTime(2026, 7, 1), start, end), isFalse);
  });

  test('matches only expense transactions in the budget scope', () {
    final budget = BudgetModel(
      id: 'budget-1',
      userId: 'user-1',
      categoryId: 'food',
      walletId: 'wallet-1',
      name: 'Ăn uống',
      limitAmount: 1000000,
      spentAmount: 0,
      remainAmount: 1000000,
      progressPercent: 0,
      startDate: DateTime(2026, 6, 1),
      endDate: DateTime(2026, 6, 30, 23, 59, 59),
      periodType: 'MONTHLY',
      note: '',
      status: 'SAFE',
      createdAt: DateTime(2026, 6, 1),
      updatedAt: DateTime(2026, 6, 1),
    );
    final matchingTransaction = TransactionModel(
      id: 'tx-1',
      amount: 100000,
      type: 'expense',
      category: 'Ăn uống',
      categoryId: 'food',
      note: 'Bữa trưa',
      createdAt: DateTime(2026, 6, 15),
      walletId: 'wallet-1',
    );

    expect(transactionCountsTowardBudget(budget, matchingTransaction), isTrue);
    expect(
      transactionCountsTowardBudget(
        budget,
        matchingTransaction.copyWith(walletId: 'wallet-2'),
      ),
      isFalse,
    );
    expect(
      transactionCountsTowardBudget(
        budget,
        matchingTransaction.copyWith(type: 'income'),
      ),
      isFalse,
    );
  });

  test('goal deposit counts toward a saving-category budget', () {
    final budget = BudgetModel(
      id: 'saving-budget',
      userId: 'user-1',
      categoryId: 'saving',
      walletId: 'wallet-1',
      name: 'Tiết Kiệm',
      limitAmount: 2000000,
      spentAmount: 0,
      remainAmount: 2000000,
      progressPercent: 0,
      startDate: DateTime(2026, 6, 1),
      endDate: DateTime(2026, 6, 30, 23, 59, 59),
      periodType: 'MONTHLY',
      note: '',
      status: 'SAFE',
      createdAt: DateTime(2026, 6, 1),
      updatedAt: DateTime(2026, 6, 1),
    );
    final deposit = TransactionModel(
      id: 'goal-deposit',
      amount: 500000,
      type: 'goal',
      category: 'Tiết Kiệm',
      categoryId: 'saving',
      note: '',
      createdAt: DateTime(2026, 6, 14),
      walletId: 'wallet-1',
      cashFlowDirection: 'out',
    );

    expect(transactionCountsTowardBudget(budget, deposit), isTrue);
    expect(
      transactionCountsTowardBudget(
        budget,
        deposit.copyWith(cashFlowDirection: 'in'),
      ),
      isFalse,
    );
  });
}
