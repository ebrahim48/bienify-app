@Tags(['live'])
library;

import 'dart:io';

import 'package:bienify_app/core/constants/api_constants.dart';
import 'package:bienify_app/core/exceptions/app_exceptions.dart';
import 'package:bienify_app/core/network/api_client.dart';
import 'package:bienify_app/core/network/token_store.dart';
import 'package:bienify_app/core/network/mappers.dart';
import 'package:bienify_app/features/Role/doctor_role/data/repositories/api_doctor_practice_repository.dart';
import 'package:bienify_app/features/Role/patient/chat/data/repositories/api_conversation_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Checks the practitioner repository against real data.
///
/// The doctor's screens read the same endpoints the patient's do, but from the
/// other side of them — `GET /appointments` answers "my bookings as a patient"
/// unless it is told otherwise, and a doctor who does not say so gets an empty
/// calendar with a 200. That is the class of failure this covers: a call that
/// succeeds and returns nothing useful.
///
///   flutter test test/live/live_doctor_test.dart --tags live
void main() {
  late ApiDoctorPracticeRepository repository;
  late ApiConversationRepository conversations;
  var up = false;

  setUpAll(() async {
    try {
      final probe = HttpClient()
        ..connectionTimeout = const Duration(seconds: 3);
      final res = await (await probe.getUrl(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.health}'),
      )).close();
      await res.drain<void>();
      probe.close();
      up = res.statusCode == 200;
    } catch (_) {
      up = false;
    }
    if (!up) return;

    final store = MemoryTokenStore();
    final client = ApiClient(tokens: store);
    try {
      final data = await client.postMap(
        ApiConstants.postAuthLogin,
        body: {'email': 'doctor@bienify.test', 'password': 'Password123!'},
      );
      await store.save(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
    } on TooManyRequestsException {
      up = false;
      // ignore: avoid_print
      print('Auth rate limit reached — live checks skipped. Retry in 15 min.');
      return;
    }
    repository = ApiDoctorPracticeRepository(client);
    conversations = ApiConversationRepository(
      client,
      myUserId: () async => Api.id(await client.getMap(ApiConstants.usersMe)),
    );
  });

  /// Treats a rate-limit refusal as "environment unavailable", not a failure.
  Future<void> live(Future<void> Function() body) async {
    try {
      await body();
    } on TooManyRequestsException {
      // ignore: avoid_print
      print('Rate limited — skipped. Retry in 15 minutes.');
    }
  }

  group('dashboard', () {
    test('names the practitioner and counts their real week', () async {
      if (!up) return;
      await live(() async {
        final dashboard = await repository.dashboard();

        expect(
          dashboard.practitioner.name,
          isNot('Doctor'),
          reason: 'the fallback name means the profile was not read',
        );
        expect(dashboard.practitioner.initials, isNot('?'));
        // The seed gives this doctor a balance and a history; zeroes here mean
        // the wallet and stats reads were mapped off the wrong fields.
        expect(dashboard.practitioner.availableBalance, greaterThan(0));
        expect(int.parse(dashboard.totalPatients), greaterThan(0));
        expect(dashboard.totalEarned, isNot('\$0'));
        expect(
          dashboard.load,
          hasLength(7),
          reason: 'the chart is a week of bars',
        );
        expect(dashboard.chartMax, greaterThan(0));
      });
    });
  });

  group('appointments', () {
    test('lists the bookings the doctor is party to', () async {
      if (!up) return;
      await live(() async {
        final appointments = await repository.appointments();

        // This is the whole point of the `role=doctor` query: without it the
        // server answers with the doctor's own patient bookings, of which
        // there are none, and the screen shows an empty calendar.
        expect(
          appointments,
          isNotEmpty,
          reason: 'a doctor with seeded bookings should see them',
        );
        expect(appointments.first.patientName, isNot('Patient'));
        expect(appointments.first.id, isNotEmpty);
        expect(
          appointments.map((a) => a.scheduledAt.year),
          isNot(contains(1970)),
        );
      });
    });

    test('groups bookings under the three chips', () async {
      if (!up) return;
      await live(() async {
        final appointments = await repository.appointments();
        // Every row has to land under a chip, or it is invisible in the UI.
        expect(appointments.map((a) => a.filter), everyElement(isNotNull));
      });
    });
  });

  group('earnings', () {
    test('reports balances and the consultations behind them', () async {
      if (!up) return;
      await live(() async {
        final earnings = await repository.earnings();

        expect(earnings.availableLabel, isNotEmpty);
        expect(earnings.totalEarnedLabel, isNot('\$0'));
        expect(earnings.paidOutLabel, isNotEmpty);
        expect(
          earnings.consultations,
          isNotEmpty,
          reason: 'the seeded doctor has been paid for consultations',
        );
        expect(earnings.consultations.first.amountLabel, startsWith('+'));
      });
    });

    test('lists payout accounts without failing on an empty set', () async {
      if (!up) return;
      await live(() async {
        // The seed adds none; an empty list is the correct answer, not an error.
        expect(await repository.payoutAccounts(), isA<List<Object>>());
      });
    });
  });

  group('profile', () {
    test('reads the practice details the edit form fills from', () async {
      if (!up) return;
      await live(() async {
        final details = await repository.profileDetails();

        expect(details.fullName, isNot('Doctor'));
        expect(details.email, contains('@'));
        expect(details.specialty, isNotEmpty);
        expect(details.licenceNumber, isNotEmpty);
        expect(details.consultationFee, greaterThan(0));
      });
    });

    test('a changed fee is saved without erasing the rest', () async {
      if (!up) return;
      await live(() async {
        final before = await repository.profileDetails();

        // `POST /doctors/me` is an upsert, not a patch: it requires
        // `specialties` and `licenseNumber` on every call and replaces the
        // document with what it is given. A fee-only body is refused with
        // "Validation failed", and a fee-plus-required body would erase the
        // bio, the languages and the years of experience.
        await repository.saveConsultationFee(
          amount: before.consultationFee + 5,
          currency: before.currency,
        );

        final after = await repository.profileDetails();
        expect(after.consultationFee, before.consultationFee + 5);
        expect(after.currency, before.currency);
        expect(after.licenceNumber, before.licenceNumber);
        expect(after.specialty, before.specialty);
        expect(after.biography, before.biography);
        expect(after.experience, before.experience);

        // Put it back so a re-run starts where this one did.
        await repository.saveConsultationFee(
          amount: before.consultationFee,
          currency: before.currency,
        );
      });
    });

    test('a changed biography leaves the fee alone', () async {
      if (!up) return;
      await live(() async {
        final before = await repository.profileDetails();

        await repository.saveProfileDetails(
          specialty: before.specialty,
          experience: before.experience,
          biography: 'Live check biography',
          licenceNumber: before.licenceNumber,
          language: before.language,
        );

        final after = await repository.profileDetails();
        expect(after.biography, 'Live check biography');
        expect(after.consultationFee, before.consultationFee);

        await repository.saveProfileDetails(
          specialty: before.specialty,
          experience: before.experience,
          biography: before.biography,
          licenceNumber: before.licenceNumber,
          language: before.language,
        );
      });
    });
  });

  group('schedule', () {
    test('lays the weekly pattern over seven dated days', () async {
      if (!up) return;
      await live(() async {
        final days = await repository.availability(DateTime.now());

        expect(days, hasLength(7));
        expect(days.first.name, 'Monday');
        // The seeded doctor is open every day, so an all-closed week means the
        // dayOfWeek convention was read the wrong way round.
        expect(days.where((d) => d.isOpen), isNotEmpty);

        final open = days.firstWhere((d) => d.isOpen);
        expect(open.slots, isNotEmpty);
        expect(
          open.slots.first.endMinute,
          greaterThan(open.slots.first.startMinute),
        );
      });
    });

    test('a saved week reads back with the same open days', () async {
      if (!up) return;
      await live(() async {
        final before = await repository.availability(DateTime.now());
        await repository.saveAvailability(before);
        final after = await repository.availability(DateTime.now());

        expect(
          after.where((d) => d.isOpen).map((d) => d.dayOfWeek),
          before.where((d) => d.isOpen).map((d) => d.dayOfWeek),
          reason: 'a round trip must not close a day the doctor had open',
        );
      });
    });
  });

  group('messages', () {
    test(
      'a sent message comes back in the thread, on the right side',
      () async {
        if (!up) return;
        await live(() async {
          final appointments = await repository.appointments();
          final id = appointments.first.id;

          final sent = await conversations.send(
            appointmentId: id,
            body: 'Live check ${DateTime.now().millisecondsSinceEpoch}',
          );
          expect(sent.isMine, isTrue);

          final thread = await conversations.messages(id);
          expect(thread.map((m) => m.id), contains(sent.id));
          // Oldest first: the server pages newest-first, and a thread read in
          // that order puts the reply above the question.
          expect(
            thread.first.sentAt.isAfter(thread.last.sentAt),
            isFalse,
            reason: 'a thread reads oldest first',
          );
          // Every bubble has to land on a side, and the doctor's own must be
          // theirs — the payload says who sent it, not whether that was you.
          expect(thread.where((m) => m.isMine), isNotEmpty);
        });
      },
    );

    test('threads are named rather than listed by id', () async {
      if (!up) return;
      await live(() async {
        final threads = await repository.threads();

        expect(threads, isNotEmpty);
        expect(
          threads.first.patientName,
          isNot('Patient'),
          reason:
              'the threads endpoint does not populate its counterpart, so '
              'the name is joined from the appointment list',
        );
        expect(threads.first.id, isNotEmpty);
        expect(threads.first.timeLabel, matches(RegExp(r'^\d{2}:\d{2}$')));
      });
    });
  });

  group('patients', () {
    test('rosters one entry per person, not one per booking', () async {
      if (!up) return;
      await live(() async {
        final patients = await repository.reviewPatients();

        expect(patients, isNotEmpty);
        expect(patients.first.name, isNot('Patient'));
        expect(
          patients.map((p) => p.id).toSet(),
          hasLength(patients.length),
          reason: 'a patient seen twice must not appear twice',
        );
      });
    });

    test('orders a lab test for a real patient', () async {
      if (!up) return;
      await live(() async {
        final patients = await repository.reviewPatients();
        await repository.orderTest(
          patientId: patients.first.id,
          tests: const ['Complete Blood Count'],
          notes: 'Routine — live check',
        );
      });
    });
  });
}
