import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../auth/domain/usecases/email_auth_usecases.dart';

/// Placeholder landing screen.
///
/// The Home module is the next milestone; this exists so every auth flow has
/// a real destination and the sign-out path can be exercised end to end.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      scrollable: false,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.appName.tr,
              style: AppTextStyles.headlineMedium.rc(AppColors.authInk),
            ),
            AppSpacing.gapV(AppSpacing.xs),
            Text(
              AppStrings.comingSoon.tr,
              style: AppTextStyles.bodyMedium.rc(AppColors.bodyInk),
            ),
            AppSpacing.gapV(AppSpacing.xl2),
            AppButton(
              label: 'Sign out',
              expanded: false,
              onPressed: () async {
                await Get.find<Logout>()();
                Get.offAllNamed<void>(AppRoutes.onboarding);
              },
            ),
          ],
        ),
      ),
    );
  }
}
