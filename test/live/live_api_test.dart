@Tags(['live'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:bienify_app/core/constants/api_constants.dart';
import 'package:bienify_app/core/exceptions/app_exceptions.dart';
import 'package:bienify_app/core/network/api_client.dart';
import 'package:bienify_app/core/network/token_store.dart';
import 'package:flutter_test/flutter_test.dart';

/// Exercises the live backend through the app's own client.
///
/// The point is not to re-test the server — the backend has its own suite for
/// that. It is to prove that *this* client, with its envelope unwrapping, its
/// bearer header and its refresh, gets a usable result from every endpoint the
/// app will call. A contract test that mocks the transport cannot catch a path
/// typo, a renamed field, or a role that turns out to be forbidden.
///
/// Skips itself when the backend is not running, so `flutter test` stays green
/// on a machine with no server:
///
///   flutter test test/live/live_api_test.dart
const password = 'Password123!';

const accounts = {
  'patient': 'patient@bienify.test',
  'doctor': 'doctor@bienify.test',
  'pharmacy_owner': 'pharmacy@bienify.test',
  'rider': 'rider@bienify.test',
  'admin': 'admin@bienify.test',
};

/// Records one write step alongside the read probes, so a single report
/// covers the whole run. [allow] lists statuses that still count as correct —
/// re-running against a database that already holds the last run's result is
/// not a regression.
Future<dynamic> act(
  String what,
  Future<dynamic> Function() call, {
  Set<int> allow = const {},
}) async {
  try {
    final out = await call();
    results.add(Probe('WRITE', what, '-', true, 'ok'));
    return out;
  } on AppException catch (e) {
    final status = _statusOf(e);
    final tolerated = status != null && allow.contains(status);
    results.add(Probe('WRITE', what, '-', tolerated, '$status ${e.message}'));
    return null;
  }
}

String? idOf(dynamic row) =>
    row is Map ? (row['_id'] ?? row['id'])?.toString() : null;

/// One attempt at one endpoint.
class Probe {
  Probe(this.method, this.path, this.role, this.ok, this.detail);
  final String method, path, role, detail;
  final bool ok;
}

final results = <Probe>[];
final ids = <String, String>{};

Future<bool> backendUp() async {
  try {
    final c = HttpClient()..connectionTimeout = const Duration(seconds: 3);
    final req = await c.getUrl(Uri.parse('${ApiConstants.baseUrl}/health'));
    final res = await req.close();
    await res.drain<void>();
    c.close();
    return res.statusCode == 200;
  } catch (_) {
    return false;
  }
}

/// Runs one call and records the outcome instead of throwing, so a single
/// broken endpoint does not hide the state of the other 144.
Future<dynamic> probe(
  ApiClient client,
  String role,
  String method,
  String path, {
  Object? body,
  Map<String, dynamic>? query,
  Set<int> allow = const {},
}) async {
  try {
    final data = switch (method) {
      'GET' => await client.get(path, query: query),
      'POST' => await client.post(path, body: body),
      'PATCH' => await client.patch(path, body: body),
      'PUT' => await client.put(path, body: body),
      'DELETE' => await client.delete(path, body: body),
      _ => throw StateError('unknown method $method'),
    };
    results.add(Probe(method, path, role, true, 'ok'));
    return data;
  } on AppException catch (e) {
    // Some calls are meant to be refused — a patient poking an admin route is
    // the authorisation layer working, not a broken endpoint.
    final status = _statusOf(e);
    final refused = status != null && allow.contains(status);
    results.add(Probe(method, path, role, refused, '$status ${e.message}'));
    return null;
  }
}

/// The status each exception type stands for.
int? _statusOf(AppException e) => switch (e) {
  ValidationException() => 400,
  UnauthorizedException() => 401,
  ForbiddenException() => 403,
  NotFoundException() => 404,
  ConflictException() => 409,
  TooManyRequestsException() => 429,
  ServerException(:final statusCode) => statusCode,
  _ => null,
};

String? firstId(dynamic data) {
  final list = ApiClient.listFrom(data);
  if (list.isEmpty) return null;
  final row = list.first;
  return (row['_id'] ?? row['id'])?.toString();
}

Future<ApiClient> signIn(String role) async {
  final store = MemoryTokenStore();
  final client = ApiClient(tokens: store);
  final data = await client.postMap(
    ApiConstants.postAuthLogin,
    body: {'email': accounts[role], 'password': password},
  );
  final access = data['accessToken'] as String?;
  final refresh = data['refreshToken'] as String?;
  if (access == null || refresh == null) {
    throw StateError('login for $role returned no tokens');
  }
  await store.save(accessToken: access, refreshToken: refresh);
  results.add(Probe('POST', ApiConstants.postAuthLogin, role, true, 'ok'));
  return client;
}

/// Signs in, waiting out the auth rate limiter if it trips.
///
/// `/auth/*` is deliberately throttled, and two live suites running at once
/// burst ten logins in a second. Backing off is the honest response — relaxing
/// the limiter to make a test pass would remove a real protection.
Future<ApiClient> signInWithBackoff(String email) async {
  for (var attempt = 0; ; attempt++) {
    try {
      return await signIn(email);
    } on TooManyRequestsException {
      if (attempt >= 4) rethrow;
      await Future<void>.delayed(Duration(seconds: 2 << attempt));
    }
  }
}

/// One session per role, shared by every check below.
///
/// `/auth/*` allows 20 requests per 15 minutes. Signing in per test would
/// exhaust that budget after two runs, so the sessions are established once.
final clients = <String, ApiClient>{};

void main() {
  late bool up;

  setUpAll(() async {
    up = await backendUp();
    if (!up) {
      // ignore: avoid_print
      print(
        'Backend not reachable at ${ApiConstants.baseUrl} — live checks skipped.',
      );
      return;
    }
    try {
      for (final role in accounts.keys) {
        clients[role] = await signInWithBackoff(role);
      }
    } on TooManyRequestsException {
      // `/auth/*` allows 20 logins per 15 minutes. Running the suite twice in
      // quick succession exhausts that, which says nothing about the code —
      // so skip rather than report a failure the next run would not reproduce.
      up = false;
      // ignore: avoid_print
      print('Auth rate limit reached — live checks skipped. Retry in 15 min.');
    }
  });

  test(
    'every role can sign in and read its own data',
    () async {
      if (!up) return;

      // ── Public, no token ───────────────────────────────────────────────────
      final anon = ApiClient(tokens: MemoryTokenStore());
      final doctors = await probe(anon, 'anon', 'GET', ApiConstants.doctors);
      ids['doctor'] = firstId(doctors) ?? '';
      final meds = await probe(anon, 'anon', 'GET', ApiConstants.medicines);
      ids['medicine'] = firstId(meds) ?? '';
      await probe(anon, 'anon', 'GET', ApiConstants.diagnosticTests);
      await probe(anon, 'anon', 'GET', ApiConstants.pharmacies);
      await probe(anon, 'anon', 'GET', ApiConstants.testingCentres);
      await probe(anon, 'anon', 'GET', ApiConstants.paymentPoints);

      // An anonymous caller must be refused anything personal.
      await probe(anon, 'anon', 'GET', ApiConstants.usersMe, allow: {401});

      // ── Patient ────────────────────────────────────────────────────────────
      final p = clients['patient']!;
      await probe(p, 'patient', 'GET', ApiConstants.usersMe);
      await probe(p, 'patient', 'GET', ApiConstants.homeFeed);
      final appts = await probe(p, 'patient', 'GET', ApiConstants.appointments);
      ids['appointment'] = firstId(appts) ?? '';
      final scripts = await probe(
        p,
        'patient',
        'GET',
        ApiConstants.prescriptions,
      );
      ids['prescription'] = firstId(scripts) ?? '';
      final orders = await probe(
        p,
        'patient',
        'GET',
        ApiConstants.medicineOrders,
      );
      ids['order'] = firstId(orders) ?? '';
      final labs = await probe(p, 'patient', 'GET', ApiConstants.labOrders);
      ids['labOrder'] = firstId(labs) ?? '';
      await probe(p, 'patient', 'GET', ApiConstants.wallet);
      await probe(p, 'patient', 'GET', ApiConstants.walletTransactions);
      await probe(p, 'patient', 'GET', ApiConstants.notifications);
      await probe(p, 'patient', 'GET', ApiConstants.vaultRecords);

      // A patient must not reach the admin console.
      await probe(p, 'patient', 'GET', ApiConstants.adminUsers, allow: {403});

      // ── Doctor ─────────────────────────────────────────────────────────────
      final d = clients['doctor']!;
      await probe(d, 'doctor', 'GET', ApiConstants.usersMe);
      await probe(d, 'doctor', 'GET', ApiConstants.appointments);
      await probe(d, 'doctor', 'GET', ApiConstants.doctorsMe);
      await probe(d, 'doctor', 'GET', ApiConstants.doctorsMeStats);
      await probe(d, 'doctor', 'GET', ApiConstants.walletTransactions);

      // ── Pharmacy ───────────────────────────────────────────────────────────
      final ph = clients['pharmacy_owner']!;
      await probe(ph, 'pharmacy_owner', 'GET', ApiConstants.usersMe);
      await probe(ph, 'pharmacy_owner', 'GET', ApiConstants.medicineOrders);
      await probe(ph, 'pharmacy_owner', 'GET', ApiConstants.wallet);

      // ── Rider ──────────────────────────────────────────────────────────────
      final r = clients['rider']!;
      await probe(r, 'rider', 'GET', ApiConstants.usersMe);
      await probe(r, 'rider', 'GET', ApiConstants.deliveriesAvailable);
      await probe(r, 'rider', 'GET', ApiConstants.wallet);

      // ── Admin ──────────────────────────────────────────────────────────────
      final a = clients['admin']!;
      await probe(a, 'admin', 'GET', ApiConstants.adminUsers);
      await probe(a, 'admin', 'GET', ApiConstants.adminDashboardStats);
      await probe(a, 'admin', 'GET', ApiConstants.adminSettings);
      await probe(a, 'admin', 'GET', ApiConstants.adminTests);
      await probe(a, 'admin', 'GET', ApiConstants.adminAppointments);
      await probe(a, 'admin', 'GET', ApiConstants.adminWithdrawals);
      await probe(a, 'admin', 'GET', ApiConstants.adminPartnerApplications);

      // ── Detail routes, using ids harvested above ──────────────────────────
      if ((ids['doctor'] ?? '').isNotEmpty) {
        await probe(anon, 'anon', 'GET', ApiConstants.doctors2(ids['doctor']!));
        await probe(
          anon,
          'anon',
          'GET',
          ApiConstants.appointmentsSlots,
          // The slot search takes a window, not a single day, and keys off the
          // doctor's *profile* id — which is what `GET /doctors` returns.
          query: {
            'doctorProfileId': ids['doctor'],
            'from': DateTime.now().toUtc().toIso8601String(),
            'to': DateTime.now()
                .add(const Duration(days: 7))
                .toUtc()
                .toIso8601String(),
          },
        );
        await probe(
          anon,
          'anon',
          'GET',
          ApiConstants.reviewsDoctors(ids['doctor']!),
        );
      }
      if ((ids['appointment'] ?? '').isNotEmpty) {
        await probe(
          p,
          'patient',
          'GET',
          ApiConstants.appointments2(ids['appointment']!),
        );
      }
      if ((ids['order'] ?? '').isNotEmpty) {
        await probe(
          p,
          'patient',
          'GET',
          ApiConstants.medicineOrders2(ids['order']!),
        );
      }
      if ((ids['prescription'] ?? '').isNotEmpty) {
        await probe(
          p,
          'patient',
          'GET',
          ApiConstants.prescriptions2(ids['prescription']!),
        );
      }

      _report();

      final failed = results.where((r) => !r.ok).toList();
      expect(
        failed,
        isEmpty,
        reason: failed
            .map((f) => '${f.role}: ${f.method} ${f.path} -> ${f.detail}')
            .join('\n'),
      );
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );

  test(
    'the platform accepts the writes each role makes',
    () async {
      if (!up) return;

      // ── Profile ────────────────────────────────────────────────────────────
      await act(
        'patient updates their profile',
        () => clients['patient']!.patch(
          ApiConstants.updateUsersMe,
          body: {
            'profile': {'name': 'Pat Patient'},
          },
        ),
      );
      await act(
        'patient asks for an avatar upload URL',
        () => clients['patient']!.post(
          ApiConstants.postUsersMeAvatarUploadUrl,
          body: {'contentType': 'image/jpeg'},
        ),
      );

      // ── Booking ────────────────────────────────────────────────────────────
      final doctors = ApiClient.listFrom(
        await clients['patient']!.get(ApiConstants.doctors),
      );
      expect(doctors, isNotEmpty, reason: 'seed data should list a doctor');
      final doctorProfileId = idOf(doctors.first)!;

      final slots = await act(
        'patient searches for free slots',
        () => clients['patient']!.get(
          ApiConstants.appointmentsSlots,
          query: {
            'doctorProfileId': doctorProfileId,
            'from': DateTime.now().toUtc().toIso8601String(),
            'to': DateTime.now()
                .add(const Duration(days: 14))
                .toUtc()
                .toIso8601String(),
          },
        ),
      );

      final free = ApiClient.listFrom(slots);
      String? bookedId;
      if (free.isNotEmpty) {
        final start = (free.first['start'] ?? free.first['slotStart'])
            ?.toString();
        final booked = await act(
          'patient books an appointment',
          () => clients['patient']!.post(
            ApiConstants.postAppointments,
            body: {
              'doctorProfileId': doctorProfileId,
              'slotStart': start,
              'type': 'video',
              'reason': 'Persistent headache',
            },
          ),
          // The slot may already be taken by an earlier run of this suite.
          allow: {409},
        );
        bookedId = idOf(booked);
      }

      if (bookedId != null) {
        await act(
          'patient pays for the appointment',
          () => clients['patient']!.post(
            ApiConstants.postPaymentsAppointmentsPay(bookedId!),
            body: {'method': 'wallet'},
          ),
          // An empty wallet is a correct refusal, not a broken endpoint.
          allow: {400, 402, 409},
        );
        await act(
          'doctor starts the consultation',
          () => clients['doctor']!.post(
            ApiConstants.postAppointmentsStart(bookedId!),
          ),
          allow: {400, 403, 409},
        );
        await act(
          'patient cancels the appointment',
          () => clients['patient']!.post(
            ApiConstants.postAppointmentsCancel(bookedId!),
            body: {'reason': 'Feeling better'},
          ),
          allow: {400, 409},
        );
      }

      // ── Wallet ─────────────────────────────────────────────────────────────
      await act(
        'patient tops up their wallet',
        () => clients['patient']!.post(
          ApiConstants.postWalletTopup,
          body: {'amountMinor': 5000, 'method': 'card'},
        ),
        allow: {400, 402},
      );
      await act(
        'patient lists saved cards',
        () => clients['patient']!.get(ApiConstants.walletCards),
      );
      await act(
        'doctor reviews their earnings',
        () => clients['doctor']!.get(ApiConstants.walletEarnings),
      );
      await act(
        'doctor lists payout accounts',
        () => clients['doctor']!.get(ApiConstants.walletPayoutAccounts),
      );
      await act(
        'doctor requests a withdrawal',
        () => clients['doctor']!.post(
          ApiConstants.postWalletWithdrawals,
          body: {'amountMinor': 1000},
        ),
        // Below the minimum, or no payout account yet — both are real answers.
        allow: {400, 404, 409},
      );

      // ── Vault ──────────────────────────────────────────────────────────────
      await act(
        'patient saves a health profile',
        () => clients['patient']!.put(
          ApiConstants.putVaultHealthProfile,
          body: {
            'bloodGroup': 'O+',
            'allergies': ['penicillin'],
            'conditions': <String>[],
          },
        ),
        allow: {400},
      );
      await act(
        'patient lists vault records',
        () => clients['patient']!.get(ApiConstants.vaultRecords),
      );
      // Sharing runs patient -> doctor, so the doctor is the one who reads
      // this list; a patient calling it is correctly refused.
      await act(
        'doctor sees the records shared with them',
        () => clients['doctor']!.get(ApiConstants.vaultRecordsSharedWithMe),
      );
      await act(
        'a patient may not read the doctor-only shared list',
        () => clients['patient']!.get(ApiConstants.vaultRecordsSharedWithMe),
        allow: {403},
      );

      // ── Notifications ──────────────────────────────────────────────────────
      final notes = ApiClient.listFrom(
        await clients['patient']!.get(ApiConstants.notifications),
      );
      if (notes.isNotEmpty) {
        await act(
          'patient marks one notification read',
          () => clients['patient']!.post(
            ApiConstants.postNotificationsRead(idOf(notes.first)!),
          ),
          allow: {404, 409},
        );
      }
      await act(
        'patient marks everything read',
        () => clients['patient']!.post(ApiConstants.postNotificationsReadAll),
      );

      // ── Pharmacy and delivery ──────────────────────────────────────────────
      await act(
        'pharmacy reviews its orders',
        () => clients['pharmacy_owner']!.get(ApiConstants.medicineOrders),
      );
      await act(
        'rider lists deliveries it could claim',
        () => clients['rider']!.get(ApiConstants.deliveriesAvailable),
      );

      // ── Admin ──────────────────────────────────────────────────────────────
      await act(
        'admin reads the approval queues',
        () => clients['admin']!.get(ApiConstants.adminDashboardApprovalQueues),
      );
      await act(
        'admin reads the settings',
        () => clients['admin']!.get(ApiConstants.adminSettings),
      );
      await act(
        'admin changes a setting',
        () => clients['admin']!.put(
          ApiConstants.putAdminSettings,
          body: {
            'updates': [
              {'key': 'platform.name', 'value': 'Bienify'},
            ],
          },
        ),
      );
      await act(
        'admin refuses an unknown setting key',
        () => clients['admin']!.put(
          ApiConstants.putAdminSettings,
          body: {
            'updates': [
              {'key': 'not.a.real.key', 'value': 1},
            ],
          },
        ),
        // The refusal *is* the expected behaviour here.
        allow: {400},
      );
      await act(
        'admin lists the test catalogue',
        () => clients['admin']!.get(ApiConstants.adminTests),
      );
      await act(
        'admin sees the pending doctors',
        () => clients['admin']!.get(ApiConstants.adminDoctorsPending),
      );

      _report();

      final failed = results.where((r) => !r.ok).toList();
      expect(
        failed,
        isEmpty,
        reason: failed
            .map((f) => '${f.role}: ${f.method} ${f.path} -> ${f.detail}')
            .join('\n'),
      );
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

void _report() {
  final passed = results.where((r) => r.ok).length;
  final buf = StringBuffer()
    ..writeln('# Live API check (Flutter client)')
    ..writeln()
    ..writeln('Ran against `${ApiConstants.baseUrl}` through `ApiClient`.')
    ..writeln()
    ..writeln('| Metric | Result |')
    ..writeln('|---|---|')
    ..writeln('| Calls | ${results.length} |')
    ..writeln('| Passed | $passed |')
    ..writeln('| Failed | ${results.length - passed} |')
    ..writeln()
    ..writeln('| Result | Role | Method | Path | Detail |')
    ..writeln('|---|---|---|---|---|');
  for (final r in results) {
    buf.writeln(
      '| ${r.ok ? "PASS" : "FAIL"} | ${r.role} | ${r.method} | `${r.path}` | ${r.detail} |',
    );
  }
  File('docs/LIVE-API-CHECK.md')
    ..createSync(recursive: true)
    ..writeAsStringSync(buf.toString());
  // ignore: avoid_print
  print('$passed/${results.length} live calls passed — docs/LIVE-API-CHECK.md');
  // ignore: avoid_print
  print(jsonEncode(ids));
}
