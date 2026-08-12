import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// One place for transient feedback, so every controller reports success and
/// failure the same way.
///
/// ```dart
/// AppSnackbar.success(AppStrings.otpResent.tr);
/// AppSnackbar.error(AppStrings.somethingWentWrong.tr);
/// ```
///
/// **Leave the screen first, then report.** GetX shows a snackbar as a route,
/// and `Get.back()` with one open closes the snackbar rather than the screen
/// — which left the payout dialog up over a withdrawal the server had already
/// taken, inviting a second tap that would file it twice. Write:
///
/// ```dart
/// Get.back<void>();
/// AppSnackbar.success(AppStrings.saved.tr);
/// ```
class AppSnackbar {
  AppSnackbar._();

  static void success(String message) =>
      _show(message, AppColors.success600, Icons.check_circle_outline_rounded);

  static void error(String message) =>
      _show(message, AppColors.error600, Icons.error_outline_rounded);

  static void info(String message) =>
      _show(message, AppColors.primary950, Icons.info_outline_rounded);

  static void _show(String message, Color background, IconData icon) {
    if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();

    Get.rawSnackbar(
      messageText: Text(
        message,
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
      ),
      icon: Icon(icon, color: AppColors.white),
      backgroundColor: background,
      borderRadius: AppRadius.xl,
      margin: const EdgeInsets.all(AppSpacing.base),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.sm,
      ),
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      animationDuration: const Duration(milliseconds: 250),
    );
  }
}
