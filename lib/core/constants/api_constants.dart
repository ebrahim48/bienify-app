/// Network configuration and endpoint paths.
///
/// Endpoints are grouped by feature. `ApiService` prefixes them with
/// [baseUrl], so every path here starts at `/api`.
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = String.fromEnvironment(
    'BIENIFY_API_BASE_URL',
    defaultValue: 'https://api.bienify.app',
  );

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // ─── Auth ────────────────────────────────────────────────────────────────
  static const String requestOtp = '/api/v1/auth/otp/request';
  static const String verifyOtp = '/api/v1/auth/otp/verify';
  static const String loginWithEmail = '/api/v1/auth/login';
  static const String socialLogin = '/api/v1/auth/social';
  static const String completeProfile = '/api/v1/auth/profile';
  static const String registerCredentials = '/api/v1/auth/credentials';
  static const String forgotPassword = '/api/v1/auth/password/forgot';
  static const String resetPassword = '/api/v1/auth/password/reset';
  static const String logout = '/api/v1/auth/logout';

  // ─── Headers ─────────────────────────────────────────────────────────────
  static Map<String, String> get headers => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
  };

  static Map<String, String> authorized(String token) => {
    ...headers,
    'Authorization': 'Bearer $token',
  };
}
