import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/entities/onboarding_page.dart';

/// One onboarding slide: illustration, headline, supporting line.
///
/// The illustration takes the slack (`Expanded`) so slides with one- and
/// two-line bodies still bottom-align their text against the panel, exactly
/// as the three mock-ups do.
class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({super.key, required this.page});

  final OnboardingPage page;

  /// Illustration width measured from the design (227 of 390).
  static const double _illustrationWidth = 227;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Image.asset(
              page.image,
              width: _illustrationWidth.w,
              fit: BoxFit.contain,
            ),
          ),
        ),
        AppSpacing.gapV(AppSpacing.xs),
        Text(
          page.titleKey.tr,
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineSmall.rc(AppColors.authInk),
        ),
        AppSpacing.gapV(AppSpacing.xs2),
        Text(
          page.bodyKey.tr,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.rc(AppColors.bodyInk),
        ),
      ],
    );
  }
}
