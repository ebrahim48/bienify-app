import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'core/localization/app_translations.dart';
import 'core/localization/localization_controller.dart';
import 'core/routes/app_pages.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';

/// Application root.
///
/// `ScreenUtilInit` fixes the design size at 390×876 — the frame every
/// Bienify mock-up was drawn on — so `.w`, `.h`, `.r` and `.sp` throughout the
/// widget tree resolve to the same proportions on any device.
class BienifyApp extends StatelessWidget {
  const BienifyApp({super.key});

  /// The canvas the designs were authored on.
  static const Size designSize = Size(390, 876);

  @override
  Widget build(BuildContext context) {
    final localization = Get.find<LocalizationController>();

    return ScreenUtilInit(
      designSize: designSize,
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => GetMaterialApp(
        title: 'Bienify',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: AppRoutes.splash,
        getPages: AppPages.routes,
        translations: AppTranslations(),
        locale: localization.initialLocale,
        fallbackLocale: AppLanguage.english.locale,
        defaultTransition: Transition.cupertino,
        // Keeps text legible without letting an extreme system font size
        // break the fixed-height controls in the design.
        builder: (context, widget) => MediaQuery.withClampedTextScaling(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.2,
          child: widget ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
