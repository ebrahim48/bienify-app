import 'package:bienify_app/features/Role/patient/chat/domain/entities/conversation.dart';
import 'package:bienify_app/features/Role/patient/pharmacy/domain/entities/pharmacy.dart';
import 'package:bienify_app/app.dart';
import 'package:bienify_app/core/models/chat_thread.dart';
import 'package:bienify_app/core/di/dependency_injection.dart';
import 'package:bienify_app/core/localization/app_translations.dart';
import 'package:bienify_app/core/theme/app_theme.dart';
import 'package:bienify_app/features/Role/patient/appointments/domain/entities/appointment.dart';
import 'package:bienify_app/features/Role/patient/auth/presentation/screens/auth_status_screen.dart';
import 'package:bienify_app/features/Role/patient/booking/presentation/screens/payment_summary_screen.dart';
import 'package:bienify_app/features/Role/patient/chat/presentation/screens/chat_screen.dart';
import 'package:bienify_app/features/Role/patient/doctors/data/static/doctor_mock_data.dart';
import 'package:bienify_app/features/Role/patient/doctors/presentation/bindings/doctors_bindings.dart';
import 'package:bienify_app/features/Role/patient/doctors/presentation/screens/doctor_details_screen.dart';
import 'package:bienify_app/features/Role/patient/doctors/presentation/screens/doctor_search_screen.dart';
import 'package:bienify_app/features/Role/patient/pharmacy/presentation/controllers/order_tracking_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_fonts.dart';

/// Renders Search, Doctor Details, Payment Summary, the booking confirmation
/// and Chat so each can be compared against its design export.
///
/// Regenerate with `flutter test test/golden --update-goldens`.
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
    Object? arguments,
    Size size = const Size(390, 876),
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

    Get.toNamed<void>('/target', arguments: arguments);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
  }

  testWidgets('Search', (tester) async {
    await pump(
      tester,
      const DoctorSearchScreen(),
      binding: DoctorSearchBinding(),
    );
    await settleImages(tester);
    await expectLater(
      find.byType(DoctorSearchScreen),
      matchesGoldenFile('search.png'),
    );
  });

  testWidgets('Doctor details', (tester) async {
    await pump(
      tester,
      const DoctorDetailsScreen(),
      binding: DoctorDetailsBinding(),
      arguments: DoctorMockData.doctors.first,
      size: const Size(390, 1700),
    );
    await settleImages(tester);
    await expectLater(
      find.byType(DoctorDetailsScreen),
      matchesGoldenFile('doctor_details.png'),
    );
  });

  testWidgets('Doctor details lays out on a narrow, tall-text device', (
    tester,
  ) async {
    // The info grid once carried a fixed card height, which overflowed by a
    // fraction of a pixel when `.sp` and `.h` scaled apart. This renders it
    // at a narrower width with enlarged text so any regression trips the
    // overflow assertion rather than shipping.
    tester.platformDispatcher.textScaleFactorTestValue = 1.2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pump(
      tester,
      const DoctorDetailsScreen(),
      binding: DoctorDetailsBinding(),
      arguments: DoctorMockData.doctors.first,
      size: const Size(320, 1400),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('Payment summary', (tester) async {
    await pump(
      tester,
      const PaymentSummaryScreen(),
      binding: PaymentBinding(),
      arguments: Appointment(
        id: 'draft',
        doctorName: 'Dr. Kwame Mensah',
        specialty: 'Pediatrician',
        scheduledAt: DateTime(2026, 4, 1, 10),
      ),
      size: const Size(390, 1220),
    );
    await settleImages(tester);
    await expectLater(
      find.byType(PaymentSummaryScreen),
      matchesGoldenFile('payment_summary.png'),
    );
  });

  testWidgets('Appointment booked', (tester) async {
    await pump(tester, const AuthStatusScreen.appointmentBooked());
    await settleImages(tester);
    await expectLater(
      find.byType(AuthStatusScreen),
      matchesGoldenFile('appointment_booked.png'),
    );
  });

  testWidgets('Chat', (tester) async {
    // Every route into chat carries the person being talked to. The binding
    // used to fall back to the sample conversation when none was given, so a
    // thread could open with a doctor the user had never messaged.
    await pump(
      tester,
      const ChatScreen(),
      binding: ChatBinding(),
      arguments: const ConversationPeer(
        id: 'doctor-1',
        // The consultation this thread hangs off. Without it the screen is the
        // no-conversation case — no room to send to and none to call into — so
        // the golden documented a header with its call button missing.
        thread: ChatThread.consultation('appointment-1'),
        name: 'Dr Reed',
        specialty: 'Cardiology',
      ),
    );
    await settleImages(tester);
    await expectLater(find.byType(ChatScreen), matchesGoldenFile('chat.png'));
  });

  testWidgets('Chat reused for the delivery rider', (tester) async {
    // The courier thread is this same screen with a different peer, so the
    // only thing worth checking is that the header takes on the rider's name
    // and headshot rather than a doctor's.
    // The peer is built from the courier actually carrying the order, so one
    // has to be assigned. `rider` is null until then — it used to name the same
    // person on every order whether or not anybody had taken it.
    final tracking = Get.put(OrderTrackingController());
    // The delivery is the thread. Without one there is no conversation to
    // open, and `rider` is null — which is the state before anybody claims it.
    tracking.watchedDeliveryId = 'delivery-1';
    tracking.courier.value = const Courier(
      id: 'rider-1',
      name: 'Rider Arif',
      rating: 4.9,
      reviewCount: 128,
      vehicleType: 'motorbike',
    );

    await pump(
      tester,
      const ChatScreen(),
      binding: ChatBinding(),
      arguments: tracking.rider,
    );
    expect(find.text('Rider Arif'), findsOneWidget);

    await settleImages(tester);
    await expectLater(
      find.byType(ChatScreen),
      matchesGoldenFile('chat_rider.png'),
    );
  });
}
