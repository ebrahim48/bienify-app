import 'dart:io';

import 'package:bienify_app/app.dart';
import 'package:bienify_app/core/di/dependency_injection.dart';
import 'package:bienify_app/core/localization/app_translations.dart';
import 'package:bienify_app/core/theme/app_theme.dart';
import 'package:bienify_app/features/Role/patient/auth/presentation/screens/auth_status_screen.dart';
import 'package:bienify_app/features/Role/rider_role/domain/entities/rider.dart';
import 'package:bienify_app/features/Role/rider_role/presentation/bindings/rider_bindings.dart';
import 'package:bienify_app/features/Role/rider_role/presentation/controllers/rider_application_controller.dart';
import 'package:bienify_app/features/Role/rider_role/presentation/controllers/rider_orders_controller.dart';
import 'package:bienify_app/features/Role/rider_role/presentation/controllers/rider_shell_controller.dart';
import 'package:bienify_app/features/Role/rider_role/presentation/screens/rider_application_screen.dart';
import 'package:bienify_app/features/Role/rider_role/presentation/screens/rider_delivered_screen.dart';
import 'package:bienify_app/features/Role/rider_role/presentation/screens/rider_edit_profile_screen.dart';
import 'package:bienify_app/features/Role/rider_role/presentation/screens/rider_guide_screen.dart';
import 'package:bienify_app/features/Role/rider_role/presentation/screens/rider_shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_fonts.dart';

