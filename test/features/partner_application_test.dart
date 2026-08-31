// What "Become a Partner" actually does.
//
// Continue used to route straight into the rider or pharmacy shell for
// everybody. Those roles are granted by an admin (`partner.service.ts:6`), so
// the app was handing out a side of the platform the server had never agreed
// to, and the admin's review queue was fed by nothing. The assertion that
// matters is the negative one: applying must NOT open the shell.
import 'package:bienify_app/core/exceptions/app_exceptions.dart';
import 'package:bienify_app/core/routes/app_routes.dart';
import 'package:bienify_app/features/Role/patient/profile/domain/entities/profile.dart';
import 'package:bienify_app/features/Role/patient/profile/domain/repositories/partner_repository.dart';
import 'package:bienify_app/features/Role/patient/profile/presentation/controllers/partner_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _RecordingPartner implements PartnerRepository {
  _RecordingPartner({this.existing});

  final PartnerApplication? existing;
  final List<PartnerRole> applied = <PartnerRole>[];

  bool refuse = false;

  @override
  Future<PartnerApplication> apply({
    required PartnerRole role,
    String? motivation,
  }) async {
    if (refuse) throw ConflictException('You have already applied');
    applied.add(role);
    return PartnerApplication(
      role: role,
      status: PartnerApplicationStatus.pending,
    );
  }

  @override
  Future<PartnerApplication?> latestApplication() async => existing;
}

void main() {
  tearDown(Get.reset);

  /// Records where the app was sent instead of building the partner shells.
  Future<List<String>> mountApp(WidgetTester tester) async {
    final visited = <String>[];
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: '/',
        getPages: [
          GetPage(name: '/', page: () => const Scaffold()),
          for (final route in [AppRoutes.shopHome, AppRoutes.riderGuide])
            GetPage(
              name: route,
              page: () {
                visited.add(route);
                return const Scaffold();
              },
              transition: Transition.noTransition,
            ),
        ],
      ),
    );
    await tester.pump();
    return visited;
  }

  testWidgets('applying files an application and opens no shell', (
    tester,
  ) async {
    final visited = await mountApp(tester);
    final repository = _RecordingPartner();
    final controller = PartnerController(repository: repository);
    // `onInit` runs when GetX creates a controller; this one is constructed
    // directly, so the standing application is read explicitly.
    await controller.load();
    await tester.pumpAndSettle();

    controller.select(PartnerRole.rider);
    await controller.submitApplication();
    await tester.pumpAndSettle();

    expect(repository.applied, [PartnerRole.rider]);
    // The whole point: a courier's shell belongs to an approved courier.
    expect(visited, isEmpty);
  });

  testWidgets('the pharmacy option applies as a pharmacy owner', (
    tester,
  ) async {
    await mountApp(tester);
    final repository = _RecordingPartner();
    final controller = PartnerController(repository: repository);
    // `onInit` runs when GetX creates a controller; this one is constructed
    // directly, so the standing application is read explicitly.
    await controller.load();
    await tester.pumpAndSettle();

    controller.select(PartnerRole.pharmacyOwner);
    await controller.submitApplication();
    await tester.pumpAndSettle();

    expect(repository.applied, [PartnerRole.pharmacyOwner]);
  });

  testWidgets('an approved application opens the shell it was approved for', (
    tester,
  ) async {
    final visited = await mountApp(tester);
    final repository = _RecordingPartner(
      existing: const PartnerApplication(
        role: PartnerRole.pharmacyOwner,
        status: PartnerApplicationStatus.approved,
      ),
    );
    final controller = PartnerController(repository: repository);
    // `onInit` runs when GetX creates a controller; this one is constructed
    // directly, so the standing application is read explicitly.
    await controller.load();
    await tester.pumpAndSettle();

    await controller.submitApplication();
    await tester.pumpAndSettle();

    expect(visited, [AppRoutes.shopHome]);
    // And it does not file a second application for a role already granted.
    expect(repository.applied, isEmpty);
  });

  testWidgets('a pending application blocks a second one', (tester) async {
    await mountApp(tester);
    final repository = _RecordingPartner(
      existing: const PartnerApplication(
        role: PartnerRole.rider,
        status: PartnerApplicationStatus.pending,
      ),
    );
    final controller = PartnerController(repository: repository);
    // `onInit` runs when GetX creates a controller; this one is constructed
    // directly, so the standing application is read explicitly.
    await controller.load();
    await tester.pumpAndSettle();

    expect(controller.isPending, isTrue);
    expect(controller.isApproved, isFalse);
  });
}
