import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/mappers.dart';
import '../../domain/entities/rider.dart';
import '../../domain/repositories/rider_repository.dart';

/// The courier, served by the API.
class ApiRiderRepository implements RiderRepository {
  const ApiRiderRepository(this._api);

  final ApiClient _api;

  static const int _pageSize = 100;

  // ─── Rider ───────────────────────────────────────────────────────────────

  @override
  Future<Rider> rider() async {
    final results = await Future.wait([
      _api.getMap(ApiConstants.usersMe),
      _api.getMap(ApiConstants.ridersMe),
      _api.getMap(ApiConstants.walletEarnings),
    ]);

    final user = results[0];
    final profile = results[1];
    final earned = results[2];

    final city = Api.str(profile['city']);

    return Rider(
      name: Api.nameOf(user, 'Rider'),
      location: city,
      todaysEarnings: Api.majorUnits(earned['todayMinor']),
      deliveriesToday: Api.integer(earned['todayCount']),
      // The server keeps no rider rating; the masthead prints a dash rather
      // than a number nobody has earned. See docs/API-GAPS.md.
      rating: 0,
      isOnline: profile['isAvailable'] == true,
      email: Api.str(user['email']),
      // A rider profile stores one free-text city and no country. Copying the
      // city into it printed "Country: Springfield" on the edit form, so the
      // field is left empty and its picker shows its own default instead.
      // See docs/API-GAPS.md.
      country: '',
      city: city,
      address: city,
      vehicleType: Api.str(profile['vehicleType'], 'motorbike'),
      licenceNumber: Api.str(profile['licenseNumber']),
      photoUrl: Api.avatarOf(user),
      phone: Api.str(user['phone']),
    );
  }

  @override
  Future<void> setOnline({required bool isOnline}) async {
    await _api.patch(
      ApiConstants.updateRidersMeAvailability,
      body: {'isAvailable': isOnline},
    );
  }

  // ─── Jobs ────────────────────────────────────────────────────────────────

  @override
  Future<List<DeliveryRequest>> requests() async {
    // Two boards make one list: what is going spare, and what this courier is
    // already carrying. The chips above the list separate them again.
    final results = await Future.wait([
      _api.getList(
        ApiConstants.deliveriesAvailable,
        query: {'limit': _pageSize},
      ),
      _api.getList(
        ApiConstants.ridersMeDeliveries,
        query: {'limit': _pageSize},
      ),
    ]);

    return [
      for (final row in results[0]) deliveryRequestFrom(row),
      for (final row in results[1]) deliveryRequestFrom(row),
    ];
  }

  @override
  Future<void> claim(String deliveryId) async {
    await _api.post(ApiConstants.postDeliveriesClaim(deliveryId));
  }

  @override
  Future<void> setStatus(
    String deliveryId,
    String status, {
    String? reason,
  }) async {
    await _api.patch(
      ApiConstants.updateDeliveriesStatus(deliveryId),
      body: {
        'status': status,
        if (reason != null && reason.isNotEmpty) 'failureReason': reason,
      },
    );
  }

  // ─── Earnings ────────────────────────────────────────────────────────────

  @override
  Future<RiderEarnings> earnings() async {
    // The courier's own jobs come along for the ride: a wallet movement knows
    // only that it was a "Delivery earning", so without them every row of the
    // history reads the same and names nobody. Its `referenceId` is the
    // delivery, which is what joins the two.
    final results = await Future.wait<dynamic>([
      _api.getMap(ApiConstants.walletEarnings),
      _api.get(ApiConstants.walletTransactions, query: {'limit': _pageSize}),
      _api.get(ApiConstants.ridersMeDeliveries, query: {'limit': _pageSize}),
    ]);

    final summary = Api.map(results[0]);

    final jobs = {
      for (final row in ApiClient.listFrom(results[2]))
        Api.id(row): deliveryRequestFrom(row),
    };

    final history = ApiClient.listFrom(results[1])
        .where((t) => Api.str(t['direction']) == 'credit')
        .map((t) => deliveryRecordFrom(t, job: jobs[Api.id(t['referenceId'])]))
        .toList();

    return RiderEarnings(
      today: Api.majorUnits(summary['todayMinor']),
      todayCount: Api.integer(summary['todayCount']),
      thisWeek: Api.majorUnits(summary['thisWeekMinor']),
      weekCount: Api.integer(summary['weekCount']),
      // The payout day is a platform policy, not a per-rider field, so it
      // stays the one the design names.
      payoutDay: 'Friday',
      payoutMinimum: Api.majorUnits(summary['minimumWithdrawalMinor']),
      history: history,
    );
  }

  // ─── Profile ─────────────────────────────────────────────────────────────

  @override
  Future<void> apply({
    required String vehicleType,
    required String licenceNumber,
    required String city,
  }) => saveProfile(
    vehicleType: vehicleType,
    licenceNumber: licenceNumber,
    city: city,
  );

  @override
  Future<void> saveProfile({
    required String vehicleType,
    required String licenceNumber,
    required String city,
  }) async {
    // `POST /riders/me` upserts, so applying and editing are the same call —
    // which is also why [apply] delegates here rather than duplicating it.
    await _api.post(
      ApiConstants.postRidersMe,
      body: {
        'vehicleType': vehicleType,
        'licenseNumber': licenceNumber,
        'city': city,
      },
    );
  }
}
