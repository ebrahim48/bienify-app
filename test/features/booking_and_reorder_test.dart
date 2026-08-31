// Phase 5: controls that pointed somewhere other than where they said.
//
// Each of these looked finished. A consultation type was chosen and thrown
// away, a shop card opened a prescription upload, and Reorder opened an empty
// basket — none of which reads as unfinished on screen, which is why they are
// asserted on what actually moved rather than on what was drawn.
import 'package:bienify_app/core/routes/app_routes.dart';
import 'package:bienify_app/features/Role/doctor_role/domain/entities/doctor_practice.dart'
    show PayoutAccount;
import 'package:bienify_app/features/Role/patient/appointments/domain/entities/appointment.dart';
import 'package:bienify_app/features/Role/patient/appointments/domain/repositories/appointment_repository.dart';
import 'package:bienify_app/features/Role/patient/appointments/presentation/controllers/appointments_controller.dart';
import 'package:bienify_app/features/Role/patient/pharmacy/domain/entities/pharmacy.dart';
import 'package:bienify_app/features/Role/patient/pharmacy/domain/repositories/pharmacy_repository.dart';
import 'package:bienify_app/features/Role/patient/pharmacy/presentation/controllers/pharmacy_cart_controller.dart';
import 'package:bienify_app/features/Role/patient/pharmacy/presentation/controllers/pharmacy_controller.dart';
import 'package:bienify_app/features/Role/patient/profile/data/repositories/mock_account_repository.dart';
import 'package:bienify_app/features/Role/patient/profile/domain/entities/profile.dart';
import 'package:bienify_app/features/Role/patient/profile/presentation/controllers/account_controller.dart';
import 'package:bienify_app/features/Role/patient/wallet/domain/repositories/wallet_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

Medicine _medicine(String id, {String pharmacyId = 'shop-1'}) => Medicine(
  id: id,
  name: 'Paracetamol $id',
  dosage: '500mg',
  price: 4.5,
  pharmacyId: pharmacyId,
);

PharmacyStore _store(String id, String name) => PharmacyStore(
  id: id,
  name: name,
  address: '1 Main St',
  distanceLabel: '0.8 km',
  rating: 4.8,
  reviewCount: 312,
  etaLabel: '25—35 min',
  price: 350,
  availableCount: 6,
  totalCount: 6,
);

class _FakePharmacy implements PharmacyRepository {
  _FakePharmacy({this.stocked = const []});

  /// What every shop is holding, keyed by nothing: the fake returns the same
  /// shelf and records which shop was asked for.
  final List<Medicine> stocked;

  final List<String?> searchedPharmacyIds = <String?>[];

  @override
  Future<List<Medicine>> searchMedicines({
    String query = '',
    String? pharmacyId,
  }) async {
    searchedPharmacyIds.add(pharmacyId);
    return stocked;
  }

  @override
  Future<List<PharmacyStore>> stores({
    String query = '',
    String city = '',
  }) async => [_store('shop-1', 'MediQuick')];

