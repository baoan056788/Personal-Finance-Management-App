enum GoalMoneyViolation {
  invalidAmount,
  exceedsGoalAmount,
  insufficientWalletBalance,
}

GoalMoneyViolation? validateGoalMoney({
  required double amount,
  required double availableGoalAmount,
  required bool isWithdrawal,
  double? walletBalance,
}) {
  if (!amount.isFinite || amount <= 0) {
    return GoalMoneyViolation.invalidAmount;
  }
  if (amount > availableGoalAmount + 0.001) {
    return GoalMoneyViolation.exceedsGoalAmount;
  }
  if (!isWithdrawal &&
      walletBalance != null &&
      amount > walletBalance + 0.001) {
    return GoalMoneyViolation.insufficientWalletBalance;
  }
  return null;
}
