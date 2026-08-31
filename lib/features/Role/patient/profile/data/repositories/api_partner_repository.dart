import '../../../../../../core/constants/api_constants.dart';
import '../../../../../../core/network/api_client.dart';
import '../../../../../../core/network/mappers.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/partner_repository.dart';

/// Partner applications, served by the API.
class ApiPartnerRepository implements PartnerRepository {
  const ApiPartnerRepository(this._api);

  final ApiClient _api;

  @override
  Future<PartnerApplication> apply({
    required PartnerRole role,
    String? motivation,
  }) async {
    final data = await _api.postMap(
      ApiConstants.postPartnerApplications,
      body: {
        'requestedRole': _wireRole(role),
        if (motivation != null && motivation.isNotEmpty)
          'motivation': motivation,
      },
    );
    return _applicationFrom(data);
  }

  @override
  Future<PartnerApplication?> latestApplication() async {
    final rows = await _api.getList(ApiConstants.partnerApplicationsMe);
    if (rows.isEmpty) return null;
    // The server returns them newest first; the standing answer is the latest.
    return _applicationFrom(rows.first);
  }
}

/// `pharmacy_owner` / `rider` — the whole enum the server accepts.
String _wireRole(PartnerRole role) => switch (role) {
  PartnerRole.pharmacyOwner => 'pharmacy_owner',
  PartnerRole.rider => 'rider',
};

PartnerApplication _applicationFrom(Map<String, dynamic> json) =>
    PartnerApplication(
      role: Api.str(json['requestedRole']) == 'pharmacy_owner'
          ? PartnerRole.pharmacyOwner
          : PartnerRole.rider,
      status: switch (Api.str(json['status'])) {
        'approved' => PartnerApplicationStatus.approved,
        'rejected' => PartnerApplicationStatus.rejected,
        // A status this app does not know about is not an approval, and
        // treating it as one would open a shell the server has not granted.
        _ => PartnerApplicationStatus.pending,
      },
    );
