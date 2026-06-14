enum OnboardingStep { profile, wallet, completed }

OnboardingStep resolveOnboardingStep({
  required bool isAdmin,
  required bool hasWallet,
  required bool profileCompleted,
}) {
  if (isAdmin || hasWallet) return OnboardingStep.completed;
  if (!profileCompleted) return OnboardingStep.profile;
  return OnboardingStep.wallet;
}
