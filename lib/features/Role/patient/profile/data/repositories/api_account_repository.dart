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
