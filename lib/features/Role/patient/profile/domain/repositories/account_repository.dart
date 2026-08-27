import '../../../../../../core/models/delivery_address.dart';
import '../entities/profile.dart';

/// The signed-in person, whatever role they are wearing.
///
/// Separate from the auth repository, which owns the *session*: this owns the
/// account behind it, and the profile screens read it long after sign-in.
abstract class AccountRepository {
  Future<PatientProfile> me();

  Future<void> saveName(String name);

  /// The patient's one saved delivery address, or null if they have never
  /// entered one. Read at checkout so an order does not ask again.
  Future<DeliveryAddress?> savedAddress();

  /// Saves it against the account. Passing null clears it.
  Future<void> saveAddress(DeliveryAddress? address);

  /// Uploads a photo of the patient's door and returns the storage key, which
  /// belongs to the address rather than being confirmed on its own: the key
  /// is filed by the same save that stores the address it describes.
  Future<String> uploadDoorImage({
    required String path,
    required String mimeType,
  });

  /// Replaces the account photo.
  ///
  /// Two calls behind one method: the server signs a key under this account's
  /// own prefix, the bytes go straight to storage, and only a confirm call
  /// points the profile at them. Both endpoints have existed since the user
  /// module was written and nothing ever called either — every avatar in the
  /// app was whatever the seed put there.
  Future<String> uploadAvatar({
    required String path,
    required String mimeType,
    void Function(double progress)? onProgress,
  });
}
