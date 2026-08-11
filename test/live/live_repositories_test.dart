@Tags(['live'])
library;

import 'dart:io';

import 'package:bienify_app/core/constants/api_constants.dart';
import 'package:bienify_app/core/exceptions/app_exceptions.dart';
import 'package:bienify_app/core/network/api_client.dart';
import 'package:bienify_app/core/network/token_store.dart';
import 'package:bienify_app/features/Role/patient/appointments/data/repositories/api_appointment_repository.dart';
import 'package:bienify_app/features/Role/patient/appointments/domain/entities/appointment.dart';
import 'package:bienify_app/features/Role/patient/doctors/data/repositories/api_doctor_repository.dart';
import 'package:bienify_app/features/Role/patient/home/data/datasources/api_home_remote_data_source.dart';
import 'package:bienify_app/features/Role/patient/wallet/data/repositories/api_wallet_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Checks the repositories the screens actually depend on, against real data.
///
/// The mapper tests pin the shapes with recorded payloads, which catches a
/// renamed field. They cannot catch a query the server rejects, a role that is
/// refused, or a response whose real contents make the mapping produce
/// something useless — an empty doctor list, a name that comes out as
/// "Doctor", a calendar with no days. That is what this covers.
void main() {
  late ApiClient client;
  var up = false;

  setUpAll(() async {
    try {
      final probe = HttpClient()
        ..connectionTimeout = const Duration(seconds: 3);
      final res = await (await probe.getUrl(
        Uri.parse('${ApiConstants.baseUrl}/health'),
      )).close();
      await res.drain<void>();
      probe.close();
      up = res.statusCode == 200;
    } catch (_) {
      up = false;
    }
    if (!up) return;

    final store = MemoryTokenStore();
    client = ApiClient(tokens: store);
    try {
      final data = await client.postMap(
        ApiConstants.postAuthLogin,
        body: {'email': 'patient@bienify.test', 'password': 'Password123!'},
      );
      await store.save(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
    } on TooManyRequestsException {
      // See live_api_test: a throttled environment is not a code failure.
      up = false;
      // ignore: avoid_print
      print('Auth rate limit reached — live checks skipped. Retry in 15 min.');
    }
  });

  group('home feed', () {
    test('renders a named patient with real sections', () async {
      if (!up) return;
      final feed = await ApiHomeRemoteDataSource(client).getFeed();

      expect(feed.patientName, isNotEmpty);
      // The seeded patient has appointments and a lab request; an empty feed
      // here means the mapping dropped them rather than that there are none.
      expect(
        feed.isEmpty,
        isFalse,
        reason: 'seed data should populate the feed',
      );
      expect(
        feed.upcomingAppointments.map((a) => a.doctorName),
        everyElement(isNot('Doctor')),
        reason: 'the fallback name means the doctor reference was not read',
      );
      expect(
        feed.upcomingAppointments.map((a) => a.scheduledAt.year),
        everyElement(isNot(1970)),
        reason: 'the epoch fallback means slotStart was not parsed',
      );
    });
  });

  group('doctors', () {
    test('lists doctors with usable names and fees', () async {
      if (!up) return;
      final doctors = await ApiDoctorRepository(client).search();

      expect(doctors, isNotEmpty);
      expect(doctors.first.name, isNot('Doctor'));
      expect(doctors.first.id, isNotEmpty);
    });

    test('offers specialty chips drawn from real doctors', () async {
      if (!up) return;
      final repo = ApiDoctorRepository(client);
      final chips = await repo.getSpecialties();

      expect(chips, isNotEmpty);
      // A chip that returns nothing is worse than no chip at all.
      final hits = await repo.search(specialty: chips.first);
      expect(hits, isNotEmpty, reason: 'chip "${chips.first}" matched nothing');
    });

    test('search narrows the list rather than ignoring the term', () async {
      if (!up) return;
      final repo = ApiDoctorRepository(client);
      final all = await repo.search();
      final none = await repo.search(query: 'zzzznotadoctorzzzz');

      expect(all, isNotEmpty);
      expect(
        none.length,
        lessThan(all.length),
        reason: 'a nonsense term returned everything, so search is ignored',
      );
    });

    test('reads a doctor profile', () async {
      if (!up) return;
      final repo = ApiDoctorRepository(client);
      final first = (await repo.search()).first;
      final details = await repo.getDetails(first.id);

      expect(details.doctor.name, first.name);
      expect(details.biography, isNotEmpty);
      expect(details.workingTime, isNotEmpty);
    });

    test('builds a bookable calendar', () async {
      if (!up) return;
      final repo = ApiDoctorRepository(client);
      final first = (await repo.search()).first;
      final availability = await repo.getAvailability(first.id);

      expect(availability.days, isNotEmpty, reason: 'no bookable days');
      expect(availability.days.first.slots, isNotEmpty);
      expect(availability.months, isNotEmpty);
      // Days must arrive in order — the calendar strip renders them as given.
      final dates = availability.days.map((d) => d.date).toList();
      expect(dates, orderedEquals(List.of(dates)..sort()));
    });
  });

  group('appointments', () {
    test('lists the patient bookings with usable detail', () async {
      if (!up) return;
      final items = await ApiAppointmentRepository(client).list();

      expect(items, isNotEmpty, reason: 'seed data should hold appointments');
      expect(
        items.map((a) => a.doctorName),
        everyElement(isNot('Doctor')),
        reason: 'the fallback name means the doctor reference was not read',
      );
      // The payment screen charges this; a zero fee would show the patient a
      // free consultation and then fail at the till.
      expect(items.map((a) => a.consultationFee), everyElement(greaterThan(0)));
    });

    test('returns them oldest first', () async {
      if (!up) return;
      final items = await ApiAppointmentRepository(client).list();
      final dates = items.map((a) => a.scheduledAt).toList();
      expect(dates, orderedEquals(List.of(dates)..sort()));
    });

    test('covers every tab the screen offers', () async {
      if (!up) return;
      final items = await ApiAppointmentRepository(client).list();
      // The seed spans five server states; if the mapping collapsed them all
      // onto one tab, two of the three tabs would render empty forever.
      expect(items.map((a) => a.status).toSet().length, greaterThan(1));
    });

    test('books, pays for and cancels an appointment', () async {
      if (!up) return;
      final doctors = ApiDoctorRepository(client);
      final appointments = ApiAppointmentRepository(client);

      final doctor = (await doctors.search()).first;
      final availability = await doctors.getAvailability(doctor.id);
      expect(availability.days, isNotEmpty);

      // Rebuild the exact instant from the calendar the UI renders.
      final day = availability.days.first;
      final parts = day.slots.first.label.split(':');
      final slot = DateTime(
        day.date.year,
        day.date.month,
        day.date.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );

      final booked = await appointments.book(
        doctorProfileId: doctor.id,
        slotStart: slot,
        type: 'video',
        reason: 'Live check',
      );
      expect(booked.id, isNotEmpty);
      expect(booked.status, AppointmentStatus.upcoming);

      await appointments.pay(booked.id);

      final afterPay = await appointments.list();
      expect(afterPay.map((a) => a.id), contains(booked.id));

      await appointments.cancel(booked.id, reason: 'Live check cleanup');

      final afterCancel = await appointments.list();
      final row = afterCancel.firstWhere((a) => a.id == booked.id);
      expect(row.status, AppointmentStatus.cancelled);
    });
  });

  group('wallet', () {
    test('reads a balance in major units', () async {
      if (!up) return;
      final balance = await ApiWalletRepository(client).balance();
      // The seed funds the patient; a zero balance here means minor units were
      // read from the wrong field.
      expect(balance, greaterThan(0));
    });
  });
}
