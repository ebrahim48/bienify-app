import 'package:dio/dio.dart';

import '../../../../../../core/constants/api_constants.dart';
import '../../../../../../core/network/api_client.dart';
import '../../../../../../core/network/mappers.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/account_repository.dart';

/// The signed-in account, served by the API.
class ApiAccountRepository implements AccountRepository {
  const ApiAccountRepository(this._api);

  final ApiClient _api;

  @override
  Future<PatientProfile> me() async {
    final data = await _api.getMap(ApiConstants.usersMe);
    return PatientProfile(
      name: Api.nameOf(data, 'You'),
      maskedPhone: maskPhone(Api.str(data['phone'])),
      photoUrl: Api.avatarOf(data),
    );
  }

  @override
  Future<void> saveName(String name) async {
    await _api.patch(ApiConstants.updateUsersMe, body: {'name': name});
  }

  @override

  Future<void> uploadAvatar({
    required List<int> bytes,
    required String fileName,
    required String contentType,

  Future<void> deleteAccount() async {
    await _api.delete(ApiConstants.deleteUsersMe);
  }

  @override
  Future<DeliveryAddress?> savedAddress() async {
    final data = await _api.getMap(ApiConstants.usersMe);
    return addressFrom(Api.map(data['profile'])['address']);
  }

  @override
  Future<void> saveAddress(DeliveryAddress? address) async {
    // Explicit null clears it. Omitting the key would leave the old address
    // in place, which is not what clearing means.
    await _api.patch(
      ApiConstants.updateUsersMe,
      body: {'address': address?.toJson()},
    );
  }

  @override
  Future<String> uploadDoorImage({
    required String path,
    required String mimeType,

  }) async {
    final uploadUrl = await _api.postMap(
      ApiConstants.postUsersMeAvatarUploadUrl,
      body: {'contentType': contentType},
    );
    final url = Api.str(uploadUrl['url']);
    final key = Api.str(uploadUrl['key']);

    // A raw PUT, not through [_api]: same reasoning as the vault upload —
    // the presigned URL is its own auth, and its response isn't the app's
    // envelope.
    await Dio().put<void>(
      url,
      data: Stream.fromIterable([bytes]),
      options: Options(
        headers: {
          Headers.contentLengthHeader: bytes.length,
          'Content-Type': contentType,
        },
      ),
    );

    await _api.post(ApiConstants.postUsersMeAvatarConfirm, body: {'key': key});
  }
}

/// `+15550000001` → `+1 555* ****`.
///
/// The design shows a partly hidden number, and the digits it hides are the
/// ones that identify the line — so the country code and the next few stay and
/// the rest goes.
String maskPhone(String phone) {
  if (phone.isEmpty) return '';
  if (phone.length <= 5) return phone;
  final head = phone.substring(0, phone.length - 7 < 5 ? 5 : phone.length - 7);
  return '$head* ****';
}
