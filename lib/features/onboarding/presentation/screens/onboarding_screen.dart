import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_language_toggle.dart';
import '../../../../core/widgets/app_page_indicator.dart';
import '../controllers/onboarding_controller.dart';
import '../widgets/auth_panel.dart';
import '../widgets/onboarding_slide.dart';

/// Onboarding: a three-slide carousel over a fixed sign-in panel.
///
/// The split is proportional (54 / 46) rather than a fixed pixel height, so
/// the panel keeps its designed weight from a 640pt handset to a tablet.
class OnboardingScreen extends GetView<OnboardingController> {
  const OnboardingScreen({super.key});

  /// Share of the screen given to the illustration half in the design
  /// (471 of 876).
  static const double _topFlex = 0.537;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.overlayStyle,
      child: Scaffold(
        backgroundColor: AppColors.authBackground,
        // The panel is anchored to the bottom edge; letting the keyboard
        // resize it would tear it away from the design.
        resizeToAvoidBottomInset: false,
        body: Column(
          children: [
            Expanded(
              flex: (_topFlex * 1000).round(),
              child: SafeArea(bottom: false, child: _TopSection()),
            ),
            Expanded(
              flex: ((1 - _topFlex) * 1000).round(),
              child: SingleChildScrollView(
                reverse: true,
                physics: const ClampingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.only(bottom: context.keyboardInset),
                  child: SafeArea(
                    top: false,
                    child: AuthPanel(onLoginTap: controller.goToLogin),
                  ),
                ),
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
