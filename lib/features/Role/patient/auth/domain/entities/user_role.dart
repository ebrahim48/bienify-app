/// Which section of the app a signed-in account belongs to.
///
/// The server decides this — an account is a patient, a practitioner, a shop
/// owner or a courier, and the app has a separate shell for each. Sending
/// everyone to the patient shell, as sign-in used to, left three of the four
/// unreachable except through the links that sign people up for them.
enum UserRole {
  patient('patient'),
  doctor('doctor'),
  pharmacyOwner('pharmacy_owner'),
  rider('rider'),
  admin('admin');

  const UserRole(this.value);

  /// Wire format, as `users/me.role` sends it.
  final String value;

  /// Anything unrecognised is treated as a patient: an account whose role the
  /// app does not know still has a home to land in.
  static UserRole fromValue(String? value) {
    if (value == null) return UserRole.patient;
    for (final role in UserRole.values) {
      if (role.value == value) return role;
    }
    return UserRole.patient;
  }
}
