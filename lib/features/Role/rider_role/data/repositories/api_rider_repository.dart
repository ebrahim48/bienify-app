import '../../../doctor_role/domain/entities/doctor_practice.dart'
    show PayoutAccount;
import '../../../patient/pharmacy/domain/entities/pharmacy.dart';
import 'dart:io';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/attachment_uploader.dart';
import '../../../../../core/network/mappers.dart';
import '../../domain/entities/rider.dart';
import '../../domain/repositories/rider_repository.dart';

/// The courier, served by the API.
class ApiRiderRepository implements RiderRepository {
  const ApiRiderRepository(this._api, this._uploader);

  final ApiClient _api;
  final AttachmentUploader _uploader;

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
      // Their own standing, from reviews customers wrote on deliveries they
      // completed. `GET /riders/me` was not returning it, so the masthead
      // printed a dash where a real figure had always been computable.
      rating: Api.decimal(Api.map(profile['rating'])['average']),
      reviewCount: Api.integer(Api.map(profile['rating'])['count']),
      deliveriesCompleted: Api.integer(profile['deliveriesCompleted']),
      isOnline: profile['isAvailable'] == true,
      email: Api.str(user['email']),
      // The profile carries these now. It held only a city before, so the
      // country was blanked and the address printed the city back — and
      // whatever the courier typed on the edit form was discarded on save.
      country: Api.str(profile['country']),
      city: city,
      address: Api.str(profile['addressLine']),
      zones: (profile['zones'] is List)
          ? (profile['zones'] as List).map(Api.str).toList()
          : const <String>[],
      shareLiveLocation: profile['shareLiveLocation'] != false,
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
      _api.get(ApiConstants.walletWithdrawals, query: {'limit': _pageSize}),
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
      // Empty, so the chip is omitted. This read `'Friday'` from a constant:
      // there is no payout schedule on the platform — an admin approves each
      // withdrawal by hand — so a courier was being told money arrived on a
      // day nothing computed and nobody guaranteed.
      payoutDay: '',
      payoutMinimum: Api.majorUnits(summary['minimumWithdrawalMinor']),
      history: history,
      // What a payout is actually drawn from, and what is already spoken for.
      available: Api.majorUnits(summary['availableMinor']),
      pendingWithdrawal: Api.majorUnits(summary['pendingWithdrawalMinor']),
      withdrawals: ApiClient.listFrom(results[3])
          .map(withdrawalRequestFrom)
          .toList(),
    );
  }

  // ─── Payout ──────────────────────────────────────────────────────────────

  @override
  Future<List<PayoutAccount>> payoutAccounts() async {
    final rows = await _api.getList(ApiConstants.walletPayoutAccounts);
    return rows.map(payoutAccountFrom).toList();
  }

  @override
  Future<void> addPayoutAccount({
    required String kind,
    required String displayName,
    required String accountNumber,
    String? bankName,
  }) async {
    await _api.post(
      ApiConstants.postWalletPayoutAccounts,
      body: {
        'kind': kind,
        'displayName': displayName,
        'accountNumber': accountNumber,
        if (bankName != null && bankName.isNotEmpty) 'bankName': bankName,
      },
    );
  }

  @override
  Future<void> makePayoutAccountDefault(String accountId) async {
    await _api.patch(
      ApiConstants.updateWalletPayoutAccountsDefault(accountId),
    );
  }

  @override
  Future<void> requestWithdrawal({
    required double amount,
    required String payoutAccountId,
  }) async {
    await _api.post(
      ApiConstants.postWalletWithdrawals,
      body: {
        // Money crosses the wire in minor units so no arithmetic happens in
        // floating point on the way.
        'amountMinor': (amount * 100).round(),
        'payoutAccountId': payoutAccountId,
      },
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
    String? name,
    String? country,
    String? addressLine,
    List<String>? zones,
    bool? shareLiveLocation,
  }) async {
    // The name lives on the account, not the courier profile, so it takes a
    // different endpoint. The edit screen offered the field and nothing ever
    // sent it anywhere.
    if (name != null && name.trim().isNotEmpty) {
      await _api.patch(ApiConstants.updateUsersMe, body: {'name': name.trim()});
    }

    // `POST /riders/me` upserts, so applying and editing are the same call —
    // which is also why [apply] delegates here rather than duplicating it.
    await _api.post(
      ApiConstants.postRidersMe,
      body: {
        'vehicleType': vehicleType,
        'licenseNumber': licenceNumber,
        'city': city,
        // Omitted rather than sent empty: the upsert only overwrites what it
        // is given, so the application flow posting without these leaves what
        // the courier already saved alone.
        if (country != null && country.isNotEmpty) 'country': country,
        if (addressLine != null && addressLine.isNotEmpty)
          'addressLine': addressLine,
        'zones': ?zones,
        'shareLiveLocation': ?shareLiveLocation,
      },
    );
  }

  @override
  Future<void> uploadDocument({
    required String kind,
    required String path,
    required String mimeType,
    void Function(double progress)? onProgress,
  }) async {
    final file = File(path);
    final size = await file.length();

    final issued = await _api.postMap(
      ApiConstants.postRidersMeDocumentsUploadUrl,
      body: {'contentType': mimeType},
    );
    final url = '${issued['url'] ?? ''}';
    final key = '${issued['key'] ?? ''}';
    if (url.isEmpty || key.isEmpty) {
      throw UnknownException('The server did not issue an upload location');
    }

    await _uploader.putBytes(
      url: url,
      file: file,
      mime: mimeType,
      size: size,
      onProgress: onProgress,
    );

    await _api.post(
      ApiConstants.postRidersMeDocuments,
      body: {'kind': kind, 's3Key': key},
    );
  }

  @override
  Future<DeliveryRoute> route(String deliveryId) async {
    final json = await _api.getMap(ApiConstants.deliveriesLocation(deliveryId));
    return deliveryRouteFrom(json);
  }

  @override
  Future<void> reportLocation(String deliveryId, double lat, double lng) async {
    await _api.patch(
      ApiConstants.updateDeliveriesLocation(deliveryId),
      body: {'lat': lat, 'lng': lng},
    );
  }
}