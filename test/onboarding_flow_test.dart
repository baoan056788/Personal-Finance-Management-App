import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_management_app/utils/onboarding_flow.dart';

void main() {
  test('new account must complete profile before creating first wallet', () {
    expect(
      resolveOnboardingStep(
        isAdmin: false,
        hasWallet: false,
        profileCompleted: false,
      ),
      OnboardingStep.profile,
    );
  });

  test('completed profile without wallet must create a wallet', () {
    expect(
      resolveOnboardingStep(
        isAdmin: false,
        hasWallet: false,
        profileCompleted: true,
      ),
      OnboardingStep.wallet,
    );
  });

  test('existing account with a wallet can enter the application', () {
    expect(
      resolveOnboardingStep(
        isAdmin: false,
        hasWallet: true,
        profileCompleted: false,
      ),
      OnboardingStep.completed,
    );
  });

  test('admin account is not blocked by personal wallet onboarding', () {
    expect(
      resolveOnboardingStep(
        isAdmin: true,
        hasWallet: false,
        profileCompleted: false,
      ),
      OnboardingStep.completed,
    );
  });
}
