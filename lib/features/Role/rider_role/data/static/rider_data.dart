import 'package:get/get.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../domain/entities/rider.dart';

/// Sample data behind the courier's section.
///
/// Static by design — this role is UI-first, so there is no repository or API
/// here; these shapes are what an endpoint will fill in.
class RiderData {
  RiderData._();

  static const Rider rider = Rider(
    name: 'Rider Arif',
    location: 'Los Angels, USA',
    todaysEarnings: 21.75,
    deliveriesToday: 4,
    rating: 4.9,
    isOnline: true,
    email: 'alex@gmail.com',
    country: 'Cameron',
    city: 'Cameron',
    address: 'Cameron',
  );

  /// The masthead on the dashboard carries the shop's name in the design;
  /// the guide carries the courier's.
  static const String dashboardName = 'Aid Plus+';

  /// The name the application form greets, which is the courier's first.
  static const String firstName = 'Arif';

  /// Shown on the Profile tab.
  static const String profileName = 'Mohammod Jakuan';
  static const String profilePhone = '+880 189* ****';

  // ─── Guide ───────────────────────────────────────────────────────────────

  /// Built rather than `const`, because every line is a translation key.
  static List<GuideStep> guideSteps() => [
    GuideStep(
      title: AppStrings.stepSignUp.tr,
      body: AppStrings.stepSignUpBody.tr,
      note: AppStrings.stepSignUpNote.tr,
    ),
    GuideStep(
      title: AppStrings.stepGetOrders.tr,
      body: AppStrings.stepGetOrdersBody.tr,
      note: AppStrings.stepGetOrdersNote.tr,
    ),
    GuideStep(
      title: AppStrings.stepPickDeliver.tr,
      body: AppStrings.stepPickDeliverBody.tr,
      note: AppStrings.stepPickDeliverNote.tr,
    ),
    GuideStep(
      title: AppStrings.stepEarnMoney.tr,
      body: AppStrings.stepEarnMoneyBody.tr,
      note: AppStrings.stepEarnMoneyNote.tr,
    ),
    GuideStep(
      title: AppStrings.stepBuildRating.tr,
      body: AppStrings.stepBuildRatingBody.tr,
      note: AppStrings.stepBuildRatingNote.tr,
    ),
  ];

  // ─── Application ─────────────────────────────────────────────────────────

  static const List<String> countries = [
    'Cameron',
    'Nigeria',
    'Kenya',
    'Ghana',
    'South Africa',
  ];

  static const List<String> cities = [
    'Cameron',
    'Douala',
    'Yaoundé',
    'Bamenda',
  ];

  static const List<String> zones = ['Cameron', 'Downtown', 'Airport', 'Port'];

  /// The zones already picked, drawn as chips under the dropdown.
  static const List<String> pickedZones = ['lester city', 'jamaica', 'rome'];

  // ─── Requests ────────────────────────────────────────────────────────────

  static List<DeliveryRequest> requests() => [
    for (final tab in RequestTab.values)
      // Three in each state: the design counts "3 new" beside the heading
      // and the dashboard's quick action repeats it.
      for (var index = 0; index < 3; index++)
        DeliveryRequest(
          id: '${tab.name}-$index',
          code: 'ORD-4821',
          fee: 4.5,
          pickupName: 'MedPlus Pharmacy',
          customerName: 'Sarah Johnson',
          customerAddress: '14 Maple Street, Apt 3B',
          minutes: 12,
          distanceKm: 1.2,
          items: 'Insulin pens × 2, Syringes × 10',
          tab: tab,
        ),
  ];

  // ─── Deliveries ──────────────────────────────────────────────────────────

  static const List<DeliveryRecord> recentDeliveries = [
    DeliveryRecord(
      customerName: 'Tom Chen',
      initials: 'TC',
      whenLabel: 'Today, 10:42 AM',
      fee: 5,
      orderCode: 'ORD-4819',
    ),
    DeliveryRecord(
      customerName: 'Maria Santos',
      initials: 'MS',
      whenLabel: 'Today, 09:15 AM',
      fee: 4.5,
      orderCode: 'ORD-4817',
    ),
    DeliveryRecord(
      customerName: 'David Kim',
      initials: 'DK',
      whenLabel: 'Yesterday, 3:30 PM',
      fee: 6.75,
      orderCode: 'ORD-4810',
    ),
  ];

  static const RiderEarnings earnings = RiderEarnings(
    today: 21.5,
    todayCount: 4,
    thisWeek: 87.5,
    weekCount: 19,
    payoutDay: 'Friday',
    payoutMinimum: 50,
    history: [
      ...recentDeliveries,
      DeliveryRecord(
        customerName: 'Linda Park',
        initials: 'LP',
        whenLabel: 'Yesterday, 11:00 AM',
        fee: 5.25,
        orderCode: 'ORD-4805',
      ),
    ],
  );

  // ─── The live job ────────────────────────────────────────────────────────

  static ActiveDelivery activeDelivery() => activeDeliveryFor(requests().first);

  /// The map's own figures — the road, the arrival window, how many turns are
  /// left — come from a routing service the app does not have, so they stay
  /// the design's. [request] is the real job they are wrapped around.
  static ActiveDelivery activeDeliveryFor(DeliveryRequest request) =>
      ActiveDelivery(
        roadName: 'Los Angels road',
        arrivingAtLabel: '2:52 PM',
        latestArrivalLabel: '3:15 PM',
        stepsLeft: 3,
        minutesAway: 15,
        request: request,
        note: AppStrings.customerNote.tr,
        unreadMessages: 1,
      );

  static const DeliveryReceipt receipt = DeliveryReceipt(
    orderId: '#45892',
    customerName: 'John Doe',
    location: 'Banani, Dhaka',
    timeLabel: '4:32 PM',
  );

  /// How many requests are waiting, printed on the dashboard's quick action
  /// and beside the Order Requests heading.
  static int get openRequests =>
      requests().where((r) => r.tab == RequestTab.fresh).length;
}
