import 'package:bienify_app/app.dart';
import 'package:bienify_app/core/di/dependency_injection.dart';
import 'package:bienify_app/core/localization/app_translations.dart';
import 'package:bienify_app/core/theme/app_theme.dart';
import 'package:bienify_app/features/main/presentation/bindings/main_binding.dart';
import 'package:bienify_app/features/main/presentation/screens/main_shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_fonts.dart';

/// Renders the signed-in shell to a PNG so the Home layout can be compared
/// against the design export.
///
/// Regenerate after an intentional visual change:
/// `flutter test test/golden --update-goldens`
///
/// Golden output is font-rendering sensitive, so treat a mismatch on a
/// different OS as environmental rather than a regression.
void main() {
  setUpAll(loadAppFonts);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
    await DependencyInjection.init();
  });

  tearDown(() {
    DependencyInjection.clear();
    Get.reset();
  });

  testWidgets('Home tab matches the design', (tester) async {
    // Taller than a handset so the whole feed is captured in one frame.
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: BienifyApp.designSize,
        builder: (context, child) => GetMaterialApp(
          theme: AppTheme.light,
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          initialRoute: '/',
          getPages: [
            GetPage(
              name: '/',
              page: () => const MainShellScreen(),
              binding: MainBinding(),
            ),
          ],
        ),
      ),
    );

    // Let the mock feed resolve and the shimmer settle.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 100));

    await settleImages(tester);
    await expectLater(
      find.byType(MainShellScreen),
      matchesGoldenFile('home.png'),
    );
  });
}
