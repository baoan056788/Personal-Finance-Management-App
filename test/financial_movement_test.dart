import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_management_app/models/debt_model.dart';
import 'package:personal_finance_management_app/models/goal_contribution_model.dart';
import 'package:personal_finance_management_app/models/transaction_model.dart';
import 'package:personal_finance_management_app/utils/finance_error_message.dart';
import 'package:personal_finance_management_app/utils/goal_money_validator.dart';

void main() {
  group('internal financial movements', () {
    test('legacy goal expense remains an expense in reports', () {
      final transaction = TransactionModel.fromMap({
        'amount': 500000,
        'type': 'expense',
        'category': 'Tiết Kiệm',
        'note': 'Góp mục tiêu: Mua điện thoại',
      }, 'legacy-goal');

      expect(transaction.isGoalMovement, isTrue);
      expect(transaction.isExpense, isTrue);
      expect(transaction.reportImpact, -500000);
      expect(transaction.walletBalanceImpact, -500000);
    });

    test('goal deposit reduces wallet and is counted as an expense', () {
      final transaction = TransactionModel(
        id: 'goal-deposit',
        amount: 500000,
        type: 'goal',
        category: 'Mục tiêu tiết kiệm',
        note: '',
        createdAt: DateTime(2026, 6, 14),
        cashFlowDirection: 'out',
      );

      expect(transaction.walletBalanceImpact, -500000);
      expect(transaction.reportImpact, -500000);
      expect(transaction.isExpense, isTrue);
      expect(transaction.isInternalMovement, isTrue);
    });

    test('goal withdrawal increases wallet and is counted as income', () {
      final transaction = TransactionModel(
        id: 'goal-withdrawal',
        amount: 200000,
        type: 'goal',
        category: 'Mục tiêu tiết kiệm',
        note: '',
        createdAt: DateTime(2026, 6, 14),
        cashFlowDirection: 'in',
      );

      expect(transaction.walletBalanceImpact, 200000);
      expect(transaction.reportImpact, 200000);
      expect(transaction.isIncome, isTrue);
      expect(transaction.isCredit, isTrue);
    });

    test('debt repayment reduces wallet without becoming an expense', () {
      final transaction = TransactionModel(
        id: 'debt-payment',
        amount: 300000,
        type: 'debt',
        category: 'Trả nợ',
        note: '',
        createdAt: DateTime(2026, 6, 14),
        cashFlowDirection: 'out',
      );

      expect(transaction.walletBalanceImpact, -300000);
      expect(transaction.reportImpact, 0);
      expect(transaction.isDebtMovement, isTrue);
    });
  });

  test('goal withdrawal contribution is represented by a negative amount', () {
    final contribution = GoalContributionModel(
      id: 'withdrawal',
      goalId: 'goal',
      walletId: 'wallet',
      transactionId: 'transaction',
      amount: -100000,
      note: '',
      createdAt: DateTime(2026, 6, 14),
      type: 'withdrawal',
    );

    expect(contribution.isWithdrawal, isTrue);
    expect(contribution.amount, -100000);
  });

  test('debt remaining amount reflects partial payments', () {
    final debt = DebtModel(
      id: 'debt',
      userId: 'user',
      type: 'borrowed',
      personName: 'Nguyễn Văn An',
      amount: 1000000,
      paidAmount: 400000,
      dueDate: DateTime(2026, 6, 30),
      createdAt: DateTime(2026, 6, 14),
      updatedAt: DateTime(2026, 6, 14),
    );

    expect(debt.remainAmount, 600000);
    expect(debt.isPaid, isFalse);
  });

  test('permission errors are converted to a friendly message', () {
    final message = financeErrorMessage(
      FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
    );

    expect(message, isNot(contains('cloud_firestore')));
    expect(message, isNot(contains('permission-denied')));
    expect(message, contains('Không thể cập nhật dữ liệu'));
  });

  group('goal money validation', () {
    test('rejects a withdrawal larger than the saved amount', () {
      expect(
        validateGoalMoney(
          amount: 1000000,
          availableGoalAmount: 100000,
          isWithdrawal: true,
        ),
        GoalMoneyViolation.exceedsGoalAmount,
      );
    });

    test('rejects a deposit larger than the selected wallet balance', () {
      expect(
        validateGoalMoney(
          amount: 1000000,
          availableGoalAmount: 2000000,
          isWithdrawal: false,
          walletBalance: 100000,
        ),
        GoalMoneyViolation.insufficientWalletBalance,
      );
    });
  });
}
