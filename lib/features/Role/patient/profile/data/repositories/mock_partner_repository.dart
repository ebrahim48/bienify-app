import '../../domain/entities/profile.dart';
import '../../domain/repositories/partner_repository.dart';

/// An offline application desk: it remembers what was filed this run, so the
/// screen shows "pending" afterwards the way the live one does.
class MockPartnerRepository implements PartnerRepository {
  PartnerApplication? _filed;

  @override
  Future<PartnerApplication> apply({
    required PartnerRole role,
    String? motivation,
  }) async {
    // Pending, not approved: an application the app grants itself is the bug
    // this repository exists to stop being possible.
    final application = PartnerApplication(
      role: role,
      status: PartnerApplicationStatus.pending,
    );
    _filed = application;
    return application;
  }

  @override
  Future<PartnerApplication?> latestApplication() async => _filed;
}
