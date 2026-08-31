// A doctor's standing on the card the patient chooses from.
//
// Rating and patients-consulted are both derived server-side and were both
// absent before: every doctor showed 0.0 from 0 reviews, and no patient count
// existed at all. These cover the two seams between that figure and the
// screen — the mapper that reads it, and the widget that prints it.
import 'package:bienify_app/core/localization/app_translations.dart';
import 'package:bienify_app/core/network/mappers.dart';
import 'package:bienify_app/core/theme/app_theme.dart';
import 'package:bienify_app/features/Role/patient/doctors/domain/entities/doctor.dart';
import 'package:bienify_app/features/Role/patient/doctors/domain/entities/doctor_details.dart';
import 'package:bienify_app/features/Role/patient/doctors/presentation/widgets/doctor_info_grid.dart';
import 'package:bienify_app/features/Role/patient/doctors/presentation/widgets/doctor_list_card.dart';
import 'package:bienify_app/features/Role/patient/doctors/presentation/widgets/doctor_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  tearDown(Get.reset);

  Doctor doctorWith({int patientsSeen = 0, double rating = 0}) => Doctor(
    id: 'd-1',
    name: 'Dr Dana Okafor',
    specialty: 'Cardiologist',
    rating: rating,
    reviewCount: 3,
    patientsSeen: patientsSeen,
  );

  DoctorDetails detailsWith(int patientsSeen) => DoctorDetails(
    doctor: doctorWith(patientsSeen: patientsSeen),
    experienceYears: 8,
    workingTime: 'Sun-Sat, 9AM - 5PM',
    languages: const ['English'],
    biography: 'A cardiologist.',
  );

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 876),
        builder: (context, _) => GetMaterialApp(
          theme: AppTheme.light,
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    );
    await tester.pump();
  }

  group('the mapper', () {
    test('reads the patient count the server sends', () {
      final doctor = doctorFrom({
        '_id': 'd-1',
        'specialty': 'Cardiology',
        'patientsSeen': 42,
        'rating': {'average': 4.8, 'count': 6},
      });
      expect(doctor.patientsSeen, 42);
    });

    test('treats a missing count as none, not as a crash', () {
      // An older server, or a projection that leaves it out.
      final doctor = doctorFrom({'_id': 'd-1', 'specialty': 'Cardiology'});
      expect(doctor.patientsSeen, 0);
    });
  });

  group('the card', () {
    testWidgets('prints how many patients a doctor has consulted', (
      tester,
    ) async {
      await pump(tester, DoctorSummary(doctor: doctorWith(patientsSeen: 8)));
      expect(find.text('8 patients consulted'), findsOneWidget);
    });

    testWidgets('says nothing at all when a doctor has seen nobody', (
      tester,
    ) async {
      // A new doctor. "0 patients consulted" is a worse first impression than
      // an absent line, and the figure is not yet meaningful.
      await pump(tester, DoctorSummary(doctor: doctorWith(patientsSeen: 0)));
      expect(find.textContaining('patients consulted'), findsNothing);
    });

    // The list card is the one a patient actually chooses from — Home's
    // "Nearby Doctors" and the specialty list both draw it — and it showed a
    // rating with nothing behind it.
    testWidgets('the list card carries the count too, not just the rating', (
      tester,
    ) async {
      await pump(
        tester,
        DoctorListCard(doctor: doctorWith(patientsSeen: 12), onTap: () {}),
      );
      expect(find.text('12 patients consulted'), findsOneWidget);
    });

    testWidgets('the list card omits it for a doctor who has seen nobody', (
      tester,
    ) async {
      await pump(
        tester,
        DoctorListCard(doctor: doctorWith(patientsSeen: 0), onTap: () {}),
      );
      expect(find.textContaining('patients consulted'), findsNothing);
    });
  });

  // `DoctorDetails.patientCount` used to be a `String` on the constructor, and
  // the API repository passed the literal '—' with a comment claiming the
  // server did not count a doctor's patients. It does, and had done since
  // before that comment was written — so the tile captioned "Patients" showed
  // a dash on every profile in the app.
  group('the details stat tile', () {
    test('reads the figure the server sent rather than a placeholder', () {
      expect(detailsWith(42).patientCount, '42');
      expect(detailsWith(42).patientCount, isNot('—'));
    });

    test('reports zero as zero', () {
      // The grid is a fixed 2x2 of stats; a blank cell reads as broken, and
      // nobody-yet is a fact the tile can state.
      expect(detailsWith(0).patientCount, '0');
    });

    test('shortens a large figure the way the design does', () {
      expect(detailsWith(999).patientCount, '999');
      expect(detailsWith(2700).patientCount, '2.7k+');
      // A round thousand keeps no pointless '.0'.
      expect(detailsWith(3000).patientCount, '3k+');
    });

    testWidgets('and the tile prints it under the Patients caption', (
      tester,
    ) async {
      await pump(tester, DoctorInfoGrid(details: detailsWith(2700)));
      expect(find.text('2.7k+'), findsOneWidget);
      expect(find.text('—'), findsNothing);
    });
  });
}
