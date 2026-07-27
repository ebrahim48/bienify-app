import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../core/routes/app_routes.dart';
import '../../data/static/onboarding_pages.dart';
import '../../domain/entities/onboarding_page.dart';

/// Paging state for the onboarding carousel.
///
/// Only the illustration and copy page; the sign-in panel underneath is
/// fixed, which is why it lives outside the `PageView`.
class OnboardingController extends GetxController {
  final PageController pageController = PageController();

  final RxInt currentIndex = 0.obs;

  List<OnboardingPage> get pages => OnboardingPages.all;

  int get pageCount => pages.length;

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  void onPageChanged(int index) => currentIndex.value = index;

  void goToPage(int index) => pageController.animateToPage(
    index,
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOut,
  );

  /// "Already have an account? Login".
  void goToLogin() => Get.toNamed<void>(AppRoutes.login);
}
