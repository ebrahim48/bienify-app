import '../../../../../../core/models/delivery_address.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/account_repository.dart';
import '../static/profile_mock_data.dart';

/// The account, served from the design's sample data.
class MockAccountRepository implements AccountRepository {
  MockAccountRepository();

  @override
  Future<PatientProfile> me() async => ProfileMockData.patient;

  @override
  Future<void> saveName(String name) async {}

  /// Held in memory so the mock behaves like the real thing across a
  /// checkout: save an address, reopen the dialog, and it is still there.
  ///
  /// Per instance, not static — two mock repositories are two accounts, and a
  /// static field would carry one test's address into the next.
  DeliveryAddress? _address;

  @override
  Future<DeliveryAddress?> savedAddress() async => _address;

  @override
  Future<void> saveAddress(DeliveryAddress? address) async {
    _address = address;
  }

  @override
  Future<String> uploadDoorImage({
    required String path,
    required String mimeType,
  }) async => path;

  @override
  Future<String> uploadAvatar({
    required String path,
    required String mimeType,
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(1);
    return path;
  }
}