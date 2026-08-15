import '../../domain/entities/profile.dart';
import '../../domain/repositories/account_repository.dart';
import '../static/profile_mock_data.dart';

/// The account, served from the design's sample data.
class MockAccountRepository implements AccountRepository {
  const MockAccountRepository();

  @override
  Future<PatientProfile> me() async => ProfileMockData.patient;

  @override
  Future<void> saveName(String name) async {}

  @override
  Future<void> uploadAvatar({
    required List<int> bytes,
    required String fileName,
    required String contentType,
  }) async {}
}
