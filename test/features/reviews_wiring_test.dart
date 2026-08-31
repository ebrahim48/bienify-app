// Where the stars actually go.
//
// Both review screens showed the real `ReviewDialog`, took the rating, and
// navigated away without calling `POST /reviews`. Every rider and pharmacy
// rating a patient gave was discarded at the moment they gave it, so these
// tests assert on what reached the repository rather than on what the screen
// did afterwards.
//
// The two are keyed differently on purpose: a pharmacy review names the
// **order**, a rider review names the **delivery** (`review.service.ts:55`
// resolves the courier from it, and an order id there is simply not found).
import 'package:bienify_app/core/exceptions/app_exceptions.dart';
import 'package:bienify_app/features/Role/patient/pharmacy/domain/repositories/pharmacy_repository.dart';
import 'package:bienify_app/features/Role/patient/pharmacy/presentation/controllers/delivery_feedback_controller.dart';
import 'package:bienify_app/features/Role/patient/profile/domain/entities/profile.dart';
import 'package:bienify_app/features/Role/patient/profile/presentation/controllers/account_controller.dart';
import 'package:bienify_app/features/Role/patient/wallet/domain/repositories/wallet_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _RecordingPharmacy implements PharmacyRepository {
  final List<Map<String, Object>> filed = <Map<String, Object>>[];

  /// Set to answer the way the server does for a repeat review, or one the
  /// order is not finished enough for.
  bool refuse = false;

  @override
  Future<void> reviewPharmacy({
    required String orderId,
    required int rating,
  }) async {
    if (refuse) throw ConflictException('You have already reviewed this');
    filed.add({'kind': 'pharmacy', 'id': orderId, 'rating': rating});
  }

  @override
  Future<void> reviewRider({
    required String deliveryId,
    required int rating,
  }) async {
    if (refuse) throw ConflictException('You have already reviewed this');
    filed.add({'kind': 'rider', 'id': deliveryId, 'rating': rating});
  }

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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

OrderHistoryEntry _order(String id) => OrderHistoryEntry(
  id: id,
  reference: '#$id',
  storeName: 'Demo Pharmacy',
  placedOn: DateTime(2026, 8, 1),
  total: 20,
  itemCount: 2,
  state: OrderState.delivered,
  pharmacyId: 'pharmacy-1',
);

void main() {
  late _RecordingPharmacy pharmacy;

  setUp(() => pharmacy = _RecordingPharmacy());

  tearDown(Get.reset);

  /// Both controllers report through `AppSnackbar`, which needs a navigator.
  Future<void> mountApp(WidgetTester tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: Scaffold()));
    await tester.pump();
  }

  group('pharmacy review', () {
    testWidgets('files the rating against the order that was reviewed', (
      tester,
    ) async {
      await mountApp(tester);
      final account = AccountController(
        repository: _StubWallet(),
        pharmacy: pharmacy,
      );

      final ok = await account.submitShopReview(_order('order-42'), 4);
      await tester.pumpAndSettle();

      expect(ok, isTrue);
      expect(pharmacy.filed, hasLength(1));
      expect(pharmacy.filed.single['kind'], 'pharmacy');
      expect(pharmacy.filed.single['id'], 'order-42');
      expect(pharmacy.filed.single['rating'], 4);
    });

    testWidgets('a refusal is reported rather than swallowed', (tester) async {
      await mountApp(tester);
      pharmacy.refuse = true;
      final account = AccountController(
        repository: _StubWallet(),
        pharmacy: pharmacy,
      );

      final ok = await account.submitShopReview(_order('order-42'), 4);
      await tester.pumpAndSettle();

      // False keeps the screen open, which is what stops it claiming a review
      // the server rejected.
      expect(ok, isFalse);
      expect(pharmacy.filed, isEmpty);
    });
  });

  group('rider review', () {
    testWidgets('files the rating against the delivery, not the order', (
      tester,
    ) async {
      await mountApp(tester);
      final feedback = DeliveryFeedbackController(
        deliveryId: 'delivery-7',
        repository: pharmacy,
      );

      final ok = await feedback.submitRiderReview(5);
      await tester.pumpAndSettle();

      expect(ok, isTrue);
      expect(pharmacy.filed.single['kind'], 'rider');
      expect(pharmacy.filed.single['id'], 'delivery-7');
      expect(pharmacy.filed.single['rating'], 5);
    });

    testWidgets('an order that was never dispatched files nothing', (
      tester,
    ) async {
      await mountApp(tester);
      final feedback = DeliveryFeedbackController(
        deliveryId: null,
        repository: pharmacy,
      );

      expect(feedback.canReview, isFalse);
      expect(await feedback.submitRiderReview(5), isFalse);
      expect(pharmacy.filed, isEmpty);
    });
  });
}
