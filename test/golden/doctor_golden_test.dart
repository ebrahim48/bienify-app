import 'package:bienify_app/app.dart';
import 'package:bienify_app/core/di/dependency_injection.dart';
import 'package:bienify_app/core/localization/app_translations.dart';
import 'package:bienify_app/core/theme/app_theme.dart';
import 'package:bienify_app/features/Role/doctor_role/domain/entities/doctor_practice.dart';
import 'package:bienify_app/features/Role/doctor_role/presentation/bindings/doctor_bindings.dart';
import 'package:bienify_app/features/Role/patient/appointments/presentation/screens/consultation_history_screen.dart';
import 'package:bienify_app/features/Role/doctor_role/data/static/doctor_practice_data.dart';
import 'package:bienify_app/features/Role/doctor_role/presentation/controllers/doctor_appointments_controller.dart';
import 'package:bienify_app/features/Role/doctor_role/presentation/controllers/doctor_messages_controller.dart';
import 'package:bienify_app/features/Role/doctor_role/presentation/controllers/doctor_schedule_controller.dart';
import 'package:bienify_app/features/Role/doctor_role/presentation/controllers/doctor_profile_controller.dart';
import 'package:bienify_app/features/Role/doctor_role/presentation/controllers/earnings_controller.dart';
import 'package:bienify_app/features/Role/doctor_role/presentation/controllers/write_prescription_controller.dart';
import 'package:bienify_app/features/Role/doctor_role/presentation/screens/doctor_appointment_details_screen.dart';
import 'package:bienify_app/features/Role/doctor_role/presentation/screens/doctor_edit_profile_screen.dart';
import 'package:bienify_app/features/Role/doctor_role/presentation/screens/earning_withdraw_screen.dart';
import 'package:bienify_app/features/Role/doctor_role/presentation/widgets/request_payout_dialog.dart';
import 'package:bienify_app/features/Role/doctor_role/presentation/screens/write_prescription_screen.dart';
import 'package:bienify_app/features/Role/doctor_role/presentation/controllers/doctor_shell_controller.dart';
import 'package:bienify_app/features/Role/doctor_role/presentation/screens/doctor_shell_screen.dart';
import 'package:bienify_app/features/Role/doctor_role/presentation/screens/set_schedule_screen.dart';
import 'package:bienify_app/features/Role/doctor_role/presentation/widgets/set_fees_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_fonts.dart';