  @override
  Future<double> deliveryCharge() async => 2.5;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubWallet implements WalletRepository {
  @override
  Future<WalletSummary> summary() async => const WalletSummary(
    balance: 0,
    cards: [],
    transactions: [],
    totalSpent: 0,
    addedThisMonth: 0,
    spentOrderCount: 0,
  );

  @override
  Future<List<OrderHistoryEntry>> orders() async => const [];

  @override
  Future<List<PayoutAccount>> payoutAccounts() async => const [];

  @override
  Future<double> balance() async => 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Appointment _appointment(ConsultationType type) => Appointment(
  id: 'appt-1',
  doctorName: 'Dr Reed',
  specialty: 'Neurology',
  scheduledAt: DateTime(2026, 9, 1, 10),
  type: type,
);

void main() {
  tearDown(Get.reset);

  Future<List<String>> mountApp(WidgetTester tester) async {
    final visited = <String>[];
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: '/',
        getPages: [
          GetPage(name: '/', page: () => const Scaffold()),
          for (final route in [
            AppRoutes.videoCall,
            AppRoutes.chat,
            AppRoutes.pharmacyCart,
          ])
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

  group('joining a consultation', () {
    testWidgets('a video booking opens the call', (tester) async {
      final visited = await mountApp(tester);
      final controller = AppointmentsController(
        repository: _StubAppointments(),
      );

      controller.join(_appointment(ConsultationType.video));
      await tester.pumpAndSettle();

      expect(visited, [AppRoutes.videoCall]);
    });

    testWidgets('a chat booking opens the thread, not a video call', (
      tester,
    ) async {
      // Every appointment opened the video screen, because every booking was
      // sent as `video` whatever the patient picked.
      final visited = await mountApp(tester);
      final controller = AppointmentsController(
        repository: _StubAppointments(),
      );

      controller.join(_appointment(ConsultationType.chat));
      await tester.pumpAndSettle();

      expect(visited, [AppRoutes.chat]);
    });

    testWidgets('an in-person visit opens nothing', (tester) async {
      // It happens at the clinic. A "Join" that dialled a video call for it
      // would be a control doing something other than what it says.
      final visited = await mountApp(tester);
      final controller = AppointmentsController(
        repository: _StubAppointments(),
      );

      controller.join(_appointment(ConsultationType.inPerson));
      await tester.pumpAndSettle();

      expect(visited, isEmpty);
    });
  });

  group('tapping a shop', () {
    testWidgets('shows that shop\'s shelf rather than the upload screen', (
      tester,
    ) async {
      await mountApp(tester);
      final pharmacy = _FakePharmacy(stocked: [_medicine('m1')]);
      Get.put(
        PharmacyCartController(
          pharmacy: pharmacy,
          wallet: _StubWallet(),
          account: MockAccountRepository(),
        ),
      );
      final controller = PharmacyController(
        repository: pharmacy,
        account: MockAccountRepository(),
      );
      await controller.load();
      pharmacy.searchedPharmacyIds.clear();

      await controller.openStore(_store('shop-7', 'CityCare'));
      await tester.pumpAndSettle();

      expect(controller.viewingStore.value?.id, 'shop-7');
      expect(pharmacy.searchedPharmacyIds, contains('shop-7'));
    });

    testWidgets('clearing goes back to the whole catalogue', (tester) async {
      await mountApp(tester);
      final pharmacy = _FakePharmacy(stocked: [_medicine('m1')]);
      Get.put(
        PharmacyCartController(
          pharmacy: pharmacy,
          wallet: _StubWallet(),
          account: MockAccountRepository(),
        ),
      );
      final controller = PharmacyController(
        repository: pharmacy,
        account: MockAccountRepository(),
      );
      await controller.load();
      await controller.openStore(_store('shop-7', 'CityCare'));
      pharmacy.searchedPharmacyIds.clear();

      await controller.clearStore();
      await tester.pumpAndSettle();

      expect(controller.viewingStore.value, isNull);
      expect(pharmacy.searchedPharmacyIds, contains(null));
    });
  });

  group('reordering', () {
    OrderHistoryEntry order(Map<String, int> quantities) => OrderHistoryEntry(
      id: 'order-1',
      reference: '#ORDER1',
      storeName: 'MediQuick',
      pharmacyId: 'shop-1',
      placedOn: DateTime(2026, 8, 1),
      itemCount: quantities.values.fold(0, (a, b) => a + b),
      total: 20,
      state: OrderState.delivered,
      quantitiesByMedicineId: quantities,
    );

    testWidgets('puts the previous order back in the basket', (tester) async {
      // It opened an empty cart, so "Reorder" ordered nothing: the patient had
      // to remember what they had bought and find each medicine again.
      final visited = await mountApp(tester);
      final pharmacy = _FakePharmacy(
        stocked: [_medicine('m1'), _medicine('m2')],
      );
      final cart = Get.put(
        PharmacyCartController(
          pharmacy: pharmacy,
          wallet: _StubWallet(),
          account: MockAccountRepository(),
        ),
      );
      final account = AccountController(
        repository: _StubWallet(),
        pharmacy: pharmacy,
      );

      await account.reorder(order({'m1': 2, 'm2': 1}));
      await tester.pumpAndSettle();

      expect(cart.lines, hasLength(2));
      expect(
        cart.lines.firstWhere((l) => l.medicine.id == 'm1').quantity,
        2,
      );
      expect(visited, contains(AppRoutes.pharmacyCart));
    });

    testWidgets('drops what the shop no longer stocks', (tester) async {
      await mountApp(tester);
      // Only m1 is still on the shelf.
      final pharmacy = _FakePharmacy(stocked: [_medicine('m1')]);
      final cart = Get.put(
        PharmacyCartController(
          pharmacy: pharmacy,
          wallet: _StubWallet(),
          account: MockAccountRepository(),
        ),
      );
      final account = AccountController(
        repository: _StubWallet(),
        pharmacy: pharmacy,
      );

      await account.reorder(order({'m1': 1, 'gone': 3}));
      await tester.pumpAndSettle();

      // Added rather than refused: a line the checkout would reject is worse
      // than a short basket the patient can see.
      expect(cart.lines, hasLength(1));
      expect(cart.lines.single.medicine.id, 'm1');
    });

    testWidgets('an order with nothing left opens no basket', (tester) async {
      final visited = await mountApp(tester);
      final pharmacy = _FakePharmacy(stocked: const []);
      Get.put(
        PharmacyCartController(
          pharmacy: pharmacy,
          wallet: _StubWallet(),
          account: MockAccountRepository(),
        ),
      );
      final account = AccountController(
        repository: _StubWallet(),
        pharmacy: pharmacy,
      );

      await account.reorder(order({'gone': 1}));
      await tester.pumpAndSettle();

      // An empty basket would look like the reorder silently failed.
      expect(visited, isEmpty);
    });
  });
}

/// `join` reads nothing from the repository; this exists only so the
/// controller can be built without a registered one.
class _StubAppointments implements AppointmentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
