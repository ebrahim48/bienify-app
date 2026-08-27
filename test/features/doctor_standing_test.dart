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
  });
}
