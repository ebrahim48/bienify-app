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
    // Country, city and address all read 'Cameron' here, so the demo's Edit
    // Profile showed the same word in four fields. Aligned with the courier
    // the backend seeds, so mock mode and a live session look like the same
    // product.
    country: 'Dominican Republic',
    city: 'Springfield',
    address: '18 Calle Duarte',
  );

  /// The masthead on the dashboard carries the shop's name in the design;
  /// the guide carries the courier's.
  static const String dashboardName = 'Aid Plus+';

  /// The name the application form greets, which is the courier's first.
  static const String firstName = 'Arif';

  /// What the Profile tab falls back to before the courier has loaded. The
  /// card prints the signed-in courier once it has.
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

  /// Where Bienify operates. "Cameron" headed both this list and the cities
  /// one — a misspelling of Cameroon used as a city as well as a country.
  static const List<String> countries = [
    'Dominican Republic',
    'Haiti',
    'Puerto Rico',
  ];

  static const List<String> cities = [
    'Springfield',
    'Santo Domingo',
    'Santiago',
    'La Romana',
    'Puerto Plata',
  ];

  /// The delivery zones a courier can choose to cover.
  static const List<String> zones = [
    'Downtown',
    'Airport',
    'Port',
    'lester city',
    'jamaica',
    'rome',
  ];

  /// `pickedZones` used to live here — three zones drawn as chips under the
  /// dropdown before the courier had chosen anything, so the step opened
  /// already answered on somebody else's behalf. Which zones a courier covers
  /// is their decision, so they start with none.

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
    // Empty, as the API path is: the platform has no payout schedule, so the
    // chip is omitted rather than naming a day nothing computes. A fixture
    // that says otherwise makes a golden documenting a screen no courier sees.
    payoutDay: '',
    payoutMinimum: 50,
    // Enough in the wallet to withdraw, so the golden shows the button in the
    // state a courier who has cleared the minimum actually sees.
    available: 87.5,
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

  /// [request] is the real job; the status is what the step bar reads.
  static ActiveDelivery activeDeliveryFor(
    DeliveryRequest request, {
    String status = 'assigned',
  }) => ActiveDelivery(request: request, status: status);

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
