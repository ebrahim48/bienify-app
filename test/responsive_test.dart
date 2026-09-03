import 'package:bienify_app/app.dart';
import 'package:bienify_app/core/di/dependency_injection.dart';
import 'package:bienify_app/core/localization/app_translations.dart';
import 'package:bienify_app/core/theme/app_theme.dart';
import 'package:bienify_app/core/widgets/app_pill_selector.dart';
import 'package:bienify_app/features/Role/doctor_role/presentation/bindings/doctor_bindings.dart';
import 'package:bienify_app/features/Role/doctor_role/presentation/screens/doctor_shell_screen.dart';
import 'package:bienify_app/features/Role/doctor_role/presentation/screens/results_to_review_screen.dart';
import 'package:bienify_app/features/Role/doctor_role/presentation/screens/write_prescription_screen.dart';
import 'package:bienify_app/features/Role/patient/main/presentation/bindings/main_binding.dart';
import 'package:bienify_app/features/Role/patient/main/presentation/screens/main_shell_screen.dart';
import 'package:bienify_app/features/Role/patient/profile/presentation/bindings/profile_bindings.dart';
import 'package:bienify_app/features/Role/doctor_role/presentation/screens/doctor_profile_screen.dart';
import 'package:bienify_app/features/Role/patient/profile/presentation/screens/order_history_screen.dart';
import 'package:bienify_app/features/Role/patient/profile/presentation/screens/profile_screen.dart';
import 'package:bienify_app/features/Role/patient/profile/presentation/screens/wallet_screen.dart';
import 'package:bienify_app/features/Role/pharmacy_owner_role/presentation/screens/shop_profile_screen.dart';
import 'package:bienify_app/features/Role/rider_role/presentation/screens/rider_profile_screen.dart';
import 'package:bienify_app/features/Role/pharmacy_owner_role/presentation/bindings/shop_bindings.dart';
import 'package:bienify_app/features/Role/pharmacy_owner_role/presentation/screens/shop_shell_screen.dart';
import 'package:bienify_app/features/Role/rider_role/presentation/bindings/rider_bindings.dart';
import 'package:bienify_app/features/Role/rider_role/presentation/screens/rider_shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_fonts.dart';

