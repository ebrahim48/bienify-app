import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

/// Signs in with an email address and password.
class LoginWithEmail {
  const LoginWithEmail(this._repository);

  final AuthRepository _repository;

  Future<AuthSession> call({required String email, required String password}) =>
      _repository.loginWithEmail(email: email, password: password);
}

/// Signs in through Google or Apple.
class SignInWithProvider {
  const SignInWithProvider(this._repository);

  final AuthRepository _repository;

  Future<AuthSession> call(SocialProvider provider) =>
      _repository.signInWithProvider(provider);
}

/// Ends the session and clears cached credentials.
class Logout {
  const Logout(this._repository);

  final AuthRepository _repository;

  Future<void> call() => _repository.logout();
}
