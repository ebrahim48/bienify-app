// Courier ↔ customer messaging, on both sides of it.
//
// The thread machinery is shared with consultations and covered there, so
// these cover what is specific: that each side opens a *real* thread bound to
// the delivery, and that the two conversations cannot be confused for one
// another.
import 'package:bienify_app/core/di/dependency_injection.dart';
import 'package:bienify_app/core/localization/app_translations.dart';
import 'package:bienify_app/core/models/chat_thread.dart';
import 'package:bienify_app/core/network/socket_service.dart';
import 'package:bienify_app/features/Role/patient/chat/domain/entities/conversation.dart';
import 'package:bienify_app/features/Role/rider_role/domain/entities/rider.dart';
import 'package:bienify_app/features/Role/rider_role/presentation/controllers/rider_orders_controller.dart';
import 'package:bienify_app/core/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_fonts.dart';

void main() {
  group('ChatThread', () {
    test('names a consultation and a delivery differently on the wire', () {
      expect(const ChatThread.consultation('a1').payload, {'appointmentId': 'a1'});
      expect(const ChatThread.delivery('d1').payload, {'deliveryId': 'd1'});
    });

    test('reads back the thread a server payload is about', () {
      expect(
        ChatThread.fromJson({'deliveryId': 'd1', 'messageIds': <String>[]}),
        const ChatThread.delivery('d1'),
      );
      expect(
        ChatThread.fromJson({'appointmentId': 'a1'}),
        const ChatThread.consultation('a1'),
      );
      expect(ChatThread.fromJson({'body': 'no thread here'}), isNull);
    });

    test('does not confuse two threads that share an id', () {
      // Ids come from different collections and could collide; the kind is
      // what keeps a delivery's room, receipts and filters separate.
      const consultation = ChatThread.consultation('same');
      const delivery = ChatThread.delivery('same');
      expect(consultation == delivery, isFalse);
      expect({consultation, delivery}, hasLength(2));
      expect(consultation.key, isNot(delivery.key));
    });

    test('an empty id is not a live thread', () {
      // What separates "opened from a delivery" from "opened from support",
      // which has nowhere to send.
      expect(const ChatThread.delivery('').isLive, isFalse);
      expect(const ChatThread.delivery('d1').isLive, isTrue);
    });
  });

  group('a receipt says which thread it belongs to', () {
    test('carries the delivery, not a bare id', () {
      const state = ReceiptState(
        thread: ChatThread.delivery('d1'),
        messageIds: ['m-1'],
        isRead: true,
      );
      // A client watching a consultation and a delivery at once ticks the
      // wrong bubbles without this.
      expect(state.thread, const ChatThread.delivery('d1'));
      expect(state.thread, isNot(const ChatThread.consultation('d1')));
    });
  });

  group('ConversationPeer', () {
    test('is live only once a thread is behind it', () {
      const support = ConversationPeer(id: 'u1', name: 'Support', specialty: '');
      expect(support.thread, isNull);

      const courier = ConversationPeer(
        id: 'u2',
        name: 'Ana Reyes',
        specialty: '5 Elm St',
        thread: ChatThread.delivery('d1'),
      );
      expect(courier.thread?.isLive, isTrue);
      expect(courier.thread?.isDelivery, isTrue);
    });
  });

  group("the courier's side", () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      Get.testMode = true;
      await DependencyInjection.init(useMocks: true);
    });

    tearDown(() {
      DependencyInjection.clear();
      Get.reset();
    });

    DeliveryRequest job({String id = 'd-1', String customerId = 'u-9'}) =>
        DeliveryRequest(
          id: id,
          code: 'ORD-0001',
          fee: 4,
          pickupName: 'City Pharmacy',
          customerName: 'Ana Reyes',
          customerAddress: '5 Elm St',
          customerId: customerId,
          minutes: 0,
          distanceKm: 0,
          items: 'Aspirin × 1',
          tab: RequestTab.accepted,
          status: 'in_transit',
        );

    /// `Get.toNamed` and the snackbar both need a live navigator, so the
    /// controller is exercised behind a real app rather than in isolation.
    Future<void> pump(WidgetTester tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 876),
          builder: (context, _) => GetMaterialApp(
            translations: AppTranslations(),
            locale: const Locale('en', 'US'),
            initialRoute: '/',
            getPages: [
              GetPage(name: '/', page: () => const Scaffold()),
              GetPage(
                name: AppRoutes.chat,
                page: () => const Scaffold(),
                transition: Transition.noTransition,
              ),
            ],
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('opens a thread bound to the delivery it is carrying', (
      tester,
    ) async {
      await pump(tester);
      final controller = Get.put(RiderOrdersController());
      controller.active.value = ActiveDelivery(
        request: job(),
        status: 'in_transit',
      );

      controller.openChat();
      await tester.pumpAndSettle();

      expect(Get.currentRoute, AppRoutes.chat);
      final peer = Get.arguments as ConversationPeer;
      // The delivery is the thread; the customer is the person. Passing the
      // delivery id as the peer would make the header ask presence about a
      // user that does not exist.
      expect(peer.thread, const ChatThread.delivery('d-1'));
      expect(peer.id, 'u-9');
      expect(peer.name, 'Ana Reyes');
      expect(peer.thread!.isLive, isTrue);
    });

    testWidgets('does not open a thread with no job to talk about', (
      tester,
    ) async {
      await pump(tester);
      final controller = Get.put(RiderOrdersController());
      controller.active.value = null;

      controller.openChat();
      await tester.pump();

      // It used to refuse whatever the state, saying the feature was coming;
      // now the only reason to refuse is having no delivery open — and the
      // courier is told which, rather than tapping into silence.
      expect(Get.currentRoute, isNot(AppRoutes.chat));
      expect(
        find.text('Open a delivery first to message its customer.'),
        findsOneWidget,
      );
      await settleSnackbar(tester);
    });
  });
}
