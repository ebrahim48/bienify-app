import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/routes/app_routes.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/app_navigator.dart';
import '../../../../../../core/utils/responsive.dart';
import '../../../../../../core/widgets/app_button.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../../../../core/widgets/status_badge.dart';
import '../../../main/presentation/controllers/main_nav_controller.dart';

/// Confirmation screen shared by the two success designs.
///
/// They differ only in badge colour, headline and button, so both ship as
/// named constructors rather than as two near-identical screens.
class AuthStatusScreen extends StatelessWidget {
  const AuthStatusScreen({
    super.key,
    required this.badgeColor,
    required this.titleKey,
    required this.subtitleKey,
    required this.actionKey,
    required this.onAction,
  });

  /// Shown after profile setup completes — green badge, "Get Started".
  AuthStatusScreen.signUpComplete({super.key})
    : badgeColor = AppColors.success,
      titleKey = AppStrings.allSetUp,
      subtitleKey = AppStrings.careStartsHere,
      actionKey = AppStrings.getStarted,
      onAction = (() => AppNavigator.resetTo(AppRoutes.home));

  /// Shown after a password reset — primary badge, "Login Now".
  AuthStatusScreen.passwordUpdated({super.key})
    : badgeColor = AppColors.actionFill,
      titleKey = AppStrings.passwordUpdated,
      subtitleKey = AppStrings.careStartsHere,
      actionKey = AppStrings.loginNow,
      onAction = (() => AppNavigator.resetTo(AppRoutes.login));

  /// Shown after paying for a consultation — green badge, no subtitle, and a
  /// return to the Appointments tab.
  const AuthStatusScreen.appointmentBooked({super.key})
    : badgeColor = AppColors.success,
      titleKey = AppStrings.appointmentScheduled,
      subtitleKey = null,
      actionKey = AppStrings.backToAppointment,
      onAction = _returnToAppointments;

  /// Shown once the rider application is in — green badge, and a way into
  /// the courier's own shell.
  AuthStatusScreen.riderReady({super.key})
    : badgeColor = AppColors.success,
      titleKey = AppStrings.riderReady,
      subtitleKey = AppStrings.riderReadyBody,
      actionKey = AppStrings.backToHome,
      onAction = (() => AppNavigator.resetTo(AppRoutes.riderHome));

  final Color badgeColor;
  final String titleKey;

  /// Optional supporting line; omitted by the booking confirmation.
  final String? subtitleKey;

  final String actionKey;
  final VoidCallback onAction;

  /// Pops back to the shell and selects the Appointments tab.
  static void _returnToAppointments() {
    Get.until((route) => Get.currentRoute == AppRoutes.home);
    if (Get.isRegistered<MainNavController>()) {
      Get.find<MainNavController>().select(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      scrollable: false,
      bottomBar: AppButton(label: actionKey.tr, onPressed: onAction),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusBadge(color: badgeColor),
            AppSpacing.gapV(AppSpacing.xl),
            Text(
              titleKey.tr,
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineSmall.rc(AppColors.black),
            ),
            if (subtitleKey != null) ...[
              AppSpacing.gapV(AppSpacing.sm),
              Text(
                subtitleKey!.tr,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.rc(AppColors.fieldHint),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
