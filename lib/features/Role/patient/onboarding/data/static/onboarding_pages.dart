import '../../../../../../core/constants/app_assets.dart';
import '../../../../../../core/constants/app_strings.dart';
import '../../domain/entities/onboarding_page.dart';

/// The three onboarding slides, in order.
///
/// Static because the copy ships with the build; if it ever becomes
/// remote-configurable, only this file and the controller's source change.
class OnboardingPages {
  OnboardingPages._();

  static const List<OnboardingPage> all = [
    OnboardingPage(
      image: AppAssets.onboardingFindDoctor,
      titleKey: AppStrings.onboardingTitle1,
      bodyKey: AppStrings.onboardingBody1,
    ),
    OnboardingPage(
      image: AppAssets.onboardingConsult,
      titleKey: AppStrings.onboardingTitle2,
      bodyKey: AppStrings.onboardingBody2,
    ),
    OnboardingPage(
      image: AppAssets.onboardingMedicine,
      titleKey: AppStrings.onboardingTitle3,
      bodyKey: AppStrings.onboardingBody3,
    ),
  ];
}
