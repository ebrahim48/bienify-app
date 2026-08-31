// Where completing sign-up sends the email and password.
//
// Profile-setup step 2 posted `{email, password}` to `POST /auth/register`,
// whose schema also requires `name` — so it answered
// `400 Validation failed — name: Required` and sign-up could not complete.
// Supplying `name` would not have fixed it: the phone/OTP step has already
// created the account and issued the session, and `register` creates a
// **brand-new user** (`auth.service.ts:149-160`), so a successful call would
// have left the patient with two accounts and signed them into the empty one.
//
// The endpoint is the assertion. Anything else — a status code, a returned
// user — looks identical whichever account the server wrote to.
import 'dart:convert';

import 'package:bienify_app/core/constants/api_constants.dart';
import 'package:bienify_app/core/network/api_client.dart';
import 'package:bienify_app/core/network/token_store.dart';
import 'package:bienify_app/core/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bienify_app/features/Role/patient/auth/data/datasources/auth_local_data_source.dart';
import 'package:bienify_app/features/Role/patient/auth/data/datasources/auth_remote_data_source.dart';
import 'package:bienify_app/features/Role/patient/auth/data/models/auth_session_model.dart';
import 'package:bienify_app/features/Role/patient/auth/data/models/user_model.dart';
import 'package:bienify_app/features/Role/patient/auth/data/repositories/auth_repository_impl.dart';
import 'package:bienify_app/features/Role/patient/auth/domain/entities/age_range.dart';
import 'package:bienify_app/features/Role/patient/auth/domain/entities/gender.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../core/network/api_client_test.dart' show FakeAdapter, ok;

({ApiClient client, FakeAdapter adapter}) buildClient() {
  final adapter = FakeAdapter(
    (_) => ok({
      'user': {
        '_id': 'user-1',
        'role': 'patient',
        'email': 'new@example.com',
        'profile': {'name': 'Phone Signup'},
      },
    }),
  );
  final dio = Dio(ApiClient.baseOptions())..httpClientAdapter = adapter;
  final refreshDio = Dio(ApiClient.baseOptions())..httpClientAdapter = adapter;
  return (
    client: ApiClient(
      tokens: MemoryTokenStore(access: 'access', refresh: 'refresh'),
      dio: dio,
      refreshDio: refreshDio,
    ),
    adapter: adapter,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('completing sign-up attaches credentials instead of registering', () async {
    final b = buildClient();
    final source = ApiAuthRemoteDataSource(b.client);

    await source.saveCredentials(
      token: 'access',
      body: {'email': 'new@example.com', 'password': 'password123'},
    );

    final sent = b.adapter.requests.single;
    expect(sent.path, ApiConstants.postAuthCredentials);
    // The account-duplicating route, specifically not used.
    expect(sent.path, isNot(ApiConstants.postAuthRegister));
    expect(sent.method, 'POST');
  });

  test('it carries the session the phone step issued', () async {
    // Without the bearer token the server cannot know which account to attach
    // to, and answers 401 — so this is not decoration.
    final b = buildClient();
    final source = ApiAuthRemoteDataSource(b.client);

    await source.saveCredentials(
      token: 'access',
      body: {'email': 'new@example.com', 'password': 'password123'},
    );

    expect(
      b.adapter.requests.single.headers['Authorization'],
      'Bearer access',
    );
  });

  test('it sends what the patient typed and nothing invented', () async {
    final b = buildClient();
    final source = ApiAuthRemoteDataSource(b.client);

    await source.saveCredentials(
      token: 'access',
      body: {'email': 'new@example.com', 'password': 'password123'},
    );

    final body = jsonDecode(jsonEncode(b.adapter.requests.single.data)) as Map;
    expect(body, {'email': 'new@example.com', 'password': 'password123'});
    // No `name` and no `role`: step 1 saved the name through `PATCH /users/me`
    // and the account already has a role. Both were `register`'s requirements,
    // not this route's.
    expect(body.containsKey('name'), isFalse);
    expect(body.containsKey('role'), isFalse);
  });
  test('profile setup sends the age bracket under the key the server keeps', () async {
    // `PATCH /users/me` validates with a zod object, which strips unknown keys
    // rather than rejecting them. The repository sent `age_range`, so the
    // server answered 200 and discarded it — the failure had no symptom at all
    // until someone looked for the value and found nothing on the account.
    //
    // Driven through `AuthRepositoryImpl` on purpose: the key is chosen there,
    // so a test that hands the datasource a ready-made body could never fail.
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await storage.init();

    // The repository reads its session from local storage when it is built,
    // and `saveProfileDetails` needs the bearer token from it.
    final local = AuthLocalDataSource(storage);
    await local.writeSession(
      const AuthSessionModel(
        accessToken: 'access',
        refreshToken: 'refresh',
        user: UserModel(id: 'user-1'),
      ),
    );

    final remote = _RecordingRemote();
    final repository = AuthRepositoryImpl(remote: remote, local: local);

    await repository.saveProfileDetails(
      name: 'Phone Signup',
      gender: Gender.male,
      ageRange: AgeRange.age25to32,
    );

    expect(remote.profileBody['ageRange'], '25-32');
    expect(remote.profileBody.containsKey('age_range'), isFalse);
    expect(remote.profileBody['name'], 'Phone Signup');
  });
}

/// Records the body the repository built, which is the thing under test.
class _RecordingRemote implements AuthRemoteDataSource {
  Map<String, dynamic> profileBody = <String, dynamic>{};

  @override
  Future<UserModel> saveProfileDetails({
    required String token,
    required Map<String, dynamic> body,
  }) async {
    profileBody = body;
    return const UserModel(id: 'user-1');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
