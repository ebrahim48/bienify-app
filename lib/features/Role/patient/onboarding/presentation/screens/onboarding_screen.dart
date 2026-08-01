import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../core/utils/responsive.dart';
import '../../../../../../core/widgets/app_language_toggle.dart';
import '../../../../../../core/widgets/app_page_indicator.dart';
import '../controllers/onboarding_controller.dart';
import '../widgets/auth_panel.dart';
import '../widgets/onboarding_slide.dart';

/// Onboarding: a three-slide carousel over a fixed sign-in panel.
///
/// The panel is laid out at its intrinsic height so no control is ever
/// clipped, and the illustration half takes whatever is left — on the 876pt
/// design that lands on the drawn 54 / 46 split, and on shorter handsets the
/// illustration gives up the difference instead of the buttons being cut off.
class OnboardingScreen extends GetView<OnboardingController> {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.overlayStyle,
      child: Scaffold(
        backgroundColor: AppColors.authBackground,
        // The panel is anchored to the bottom edge; letting the keyboard
        // resize it would tear it away from the design. It is lifted above
        // the keyboard by hand below instead.
        resizeToAvoidBottomInset: false,
        body: Column(
          children: [
            Expanded(
              child: SafeArea(
                bottom: false,
                // While typing there is no room for the carousel above the
                // raised panel; the slides come back as the keyboard closes.
                child: context.isKeyboardOpen
                    ? const SizedBox.shrink()
                    : _TopSection(),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: context.keyboardInset),
              child: SafeArea(
                top: false,
                child: AuthPanel(onLoginTap: controller.goToLogin),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopSection extends GetView<OnboardingController> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.pagePadding,
      child: Column(
        children: [
          AppSpacing.gapV(AppSpacing.sm),
          const Align(
            alignment: Alignment.centerRight,
            child: AppLanguageToggle(),
          ),
          AppSpacing.gapV(AppSpacing.xs2),
          Expanded(
            child: PageView.builder(
              controller: controller.pageController,
              onPageChanged: controller.onPageChanged,
              itemCount: controller.pageCount,
              itemBuilder: (context, index) =>
                  OnboardingSlide(page: controller.pages[index]),
            ),
          ),
          AppSpacing.gapV(AppSpacing.lg),
          Obx(
            () => AppPageIndicator(
              count: controller.pageCount,
              currentIndex: controller.currentIndex.value,
              onDotTap: controller.goToPage,
            ),
          ),
          AppSpacing.gapV(AppSpacing.md),
        ],
      ),
    );
  }
}