/// Renders the courier's section.
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

  Future<void> pump(
    WidgetTester tester,
    Widget screen, {
    Bindings? binding,
    Size size = const Size(390, 876),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: BienifyApp.designSize,
        builder: (context, child) => GetMaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          initialRoute: '/',
          getPages: [
            GetPage(name: '/', page: () => const Scaffold()),
            GetPage(
              name: '/target',
              page: () => screen,
              binding: binding,
              transition: Transition.noTransition,
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    Get.toNamed<void>('/target');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
  }

  testWidgets('How It Works', (tester) async {
    // The masthead names the signed-in courier now, so the screen needs the
    // controller that reads them — it drew the fixture courier before, on a
    // page a real courier opens.
    await pump(
      tester,
      const RiderGuideScreen(),
      binding: RiderGuideBinding(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rider Arif'), findsOneWidget);
    expect(find.text('Apply Rider?'), findsOneWidget);

    await settleImages(tester);
    await expectLater(
      find.byType(RiderGuideScreen),
      matchesGoldenFile('rider_guide.png'),
    );

    // The panel sits at the foot of a long page.
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -700),
    );
    await settleImages(tester);
    await expectLater(
      find.byType(RiderGuideScreen),
      matchesGoldenFile('rider_guide_apply.png'),
    );
  });

  testWidgets('The application walks its five steps', (tester) async {
    await pump(
      tester,
      const RiderApplicationScreen(),
      binding: RiderApplicationBinding(),
    );
    final controller = Get.find<RiderApplicationController>();
    // The greeting is the applicant's own first name, read from their account.
    // It said "Hey Arif!" to every courier who ever applied.
    controller.firstName.value = 'Arif';
    await tester.pump();

    expect(find.text('Hey Arif!'), findsOneWidget);
    await settleImages(tester);
    await expectLater(
      find.byType(RiderApplicationScreen),
      matchesGoldenFile('rider_apply_selfie.png'),
    );

    // The selfie is not starred, so the step lets the courier past.
    expect(controller.canContinue, isTrue);
    controller.next();
    await tester.pumpAndSettle();
    expect(find.text('Front of ID Card *'), findsOneWidget);
    // Both sides are starred, so this one does not.
    expect(controller.canContinue, isFalse);

    await settleImages(tester);
    await expectLater(
      find.byType(RiderApplicationScreen),
      matchesGoldenFile('rider_apply_identity.png'),
    );

    // Step past it the way a filled form would.
    controller.step.value = 2;
    await tester.pumpAndSettle();
    expect(find.text('Bike'), findsOneWidget);
    await settleImages(tester);
    await expectLater(
      find.byType(RiderApplicationScreen),
      matchesGoldenFile('rider_apply_vehicle.png'),
    );

    // The server will not store a profile without a licence number, so the
    // step holds the courier here until there is one — photographs alone are
    // not enough to file the application.
    controller.licence.value = File('licence.jpg');
    controller.vehiclePhoto.value = File('vehicle.jpg');
    expect(controller.canContinue, isFalse);
    controller.licenceNumber.value = 'DL-99887';
    expect(controller.canContinue, isTrue);

    controller.step.value = 3;
    await tester.pumpAndSettle();
    // A zone chip appears once the applicant picks one. Three were pre-picked
    // from a fixture before, so this step opened already answered.
    expect(controller.zones, isEmpty);
    controller.selectZone('lester city');
    // Selecting also moves the picker onto it, so the name would appear twice.
    controller.zone.value = 'Downtown';
    await tester.pumpAndSettle();
    expect(find.text('lester city'), findsOneWidget);
    await settleImages(tester);
    await expectLater(
      find.byType(RiderApplicationScreen),
      matchesGoldenFile('rider_apply_location.png'),
    );

    controller.step.value = 4;
    await tester.pumpAndSettle();
    expect(controller.isLastStep, isTrue);
    await settleImages(tester);
    await expectLater(
      find.byType(RiderApplicationScreen),
      matchesGoldenFile('rider_apply_payment.png'),
    );

    // The chevron walks back through the application.
    expect(controller.stepBack(), isTrue);
    expect(controller.step.value, 3);
  });

  testWidgets('Picking a zone adds a chip, tapping one removes it', (
    tester,
  ) async {
    await pump(
      tester,
      const RiderApplicationScreen(),
      binding: RiderApplicationBinding(),
    );
    final controller = Get.find<RiderApplicationController>()..step.value = 3;
    await tester.pumpAndSettle();

    // Nothing pre-picked: which zones a courier covers is their choice, and
    // the fixture chose three on their behalf.
    expect(controller.zones, isEmpty);

    controller.selectZone('Airport');
    await tester.pump();
    expect(controller.zones.length, 1);

    // Picking the same one twice does not double it up.
    controller.selectZone('Airport');
    await tester.pump();
    expect(controller.zones.length, 1);

    controller.selectZone('jamaica');
    // Move the picker off it, so the only 'jamaica' on screen is the chip.
    // Selecting a zone also sets the dropdown's value, and tapping that row
    // re-adds what the chip just removed.
    controller.zone.value = 'Airport';
    await tester.pumpAndSettle();

    await tester.tap(find.text('jamaica'));
    await tester.pumpAndSettle();
    expect(controller.zones.contains('jamaica'), isFalse);
  });

  testWidgets("You're all set up", (tester) async {
    await pump(tester, AuthStatusScreen.riderReady());

    expect(find.text("You're all set up !"), findsOneWidget);
    expect(find.text('Back to Home'), findsOneWidget);

    await settleImages(tester);
    await expectLater(
      find.byType(AuthStatusScreen),
      matchesGoldenFile('rider_ready.png'),
    );
  });

  testWidgets('Rider dashboard', (tester) async {
    await pump(tester, const RiderShellScreen(), binding: RiderShellBinding());

    expect(find.text(r'$21.75'), findsOneWidget);
    expect(find.text('Online — accepting orders'), findsOneWidget);

    await settleImages(tester);
    await expectLater(
      find.byType(RiderShellScreen),
      matchesGoldenFile('rider_home.png'),
    );
  });

  testWidgets('Order Requests, and what each chip allows', (tester) async {
    await pump(tester, const RiderShellScreen(), binding: RiderShellBinding());
    Get.find<RiderShellController>().select(RiderTab.orders);
    await tester.pumpAndSettle();

    final controller = Get.find<RiderOrdersController>();
    expect(controller.visible.length, 3);
    // A new job offers both answers.
    expect(find.text('Accept'), findsWidgets);

    await settleImages(tester);
    await expectLater(
      find.byType(RiderShellScreen),
      matchesGoldenFile('rider_orders_new.png'),
    );

    controller.selectTab(RequestTab.accepted);
    await tester.pumpAndSettle();
    // A taken job offers the map instead.
    expect(find.text('Track LIVE'), findsWidgets);
    expect(find.text('Accept'), findsNothing);

    await settleImages(tester);
    await expectLater(
      find.byType(RiderShellScreen),
      matchesGoldenFile('rider_orders_accepted.png'),
    );

    // Accepting moves a card between the chips.
    controller.selectTab(RequestTab.fresh);
    await tester.pumpAndSettle();
    final before = controller.visible.length;
    controller.accept(controller.visible.first);
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(controller.visible.length, before - 1);
  });

  testWidgets('Earnings', (tester) async {
    await pump(tester, const RiderShellScreen(), binding: RiderShellBinding());
    Get.find<RiderShellController>().select(RiderTab.earnings);
    await tester.pumpAndSettle();

    expect(find.text(r'$87.50'), findsOneWidget);
    // No payout day. This asserted "Friday", which came from a constant — the
    // platform has no payout schedule, so the chip is gone rather than naming
    // a day nothing computes.
    expect(find.text('Friday'), findsNothing);
    // What replaced it: a courier who has cleared the minimum can now ask to
    // be paid. The bar used to be the whole card.
    expect(find.text('Withdraw'), findsOneWidget);

    await settleImages(tester);
    await expectLater(
      find.byType(RiderShellScreen),
      matchesGoldenFile('rider_earnings.png'),
    );
  });

  testWidgets('Profile tab', (tester) async {
    await pump(tester, const RiderShellScreen(), binding: RiderShellBinding());
    Get.find<RiderShellController>().select(RiderTab.profile);
    await tester.pumpAndSettle();

    // The signed-in courier, not the design's sample name — the card used to
    // print `RiderData.profileName` whoever was logged in.
    expect(find.text('Rider Arif'), findsOneWidget);
    expect(find.text('My Wallet'), findsOneWidget);

    await settleImages(tester);
    await expectLater(
      find.byType(RiderShellScreen),
      matchesGoldenFile('rider_profile.png'),
    );
  });

  testWidgets('Edit Profile', (tester) async {
    await pump(
      tester,
      const RiderEditProfileScreen(),
      binding: RiderProfileBinding(),
      size: const Size(390, 1100),
    );

    await settleImages(tester);
    await expectLater(
      find.byType(RiderEditProfileScreen),
      matchesGoldenFile('rider_edit_profile.png'),
    );
  });

  testWidgets('Delivery completed', (tester) async {
    // With a courier session behind it, carrying the handover they just made.
    Get.put(RiderOrdersController()).receipt.value = const DeliveryReceipt(
      orderId: '#45892',
      customerName: 'John Doe',
      location: 'Banani, Dhaka',
      timeLabel: '4:32 PM',
    );
    await pump(tester, const RiderDeliveredScreen());
    await tester.pumpAndSettle();

    expect(find.text('Order successfully delivered!'), findsOneWidget);
    expect(find.text('#45892'), findsOneWidget);

    await settleImages(tester);
    await expectLater(
      find.byType(RiderDeliveredScreen),
      matchesGoldenFile('rider_delivered.png'),
    );
  });
}
