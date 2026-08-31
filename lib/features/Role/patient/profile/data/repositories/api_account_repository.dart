import 'dart:io';

import '../../../../../../core/constants/api_constants.dart';
import '../../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../../core/network/api_client.dart';
import '../../../../../../core/network/attachment_uploader.dart';
import '../../../../../../core/models/delivery_address.dart';
import '../../../../../../core/network/mappers.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/account_repository.dart';

/// The signed-in account, served by the API.
class ApiAccountRepository implements AccountRepository {
  const ApiAccountRepository(this._api, this._uploader);

  final ApiClient _api;
  final AttachmentUploader _uploader;

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
    final file = File(path);
    final issued = await _api.postMap(
      ApiConstants.postUsersMeDoorImageUploadUrl,
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
      size: await file.length(),
    );
    // No confirm call: the key is filed by the save that stores the address.
    return key;
  }

  @override
  Future<String> uploadAvatar({
    required String path,
    required String mimeType,
    void Function(double progress)? onProgress,
  }) async {
    final file = File(path);
    final size = await file.length();

    final issued = await _api.postMap(
      ApiConstants.postUsersMeAvatarUploadUrl,
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

    // Confirming is what actually moves the profile onto the new object; the
    // upload alone leaves an orphan in the bucket.
    final updated = await _api.postMap(
      ApiConstants.postUsersMeAvatarConfirm,
      body: {'key': key},
    );
    return Api.avatarOf(updated) ?? '';
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
