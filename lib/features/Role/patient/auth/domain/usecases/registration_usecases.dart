import '../entities/age_range.dart';
import '../entities/auth_session.dart';
import '../entities/gender.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Profile-setup step 1 — name, gender and age bracket.
class SaveProfileDetails {
  const SaveProfileDetails(this._repository);

  final AuthRepository _repository;

  Future<UserEntity> call({
    required String name,
    required Gender gender,
    required AgeRange ageRange,
  }) => _repository.saveProfileDetails(
    name: name,
    gender: gender,
    ageRange: ageRange,
  );
}

/// Profile-setup step 2 — name, email and password; this is what actually
/// creates the account.
class SaveCredentials {
  const SaveCredentials(this._repository);

  final AuthRepository _repository;

  Future<AuthSession> call({
    required String name,
    required String email,
    required String password,
  }) => _repository.saveCredentials(name: name, email: email, password: password);
}
