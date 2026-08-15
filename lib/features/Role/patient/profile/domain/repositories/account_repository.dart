import '../entities/profile.dart';

/// The signed-in person, whatever role they are wearing.
///
/// Separate from the auth repository, which owns the *session*: this owns the
/// account behind it, and the profile screens read it long after sign-in.
abstract class AccountRepository {
  Future<PatientProfile> me();

  Future<void> saveName(String name);

  /// Replaces the account's avatar: a presigned S3 upload, then a confirm
  /// call that points the account at the new file.
  Future<void> uploadAvatar({
    required List<int> bytes,
    required String fileName,
    required String contentType,
  });
}
