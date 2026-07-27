import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_text_styles.dart';

/// Builds the single [ThemeData] used by the app.
///
/// Screens should read colours and type from [AppColors] / [AppTextStyles]
/// directly; this theme exists so that framework-owned surfaces (dialogs,
/// text selection, ripples, the system UI overlay) match the design too.
class AppTheme {
  AppTheme._();

  /// Status-bar / navigation-bar styling for the light auth screens.
  static const SystemUiOverlayStyle overlayStyle = SystemUiOverlayStyle(
    statusBarColor: AppColors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.authBackground,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.authBackground,
      primaryColor: AppColors.primary800,
      splashColor: AppColors.primary100.withValues(alpha: 0.4),
      highlightColor: AppColors.transparent,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary800,
        onPrimary: AppColors.actionLabel,
        secondary: AppColors.primary950,
        onSecondary: AppColors.white,
        surface: AppColors.white,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
      ),
      textTheme: _textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.authBackground,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: overlayStyle,
        iconTheme: IconThemeData(color: AppColors.authInk),
        titleTextStyle: AppTextStyles.titleMedium,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.fieldBorder,
        thickness: 1,
        space: 1,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primary800,
        selectionColor: AppColors.primary200,
        selectionHandleColor: AppColors.primary800,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl3),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary950,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary800,
      ),
    );
  }

  static const TextTheme _textTheme = TextTheme(
    displayLarge: AppTextStyles.displayLarge,
    displayMedium: AppTextStyles.displayMedium,
    displaySmall: AppTextStyles.displaySmall,
    headlineLarge: AppTextStyles.headlineLarge,
    headlineMedium: AppTextStyles.headlineMedium,
    headlineSmall: AppTextStyles.headlineSmall,
    titleLarge: AppTextStyles.titleLarge,
    titleMedium: AppTextStyles.titleMedium,
    titleSmall: AppTextStyles.titleSmall,
    bodyLarge: AppTextStyles.bodyLarge,
    bodyMedium: AppTextStyles.bodyMedium,
    bodySmall: AppTextStyles.bodySmall,
    labelLarge: AppTextStyles.labelLarge,
    labelMedium: AppTextStyles.labelMedium,
    labelSmall: AppTextStyles.labelSmall,
  );
}
