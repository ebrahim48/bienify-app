import '../../../../core/constants/app_strings.dart';

/// Gender options offered on the profile-setup screen.
enum Gender {
  male('male', AppStrings.male),
  female('female', AppStrings.female);

  const Gender(this.value, this.labelKey);

  /// Wire format sent to and received from the API.
  final String value;

  /// Translation key for the visible label.
  final String labelKey;

  static Gender? fromValue(String? value) {
    if (value == null) return null;
    for (final gender in Gender.values) {
      if (gender.value == value) return gender;
    }
    return null;
  }
}
