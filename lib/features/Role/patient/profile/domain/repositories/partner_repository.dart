import '../entities/profile.dart';

/// Where a patient asks to become a courier or a pharmacy owner.
///
/// Both roles are granted by an admin, never by the app: the screen used to
/// navigate straight into the rider or pharmacy shell, which handed out a role
/// the server had not agreed to and left the admin's review queue empty.
abstract class PartnerRepository {
  /// `POST /partner-applications`.
  Future<PartnerApplication> apply({
    required PartnerRole role,
    String? motivation,
  });

  /// The caller's most recent application, or null if they have never applied.
  Future<PartnerApplication?> latestApplication();
}

/// How far an application has got.
enum PartnerApplicationStatus { pending, approved, rejected }

class PartnerApplication {
  const PartnerApplication({required this.role, required this.status});

  final PartnerRole role;
  final PartnerApplicationStatus status;

  /// Only an approved application opens the partner's side of the app.
  bool get isApproved => status == PartnerApplicationStatus.approved;
}
