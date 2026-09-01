import 'package:bienify_app/core/localization/app_translations.dart';
import 'package:bienify_app/core/models/chat_thread.dart';
import 'package:bienify_app/core/routes/app_routes.dart';
import 'package:bienify_app/core/theme/app_theme.dart';
import 'package:bienify_app/features/Role/patient/appointments/domain/entities/appointment.dart';
import 'package:bienify_app/features/Role/patient/appointments/domain/repositories/appointment_repository.dart';
import 'package:bienify_app/features/Role/patient/chat/domain/entities/conversation.dart';
import 'package:bienify_app/features/Role/patient/doctors/domain/entities/doctor.dart';
import 'package:bienify_app/features/Role/patient/doctors/domain/entities/doctor_details.dart';
import 'package:bienify_app/features/Role/patient/doctors/domain/repositories/doctor_repository.dart';
import 'package:bienify_app/features/Role/patient/doctors/domain/usecases/doctor_usecases.dart';
import 'package:bienify_app/features/Role/patient/doctors/presentation/controllers/doctor_details_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../support/test_fonts.dart';

/// Covers the message button on Doctor Details.
///
/// It used to hand the chat screen a peer with no thread, which that screen
/// answers with the bundled sample conversation — a fabricated exchange the
/// patient could type into and reach nobody.
void main() {
  setUpAll(loadAppFonts);
  tearDown(Get.reset);

  const doctor = Doctor(
    id: 'profile-1',
    name: 'Dr Dana Okafor',
    specialty: 'Cardiology',
    photoUrl: 'https://example.test/dana.jpg',
  );

  Appointment booking({
    required String id,
    required AppointmentStatus status,
    required DateTime at,
    String profileId = 'profile-1',
    String userId = 'user-1',
  }) => Appointment(
    id: id,
    doctorName: doctor.name,
    specialty: doctor.specialty,
    scheduledAt: at,
    status: status,
    doctorProfileId: profileId,
    doctorUserId: userId,
  );

  DoctorDetailsController put(List<Appointment> appointments) {
    final repository = _StubDoctors();
    final controller = DoctorDetailsController(
      doctor: doctor,
      getDetails: GetDoctorDetails(repository),
      getAvailability: GetDoctorAvailability(repository),
      appointments: _StubAppointments(appointments),
    );
    Get.put(controller);
    return controller;
  }

  /// A host with the overlay Get needs for routing and snackbars, plus a stub
  /// chat route so the argument the button passes can be read back.
  Future<ConversationPeer?> pumpAndOpen(
    WidgetTester tester,
    DoctorDetailsController controller,
  ) async {
    ConversationPeer? opened;
    tester.view.physicalSize = const Size(390, 876);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 876),
        builder: (_, _) => GetMaterialApp(
          theme: AppTheme.light,
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const Scaffold(body: SizedBox()),
          getPages: [
            GetPage(
              name: AppRoutes.chat,
              page: () {
                opened = Get.arguments as ConversationPeer?;
                return const Scaffold();
              },
              transition: Transition.noTransition,
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    await controller.openChat();
    // Not `pumpAndSettle`: it runs past the snackbar's three-second life, so
    // the "book first" message is gone again before it can be asserted on.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    return opened;
  }

  testWidgets('opens the consultation thread, not the sample conversation', (
    tester,
  ) async {
    final controller = put([
      booking(
        id: 'appt-9',
        status: AppointmentStatus.upcoming,
        at: DateTime(2026, 9, 3, 10),
      ),
    ]);

    final peer = await pumpAndOpen(tester, controller);

    // Without a thread the chat screen falls back to the sample, so this is
    // the whole difference between a real conversation and a fake one.
    expect(peer?.thread, ChatThread.consultation('appt-9'));
    expect(peer?.thread?.isLive, isTrue);
  });

  testWidgets('addresses the peer by user id, not the doctor profile id', (
    tester,
  ) async {
    // Presence and typing are addressed per user. `Doctor.id` is a profile
    // id, so the header was asking after a user that does not exist.
    final controller = put([
      booking(
        id: 'appt-9',
        status: AppointmentStatus.upcoming,
        at: DateTime(2026, 9, 3, 10),
        userId: 'user-7',
      ),
    ]);

    final peer = await pumpAndOpen(tester, controller);

    expect(peer?.id, 'user-7');
    expect(peer?.id, isNot(doctor.id));
  });

  testWidgets('does not claim the doctor is online', (tester) async {
    // Seeding `true` made the header say Online whatever the doctor was; the
    // socket answers presence once the thread opens.
    final controller = put([
      booking(
        id: 'appt-9',
        status: AppointmentStatus.upcoming,
        at: DateTime(2026, 9, 3, 10),
      ),
    ]);

    final peer = await pumpAndOpen(tester, controller);

    expect(peer?.isOnline, isFalse);
    expect(peer?.photoUrl, doctor.photoUrl);
  });

  testWidgets('prefers the confirmed booking over a later unpaid one', (
    tester,
  ) async {
    // The unpaid one is the latest by date, so "take the most recent" would
    // pick it — and it has no consultation behind it to message about.
    final controller = put([
      booking(
        id: 'appt-old',
        status: AppointmentStatus.completed,
        at: DateTime(2026, 6, 1, 9),
      ),
      booking(
        id: 'appt-next',
        status: AppointmentStatus.upcoming,
        at: DateTime(2026, 9, 3, 10),
      ),
      booking(
        id: 'appt-unpaid',
        status: AppointmentStatus.pendingPayment,
        at: DateTime(2026, 9, 10, 10),
      ),
    ]);

    final peer = await pumpAndOpen(tester, controller);

    expect(peer?.thread, ChatThread.consultation('appt-next'));
  });

  testWidgets('falls back to the most recent past consultation', (
    tester,
  ) async {
    // A follow-up question after a consultation belongs on the thread it
    // happened in.
    final controller = put([
      booking(
        id: 'appt-older',
        status: AppointmentStatus.completed,
        at: DateTime(2026, 5, 1, 9),
      ),
      booking(
        id: 'appt-newer',
        status: AppointmentStatus.completed,
        at: DateTime(2026, 6, 1, 9),
      ),
    ]);

    final peer = await pumpAndOpen(tester, controller);

    expect(peer?.thread, ChatThread.consultation('appt-newer'));
  });

  testWidgets('says so rather than opening a thread with no consultation', (
    tester,
  ) async {
    final controller = put(const []);

    final peer = await pumpAndOpen(tester, controller);

    expect(peer, isNull);
    expect(find.text('Book a consultation to message this doctor'), findsOneWidget);
    await settleSnackbar(tester);
  });

  testWidgets('ignores a cancelled booking, which has no thread behind it', (
    tester,
  ) async {
    final controller = put([
      booking(
        id: 'appt-cancelled',
        status: AppointmentStatus.cancelled,
        at: DateTime(2026, 9, 3, 10),
      ),
    ]);

    final peer = await pumpAndOpen(tester, controller);

    expect(peer, isNull);
    await settleSnackbar(tester);
  });

  testWidgets('ignores another doctor\'s consultation', (tester) async {
    final controller = put([
      booking(
        id: 'appt-elsewhere',
        status: AppointmentStatus.upcoming,
        at: DateTime(2026, 9, 3, 10),
        profileId: 'profile-2',
        userId: 'user-2',
      ),
    ]);

    final peer = await pumpAndOpen(tester, controller);

    expect(peer, isNull);
    await settleSnackbar(tester);
  });
}

class _StubAppointments extends Fake implements AppointmentRepository {
  _StubAppointments(this._appointments);

  final List<Appointment> _appointments;

  @override
  Future<List<Appointment>> list() async => _appointments;
}

/// The screen's own loading is not what these tests are about; the controller
/// only needs `details` for the photo it passes on.
class _StubDoctors extends Fake implements DoctorRepository {
  @override
  Future<DoctorDetails> getDetails(String doctorId) async => const DoctorDetails(
    doctor: Doctor(
      id: 'profile-1',
      name: 'Dr Dana Okafor',
      specialty: 'Cardiology',
      photoUrl: 'https://example.test/dana.jpg',
    ),
    experienceYears: 8,
    workingTime: 'Mon-Fri, 09:00-17:00',
    languages: ['English'],
    biography: 'Cardiologist.',
  );

  @override
  Future<DoctorAvailability> getAvailability(String doctorId) async =>
      const DoctorAvailability(
        year: 2026,
        months: [],
        selectedMonth: 'September',
        days: [],
      );
}
