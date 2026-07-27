import '../../domain/entities/age_range.dart';
import '../../domain/entities/gender.dart';
import '../../domain/entities/user_entity.dart';

/// Serialisation layer for [UserEntity].
///
/// Keeping JSON out of the entity means a backend field rename never reaches
/// the domain or the UI.
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    super.name,
    super.email,
    super.phoneNumber,
    super.gender,
    super.ageRange,
    super.isProfileComplete,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String?,
      email: json['email'] as String?,
      phoneNumber: json['phone_number'] as String?,
      gender: Gender.fromValue(json['gender'] as String?),
      ageRange: AgeRange.fromLabel(json['age_range'] as String?),
      isProfileComplete: json['is_profile_complete'] as bool? ?? false,
    );
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      phoneNumber: entity.phoneNumber,
      gender: entity.gender,
      ageRange: entity.ageRange,
      isProfileComplete: entity.isProfileComplete,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone_number': phoneNumber,
    'gender': gender?.value,
    'age_range': ageRange?.label,
    'is_profile_complete': isProfileComplete,
  };
}