/// Renders each role's shell at the narrowest and widest phones the app is
/// likely to meet, and fails if anything overflows.
///
/// A `RenderFlex` that overruns its box paints the yellow-and-black stripe in
/// debug and silently clips in release — and the clipped half is usually a
/// label. This is the check that catches it before a device does: the chip row
/// above the doctor's appointments used to scroll, so "Completed Appointment"
/// sat off the screen edge with nothing to say it was there.
void main() {
  setUpAll(loadAppFonts);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Get.testMode = true;
    await DependencyInjection.init(useMocks: true);
  });

  tearDown(() {
    DependencyInjection.clear();
    Get.reset();
  });

  /// The span the app has to survive: a small Android phone through to a
  /// large one, at the text scale a reader may have set.
  const sizes = <String, Size>{
    'small phone (320)': Size(320, 640),
    'compact phone (360)': Size(360, 740),
    'design frame (390)': Size(390, 876),
    'large phone (430)': Size(430, 932),
  };

  Future<void> pumpAt(
    WidgetTester tester,
    Widget screen,
    Size size, {
    Bindings? binding,
  }) async {
    tester.view.physicalSize = size;
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
              page: () => screen,
              binding: binding,
              transition: Transition.noTransition,
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
  }

  /// Every screen in the app that owns a bottom-nav shell, plus the two whose
  /// chip rows carry the longest labels.
  final screens = <String, (Widget, Bindings)>{
    'patient shell': (const MainShellScreen(), MainBinding()),
    'doctor shell': (const DoctorShellScreen(), DoctorShellBinding()),
    'shop shell': (const ShopShellScreen(), ShopShellBinding()),
    'rider shell': (const RiderShellScreen(), RiderShellBinding()),
    'results to review': (
      const ResultsToReviewScreen(),
      ResultsToReviewBinding(),
    ),
    'order history': (const OrderHistoryScreen(), AccountBinding()),
    // The prescription form packs a strength field beside a unit picker and
    // two rows of choice chips; 320 is where that gets tight.
    'write prescription': (
      const WritePrescriptionScreen(),
      WritePrescriptionBinding(),
    ),
  };

  /// The label sets the app actually puts in a pill row.
  ///
  /// Tested directly rather than through a shell: the chips live on tabs the
  /// shell does not open on, so rendering the shell alone never draws them.
  const pillSets = <String, List<String>>{
    'doctor appointments': [
      'New Appointment',
      'Completed Appointment',
      'Cancelled Appointment',
    ],
    'shop orders': [
      'New',
      'Accepted',
      'Declined',
      'Preparing',
      'Out for delivery',
      'Delivered',
    ],
    'patient appointments': [
      'Upcoming Appointments',
      'Past Appointments',
      'Cancelled Appointments',
    ],
    'order history': ['All', 'Delivered', 'Pending', 'Cancelled'],
    'results to review': ['Patients', 'Lab Orders', 'Radiology Orders'],
  };

  for (final set in pillSets.entries) {
    for (final size in sizes.entries) {
      testWidgets('${set.key} pills fit a ${size.key}', (tester) async {
        await pumpAt(
          tester,
          Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppPillSelector(
                labels: set.value,
                selectedIndex: 0,
                onSelected: (_) {},
                isLarge: true,
              ),
            ),
          ),
          size.value,
        );

        for (final label in set.value) {
          final rect = tester.getRect(find.text(label));
          expect(
            rect.right,
            lessThanOrEqualTo(size.value.width),
            reason:
                '"$label" runs past the right edge of a ${size.key}. A row '
                'that scrolls hides it with nothing to say it is there.',
          );
          expect(rect.left, greaterThanOrEqualTo(0));
        }
      });
    }
  }

  for (final screen in screens.entries) {
    for (final size in sizes.entries) {
      testWidgets('${screen.key} lays out on a ${size.key}', (tester) async {
        final errors = <FlutterErrorDetails>[];
        final previous = FlutterError.onError;
        FlutterError.onError = errors.add;
        addTearDown(() => FlutterError.onError = previous);

        await pumpAt(
          tester,
          screen.value.$1,
          size.value,
          binding: screen.value.$2,
        );

        final overflows = errors
            .map((e) => e.exception.toString())
            .where((e) => e.contains('overflowed'))
            .toList();

        expect(
          overflows,
          isEmpty,
          reason:
              '${screen.key} overflows at ${size.key} — the clipped part is '
              'invisible on a real device:\n${overflows.join('\n')}',
        );

        // Overflow is only half of it. A row that *scrolls* never overflows —
        // it just leaves content past the edge with nothing to say it is
        // there, which is how "Completed Appointment" came to sit half off
        // the screen. So every pill has to be inside the viewport too.
        for (final pill in tester.widgetList<AppPillSelector>(
          find.byType(AppPillSelector),
        )) {
          for (final label in pill.labels) {
            final text = find.descendant(
              of: find.byWidget(pill),
              matching: find.text(label),
            );
            if (text.evaluate().isEmpty) continue;
            final rect = tester.getRect(text);
            expect(
              rect.right,
              lessThanOrEqualTo(size.value.width),
              reason:
                  '"$label" runs past the right edge of a ${size.key} in '
                  '${screen.key}',
            );
            expect(
              rect.left,
              greaterThanOrEqualTo(0),
              reason: '"$label" starts left of a ${size.key} in ${screen.key}',
            );
          }
        }
      });
    }
  }

  // The four Profile tabs, on a viewport too short for their content.
  //
  // Each pinned its log-out bar with a trailing `Spacer`, which cannot shrink:
  // the doctor's overflowed by 34px on a running emulator whose content area
  // was 423pt tall. A `Spacer` is only safe when the content is guaranteed to
  // fit, and four menu rows plus a profile card are not.
  //
  // 400pt is deliberately shorter than the 640 the size matrix starts at —
  // that matrix never got small enough to catch this.
  group('profile tabs survive a short viewport', () {
    final profiles = <String, (Widget, Bindings)>{
      'patient': (const ProfileScreen(), ProfileBinding()),
      'doctor': (const DoctorProfileScreen(), DoctorProfileBinding()),
      'shop': (const ShopProfileScreen(), ShopProfileBinding()),
      'rider': (const RiderProfileScreen(), RiderProfileBinding()),
    };

    for (final entry in profiles.entries) {
      testWidgets('${entry.key} profile does not overflow at 360x400', (
        tester,
      ) async {
        await pumpAt(
          tester,
          entry.value.$1,
          const Size(360, 400),
          binding: entry.value.$2,
        );

        expect(tester.takeException(), isNull);

        // The bar stays pinned rather than scrolling away with the content,
        // which is the reason the `Spacer` was there in the first place.
        expect(find.text('Log out'), findsOneWidget);
      });
    }
  });

  group('the wallet card survives a short screen', () {
    // The balance card pinned a height in `.h`, which scales by screen
    // *height*, while the type inside scales by width. On a short, wide screen
    // — the doctor's tablet-shaped emulator — the card shrank, the numbers did
    // not, and the Add Money button was struck through with the overflow bars.
    //
    // The golden for this screen pumps at 390x1000, taller than any phone that
    // breaks it, so it could never have caught this. These are the short ones.
    for (final size in const [Size(360, 640), Size(392, 697), Size(360, 560)]) {
      testWidgets('no overflow at ${size.width.toInt()}x${size.height.toInt()}', (
        tester,
      ) async {
        await pumpAt(tester, const WalletScreen(), size, binding: AccountBinding());

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Add Money stays on the card, not under the fold', (
      tester,
    ) async {
      // The button is the point of the card. An overflow clips it rather than
      // removing it, so its presence alone proves nothing — this checks it is
      // actually painted inside the card it belongs to.
      await pumpAt(
        tester,
        const WalletScreen(),
        const Size(392, 697),
        binding: AccountBinding(),
      );

      final button = find.text('Add Money');
      expect(button, findsOneWidget);
      expect(tester.getRect(button).bottom, lessThan(697));
    });
  });
}
