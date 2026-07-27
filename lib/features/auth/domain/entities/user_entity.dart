import 'age_range.dart';
import 'gender.dart';

/// A signed-in Bienify patient, independent of any API or storage shape.
class UserEntity {
  const UserEntity({
    required this.id,
    this.name,
    this.email,
    this.phoneNumber,
    this.gender,
    this.ageRange,
    this.isProfileComplete = false,
  });

  final String id;
  final String? name;
  final String? email;

  /// Full E.164 number, e.g. `+27821234567`.
  final String? phoneNumber;

  final Gender? gender;
  final AgeRange? ageRange;

  /// False until both profile-setup steps have been submitted.
  final bool isProfileComplete;

  UserEntity copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    Gender? gender,
    AgeRange? ageRange,
    bool? isProfileComplete,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      gender: gender ?? this.gender,
      ageRange: ageRange ?? this.ageRange,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
    );
  }
}