/// Renders the practitioner section.
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

  testWidgets('Doctor dashboard', (tester) async {
    // The true 390×876 frame, not a tall surface: `.h` scales against the
    // viewport height, so a 1500pt-tall test window inflates every fixed
    // height and the capture stops resembling the device.
    await pump(
      tester,
      const DoctorShellScreen(),
      binding: DoctorShellBinding(),
    );
    await settleImages(tester);
    await expectLater(
      find.byType(DoctorShellScreen),
      matchesGoldenFile('doctor_home.png'),
    );

    // Scrolled, to reach the chart and today's list.
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -620),
    );
    await settleImages(tester);
    await expectLater(
      find.byType(DoctorShellScreen),
      matchesGoldenFile('doctor_home_scrolled.png'),
    );
  });

  testWidgets('Appointments tab', (tester) async {
    await pump(
      tester,
      const DoctorShellScreen(),
      binding: DoctorShellBinding(),
    );
    Get.find<DoctorShellController>().select(DoctorTab.appointments);
    await tester.pumpAndSettle();

    final appointments = Get.find<DoctorAppointmentsController>();
    // Two on the New chip; one has an open room, the other a muted Join.
    expect(appointments.visible.length, 2);
    expect(appointments.visible.where((a) => a.isJoinable).length, 1);

    await settleImages(tester);
    await expectLater(
      find.byType(DoctorShellScreen),
      matchesGoldenFile('doctor_appointments.png'),
    );
  });

  testWidgets('Cancelling moves a booking under the Cancelled chip', (
    tester,
  ) async {
    await pump(
      tester,
      const DoctorShellScreen(),
      binding: DoctorShellBinding(),
    );
    Get.find<DoctorShellController>().select(DoctorTab.appointments);
    await tester.pumpAndSettle();

    final controller = Get.find<DoctorAppointmentsController>();
    final target = controller.visible.first;

    controller.cancel(target, 'Patient rescheduled');
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(controller.visible.length, 1);

    controller.selectFilter(DoctorApptFilter.cancelled);
    await tester.pump();
    expect(controller.visible.any((a) => a.id == target.id), isTrue);
  });

  testWidgets('Message tab', (tester) async {
    await pump(
      tester,
      const DoctorShellScreen(),
      binding: DoctorShellBinding(),
    );
    Get.find<DoctorShellController>().select(DoctorTab.message);
    await tester.pumpAndSettle();

    await settleImages(tester);
    await expectLater(
      find.byType(DoctorShellScreen),
      matchesGoldenFile('doctor_messages.png'),
    );

    // The search narrows the list, which is what the field is for.
    final messages = Get.find<DoctorMessagesController>();
    expect(messages.visible.length, 5);
    messages.query.value = 'marcus';
    await tester.pump();
    expect(messages.visible.single.patientName, 'Marcus Lee');
  });

  testWidgets('Completed chip shows the settled consultations', (tester) async {
    await pump(
      tester,
      const DoctorShellScreen(),
      binding: DoctorShellBinding(),
    );
    final shell = Get.find<DoctorShellController>()
      ..select(DoctorTab.appointments);
    final appointments = Get.find<DoctorAppointmentsController>()
      ..selectFilter(DoctorApptFilter.completed);
    await tester.pumpAndSettle();

    expect(shell.tab.value, DoctorTab.appointments);
    expect(appointments.visible.length, 4);
    // A finished consultation carries the fee and no Join.
    expect(find.text(r'$120'), findsWidgets);
    expect(find.text('Join'), findsNothing);

    await settleImages(tester);
    await expectLater(
      find.byType(DoctorShellScreen),
      matchesGoldenFile('doctor_appointments_completed.png'),
    );
  });

  testWidgets('Profile tab', (tester) async {
    await pump(
      tester,
      const DoctorShellScreen(),
      binding: DoctorShellBinding(),
    );
    Get.find<DoctorShellController>().select(DoctorTab.profile);
    await tester.pumpAndSettle();

    await settleImages(tester);
    await expectLater(
      find.byType(DoctorShellScreen),
      matchesGoldenFile('doctor_profile.png'),
    );
  });

  testWidgets('Edit Profile', (tester) async {
    await pump(
      tester,
      const DoctorEditProfileScreen(),
      binding: DoctorProfileBinding(),
      size: const Size(390, 1400),
    );
    final controller = Get.find<DoctorProfileController>();
    expect(controller.hasLicenceDocument.value, isFalse);

    await settleImages(tester);
    await expectLater(
      find.byType(DoctorEditProfileScreen),
      matchesGoldenFile('doctor_edit_profile.png'),
    );

    controller.attachLicence();
    await tester.pump();
    expect(find.text('License document attached'), findsOneWidget);
  });

  testWidgets('Earning Withdraw, then the payout request', (tester) async {
    await pump(
      tester,
      const EarningWithdrawScreen(),
      binding: EarningsBinding(),
      size: const Size(390, 1000),
    );
    final controller = Get.find<EarningsController>();
    expect(controller.earnings.length, 3);

    await settleImages(tester);
    await expectLater(
      find.byType(EarningWithdrawScreen),
      matchesGoldenFile('doctor_earnings.png'),
    );

    await tester.tap(find.text('Request Payout').first);
    await tester.pumpAndSettle();
    expect(find.byType(RequestPayoutDialog), findsOneWidget);

    // Debit/Credit is selected on open, as the design shows.
    expect(controller.selectedMethodIndex.value, 0);

    await settleImages(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('doctor_request_payout.png'),
    );
  });

  testWidgets('Appointment Details', (tester) async {
    await pump(
      tester,
      const DoctorAppointmentDetailsScreen(),
      binding: DoctorAppointmentsBinding(),
      size: const Size(390, 1000),
    );
    // `select` rather than assigning `selected`: the attachments are fetched
    // for the booking, so setting the field alone leaves the list empty.
    final controller = Get.find<DoctorAppointmentsController>()
      ..select(DoctorPracticeData.appointments().first);
    await tester.pump();
    await tester.pump();

    expect(controller.patientDocuments.length, 2);

    await settleImages(tester);
    await expectLater(
      find.byType(DoctorAppointmentDetailsScreen),
      matchesGoldenFile('doctor_appointment_details.png'),
    );
  });

  testWidgets('Write Prescriptions, before and after saving a line', (
    tester,
  ) async {
    await pump(
      tester,
      const WritePrescriptionScreen(),
      binding: WritePrescriptionBinding(),
      size: const Size(390, 1300),
    );
    final controller = Get.find<WritePrescriptionController>();
    // A new script starts empty. The two lines in the design are a filled-in
    // example, not a default every patient would be prescribed.
    expect(controller.medicines, isEmpty);
    expect(controller.hasSaved.value, isFalse);

    await settleImages(tester);
    await expectLater(
      find.byType(WritePrescriptionScreen),
      matchesGoldenFile('doctor_write_prescription.png'),
    );

    // An incomplete line is refused rather than silently added: a name with
    // no strength behind it is not a prescription.
    controller
      ..setName('Ibuprofen')
      ..save();
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(controller.medicines, isEmpty);

    controller
      ..setStrength('400')
      ..setUnit(DoseUnit.mg)
      ..setDuration('5')
      ..setTimesPerDay(2)
      ..setTiming(MealTiming.withFood)
      ..setNotes('Take with food or milk')
      ..save();
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(controller.medicines.length, 1);
    expect(controller.hasSaved.value, isTrue);
    // Saving reveals the submit action, as the design's second screen shows.
    expect(find.text('Send to Patient'), findsOneWidget);

    await settleImages(tester);
    await expectLater(
      find.byType(WritePrescriptionScreen),
      matchesGoldenFile('doctor_write_prescription_saved.png'),
    );
  });

  testWidgets('The doctor ends the call on their own summary', (tester) async {
    await pump(tester, const ConsultationHistoryScreen(isDoctor: true));
    await settleImages(tester);

    // The patient checks their vault here; the doctor writes the script.
    expect(find.text('Write Prescription'), findsOneWidget);
    expect(find.text('Check Medical Vault'), findsNothing);

    await expectLater(
      find.byType(ConsultationHistoryScreen),
      matchesGoldenFile('doctor_consultation_done.png'),
    );
  });

  testWidgets('Set Schedule', (tester) async {
    // True device metrics, then scrolled — a tall surface would inflate every
    // `.h` and the controls would stop matching the design.
    await pump(
      tester,
      const SetScheduleScreen(),
      binding: DoctorScheduleBinding(),
    );
    await settleImages(tester);
    await expectLater(
      find.byType(SetScheduleScreen),
      matchesGoldenFile('doctor_set_schedule.png'),
    );

    // Far enough to reach the weekly summary and Save.
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -2200),
    );
    await settleImages(tester);
    await expectLater(
      find.byType(SetScheduleScreen),
      matchesGoldenFile('doctor_set_schedule_summary.png'),
    );
  });

  testWidgets('Closing a day drops it from the list and the summary', (
    tester,
  ) async {
    await pump(
      tester,
      const SetScheduleScreen(),
      binding: DoctorScheduleBinding(),
      size: const Size(390, 2000),
    );
    final controller = Get.find<DoctorScheduleController>();

    // The mock week opens five days; Friday and Saturday start closed.
    expect(controller.activeDays, 5);
    // Six one-hour slots on each of the five open days. The summary counts the
    // hours actually on the calendar rather than a fixed working day, so a
    // doctor who opens two slots is not credited with eight hours.
    expect(controller.totalHoursLabel, '30h');

    controller.toggleDay(0, false);
    await tester.pump();
    expect(controller.activeDays, 4);
    expect(controller.days.first.slots, isEmpty);

    // Re-opening restores the default hours rather than leaving it unbookable.
    controller.toggleDay(0, true);
    await tester.pump();
    expect(controller.days.first.slots, isNotEmpty);
    expect(controller.activeDays, 5);
  });

  testWidgets('A slot needs both a start and an end', (tester) async {
    await pump(
      tester,
      const SetScheduleScreen(),
      binding: DoctorScheduleBinding(),
      size: const Size(390, 2000),
    );
    final controller = Get.find<DoctorScheduleController>();
    final before = controller.days.first.slots.length;

    controller.addSlot(0);
    await tester.pump();
    expect(controller.days.first.slots.length, before);

    // The refusal shows a snackbar, whose ticker must finish before the tree
    // is torn down.
    await tester.pumpAndSettle(const Duration(seconds: 5));

    controller
      ..setStart(0, '08:00 AM')
      ..setEnd(0, '09:00 AM')
      ..addSlot(0);
    await tester.pump();
    expect(controller.days.first.slots.length, before + 1);
    // The typed times are normalised to the chip format the rest of the day
    // uses, rather than pasted together as they were entered.
    expect(controller.days.first.slots.last.label, '08-09 AM');
    expect(controller.days.first.slots.last.startMinute, 8 * 60);
    expect(controller.days.first.slots.last.endMinute, 9 * 60);
  });

  testWidgets('Set Fees sheet', (tester) async {
    await pump(
      tester,
      const DoctorShellScreen(),
      binding: DoctorShellBinding(),
      size: const Size(390, 876),
    );

    await tester.tap(find.text('Set Fees'));
    await tester.pumpAndSettle();
    expect(find.byType(SetFeesSheet), findsOneWidget);

    await settleImages(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('doctor_set_fees.png'),
    );
  });
}
