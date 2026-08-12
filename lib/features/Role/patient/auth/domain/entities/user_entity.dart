import 'age_range.dart';
import 'gender.dart';
import 'user_role.dart';

/// A signed-in Bienify patient, independent of any API or storage shape.
class UserEntity {
  const UserEntity({
    required this.id,
    this.name,
    this.email,
    this.phoneNumber,
    this.gender,
    this.ageRange,
    this.role = UserRole.patient,
    this.isProfileComplete = false,
  });

  final String id;
  final String? name;
  final String? email;

  /// Full E.164 number, e.g. `+27821234567`.
  final String? phoneNumber;

  final Gender? gender;
  final AgeRange? ageRange;

  /// Which shell this account lands in after signing in.
  final UserRole role;

  /// False until both profile-setup steps have been submitted.
  final bool isProfileComplete;

  UserEntity copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    Gender? gender,
    AgeRange? ageRange,
    UserRole? role,
    bool? isProfileComplete,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      gender: gender ?? this.gender,
      ageRange: ageRange ?? this.ageRange,
      role: role ?? this.role,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
    );
  }
}
