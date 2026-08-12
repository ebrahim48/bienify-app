import '../../domain/entities/age_range.dart';
import '../../domain/entities/gender.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/user_role.dart';

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
    super.role,
    super.isProfileComplete,
  });

  /// Reads both the API's shape and this model's own.
  ///
  /// The server nests the display fields under `profile` and names its key
  /// `_id`; [toJson] writes the flat snake_case form that the local session
  /// cache is stored in. Both come back through here, so a cached session
  /// written before a sign-in still reads.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] is Map
        ? (json['profile'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};

    final name = (json['name'] ?? profile['name']) as String?;
    final gender = (json['gender'] ?? profile['gender']) as String?;

    return UserModel(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      name: name,
      email: json['email'] as String?,
      phoneNumber: (json['phone_number'] ?? json['phone']) as String?,
      gender: Gender.fromValue(gender),
      role: UserRole.fromValue(json['role'] as String?),
      ageRange: AgeRange.fromLabel(
        (json['age_range'] ?? profile['ageRange']) as String?,
      ),
      // The server has no such flag, and this decides whether a sign-in lands
      // on profile setup — so the bar is the one field the rest of the app
      // needs to render a person. Gender and age are demographic detail the
      // setup screen also collects; demanding them would send a practitioner
      // whose profile carries only a name through the patient setup flow on
      // every sign-in.
      isProfileComplete:
          json['is_profile_complete'] as bool? ??
          (name != null && name.isNotEmpty),
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
      role: entity.role,
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
    'role': role.value,
    'is_profile_complete': isProfileComplete,
  };
}
