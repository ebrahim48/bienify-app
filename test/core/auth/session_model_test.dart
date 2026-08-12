import 'package:bienify_app/features/Role/patient/auth/data/models/auth_session_model.dart';
import 'package:bienify_app/features/Role/patient/auth/data/models/user_model.dart';
import 'package:bienify_app/features/Role/patient/auth/domain/entities/gender.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins the shape of a signed-in session against what the server actually
/// sends.
///
/// The failure this guards against is silent and total: the model used to read
/// `access_token` while the server answers `accessToken`, so every sign-in
/// produced a session with an empty bearer token. Nothing threw — the login
/// screen moved on, and every authenticated request after it came back 401.
void main() {
  /// A sign-in response, copied from `POST /api/v1/auth/login`.
  const loginResponse = {
    'accessToken': 'access-abc',
    'refreshToken': 'refresh-xyz',
    'user': {
      '_id': '6a7aaeb668ba3172df9277f7',
      'role': 'patient',
      'email': 'patient@bienify.test',
      'phone': '+15550000001',
      'profile': {'name': 'Pat Patient', 'gender': 'male'},
    },
  };

  group('session', () {
    test('reads the tokens the server actually sends', () {
      final session = AuthSessionModel.fromJson(loginResponse);

      expect(session.accessToken, 'access-abc');
      expect(session.refreshToken, 'refresh-xyz');
    });

    test('still reads a session cached in its own format', () {
      // `toJson` writes snake_case, and a session stored before an upgrade has
      // to keep working — signing everyone out on release is not an option.
      final cached = AuthSessionModel.fromJson(
        AuthSessionModel.fromJson(loginResponse).toJson(),
      );

      expect(cached.accessToken, 'access-abc');
      expect(cached.refreshToken, 'refresh-xyz');
      expect(cached.user.name, 'Pat Patient');
    });
  });

  group('user', () {
    test('reads the display fields out of the nested profile', () {
      final user = UserModel.fromJson(
        (loginResponse['user']! as Map).cast<String, dynamic>(),
      );

      expect(user.id, '6a7aaeb668ba3172df9277f7');
      expect(user.name, 'Pat Patient');
      expect(user.email, 'patient@bienify.test');
      expect(user.phoneNumber, '+15550000001');
      expect(user.gender, Gender.male);
    });

    test('a named profile counts as complete', () {
      // The server has no `is_profile_complete` flag. Reading its absence as
      // "incomplete" sent every signed-in user back through profile setup.
      final user = UserModel.fromJson(
        (loginResponse['user']! as Map).cast<String, dynamic>(),
      );
      expect(user.isProfileComplete, isTrue);
    });

    test('a name alone is enough', () {
      // The seeded doctor has a name and no gender. Demanding both sent them
      // through the patient setup flow on every sign-in.
      final user = UserModel.fromJson(const {
        '_id': 'u1',
        'profile': {'name': 'Dr Dana Okafor'},
      });
      expect(user.isProfileComplete, isTrue);
    });

    test('a profile with no name still needs setting up', () {
      final user = UserModel.fromJson(const {'_id': 'u1', 'profile': {}});
      expect(user.isProfileComplete, isFalse);
    });
  });
}
