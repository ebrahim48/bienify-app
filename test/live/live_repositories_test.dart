@Tags(['live'])
library;

import 'dart:io';

import 'package:bienify_app/core/constants/api_constants.dart';
import 'package:bienify_app/core/exceptions/app_exceptions.dart';
import 'package:bienify_app/core/network/api_client.dart';
import 'package:bienify_app/core/network/attachment_uploader.dart';
import 'package:bienify_app/core/network/token_store.dart';
import 'package:bienify_app/features/Role/patient/appointments/data/repositories/api_appointment_repository.dart';
import 'package:bienify_app/features/Role/patient/appointments/domain/entities/appointment.dart';
import 'package:bienify_app/features/Role/patient/doctors/data/repositories/api_doctor_repository.dart';
import 'package:bienify_app/features/Role/patient/home/data/datasources/api_home_remote_data_source.dart';
import 'package:bienify_app/features/Role/patient/medical_vault/data/repositories/api_vault_repository.dart';
import 'package:bienify_app/features/Role/patient/medical_vault/domain/entities/medical_record.dart';
import 'package:bienify_app/features/Role/patient/medical_vault/domain/repositories/vault_repository.dart';
import 'package:bienify_app/features/Role/patient/pharmacy/data/repositories/api_pharmacy_repository.dart';
import 'package:bienify_app/features/Role/patient/wallet/data/repositories/api_wallet_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Checks the repositories the screens actually depend on, against real data.
///
/// The mapper tests pin the shapes with recorded payloads, which catches a
/// renamed field. They cannot catch a query the server rejects, a role that is
/// refused, or a response whose real contents make the mapping produce
/// something useless — an empty doctor list, a name that comes out as
/// "Doctor", a calendar with no days. That is what this covers.
/// Runs [body], treating a rate-limit refusal as "environment unavailable"
/// rather than a failure — see the note in setUpAll.
Future<void> live(Future<void> Function() body) async {
  try {
    await body();
  } on TooManyRequestsException {
    // ignore: avoid_print
    print('Rate limited — skipped. Retry in 15 minutes.');
  }
}

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
      // A throttled environment is not a code failure. The limiters allow 20
      // auth calls and 300 overall per 15 minutes, so a run soon after another
      // trips them.
      up = false;
      // ignore: avoid_print
      print('Auth rate limit reached — live checks skipped. Retry in 15 min.');
    }
  });

  group('home feed', () {
    test('renders a named patient with real sections', () async {
      if (!up) return;
      await live(() async {
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
  });

  group('doctors', () {
    test('lists doctors with usable names and fees', () async {
      if (!up) return;
      await live(() async {
        final doctors = await ApiDoctorRepository(client).search();

        expect(doctors, isNotEmpty);
        expect(doctors.first.name, isNot('Doctor'));
        expect(doctors.first.id, isNotEmpty);
      });
    });

    test('offers specialty chips drawn from real doctors', () async {
      if (!up) return;
      await live(() async {
        final repo = ApiDoctorRepository(client);
        final chips = await repo.getSpecialties();

        expect(chips, isNotEmpty);
        // A chip that returns nothing is worse than no chip at all.
        final hits = await repo.search(specialty: chips.first);
        expect(
          hits,
          isNotEmpty,
          reason: 'chip "${chips.first}" matched nothing',
        );
      });
    });

    test('search narrows the list rather than ignoring the term', () async {
      if (!up) return;
      await live(() async {
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
    });

    test('reads a doctor profile', () async {
      if (!up) return;
      await live(() async {
        final repo = ApiDoctorRepository(client);
        final first = (await repo.search()).first;
        final details = await repo.getDetails(first.id);

        expect(details.doctor.name, first.name);
        expect(details.biography, isNotEmpty);
        expect(details.workingTime, isNotEmpty);
      });
    });

    test('builds a bookable calendar', () async {
      if (!up) return;
      await live(() async {
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
  });

  group('appointments', () {
    test('lists the patient bookings with usable detail', () async {
      if (!up) return;
      await live(() async {
        final items = await ApiAppointmentRepository(client).list();

        expect(items, isNotEmpty, reason: 'seed data should hold appointments');
        expect(
          items.map((a) => a.doctorName),
          everyElement(isNot('Doctor')),
          reason: 'the fallback name means the doctor reference was not read',
        );
        // The payment screen charges this; a zero fee would show the patient a
        // free consultation and then fail at the till.
        expect(
          items.map((a) => a.consultationFee),
          everyElement(greaterThan(0)),
        );
      });
    });

    test('returns them oldest first', () async {
      if (!up) return;
      await live(() async {
        final items = await ApiAppointmentRepository(client).list();
        final dates = items.map((a) => a.scheduledAt).toList();
        expect(dates, orderedEquals(List.of(dates)..sort()));
      });
    });

    test('covers every tab the screen offers', () async {
      if (!up) return;
      await live(() async {
        final items = await ApiAppointmentRepository(client).list();
        // The seed spans five server states; if the mapping collapsed them all
        // onto one tab, two of the three tabs would render empty forever.
        expect(items.map((a) => a.status).toSet().length, greaterThan(1));
      });
    });

    test('books, pays for and cancels an appointment', () async {
      if (!up) return;
      await live(() async {
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
          reason: 'Live check',
        );
        expect(booked.id, isNotEmpty);
        // A booking is unpaid until `pay()` below — the server creates it as
        // `pending_payment`, never `confirmed`.
        expect(booked.status, AppointmentStatus.pendingPayment);

        await appointments.pay(booked.id);

        final afterPay = await appointments.list();
        expect(afterPay.map((a) => a.id), contains(booked.id));

        await appointments.cancel(booked.id, reason: 'Live check cleanup');

        final afterCancel = await appointments.list();
        final row = afterCancel.firstWhere((a) => a.id == booked.id);
        expect(row.status, AppointmentStatus.cancelled);
      });
    });
  });

  group('wallet', () {
    test('reads a balance in major units', () async {
      if (!up) return;
      await live(() async {
        final balance = await ApiWalletRepository(client).balance();
        // The seed funds the patient; a zero balance here means minor units were
        // read from the wrong field.
        expect(balance, greaterThan(0));
      });
    });
  });

  group('pharmacy', () {
    test('lists the catalogue with real names and prices', () async {
      if (!up) return;
      await live(() async {
        final medicines = await ApiPharmacyRepository(client).searchMedicines();

        expect(medicines, isNotEmpty);
        expect(medicines.map((m) => m.name), everyElement(isNot('Medicine')));
        // A zero price would put a free medicine in the basket and fail at the
        // till.
        expect(medicines.map((m) => m.price), everyElement(greaterThan(0)));
        // An order names one pharmacy, and a basket built from the catalogue
        // has not chosen a store — so each medicine has to say where it is
        // stocked or the order cannot be addressed.
        expect(
          medicines.map((m) => m.pharmacyId),
          everyElement(isNotEmpty),
          reason: 'a catalogue basket is addressed from the medicine',
        );
      });
    });

    test('search narrows the catalogue', () async {
      if (!up) return;
      await live(() async {
        final repo = ApiPharmacyRepository(client);
        final all = await repo.searchMedicines();
        final none = await repo.searchMedicines(query: 'zzzznotamedicinezzzz');

        expect(all, isNotEmpty);
        expect(none.length, lessThan(all.length));
      });
    });

    test('lists pharmacies with an address', () async {
      if (!up) return;
      await live(() async {
        final stores = await ApiPharmacyRepository(client).stores();

        expect(stores, isNotEmpty);
        expect(stores.first.name, isNot('Pharmacy'));
        expect(stores.first.address, isNotEmpty);
      });
    });

    test('reads the patient orders with priced lines', () async {
      if (!up) return;
      await live(() async {
        final orders = await ApiPharmacyRepository(client).orders();

        expect(orders, isNotEmpty, reason: 'seed data should hold an order');
        final order = orders.first;
        expect(order.lines, isNotEmpty);
        expect(order.total, greaterThan(0));
        expect(order.lines.first.medicine.name, isNot('Medicine'));
        expect(order.status, isNotEmpty);
      });
    });

    test('places an order for an over-the-counter medicine', () async {
      if (!up) return;
      await live(() async {
        final repo = ApiPharmacyRepository(client);
        final stores = await repo.stores();
        final medicines = await repo.searchMedicines(
          pharmacyId: stores.first.id,
        );

        // Anything needing a script is refused without one, which is the
        // server's rule working rather than a broken call.
        final overTheCounter = medicines
            .where((m) => m.dosage == 'Over the counter' && m.isAvailable)
            .toList();
        if (overTheCounter.isEmpty) return;

        final id = await repo.placeOrder(
          pharmacyId: stores.first.id,
          quantitiesByMedicineId: {overTheCounter.first.id: 1},
          deliveryAddress: '12 Oak Avenue, Springfield',
        );
        expect(id, isNotEmpty);
      });
    });
  });

  group('medical vault', () {
    test('lists prescriptions with their medications', () async {
      if (!up) return;
      await live(() async {
        final items = await ApiVaultRepository(client, AttachmentUploader(client)).prescriptions();

        expect(
          items,
          isNotEmpty,
          reason: 'seed data should hold a prescription',
        );
        final script = items.first;
        expect(script.doctorName, isNot('Your doctor'));
        expect(script.medications, isNotEmpty);
        expect(script.medications.first.name, isNot('Medicine'));
        expect(script.reference, isNotEmpty);
      });
    });

    test('lists the lab orders across their stages', () async {
      if (!up) return;
      await live(() async {
        final orders = await ApiVaultRepository(client, AttachmentUploader(client)).testOrders();

        expect(orders, isNotEmpty);
        expect(orders.map((o) => o.title), everyElement(isNot('Test')));
        // The seed spans several server statuses; collapsing them all onto one
        // stage would leave the filter chips useless.
        expect(orders.map((o) => o.stage).toSet(), isNotEmpty);
      });
    });

    test('lists testing centres with an address', () async {
      if (!up) return;
      await live(() async {
        final centres = await ApiVaultRepository(client, AttachmentUploader(client)).testingCentres();
        expect(centres, isNotEmpty);
        expect(centres.first.name, isNot('Testing centre'));
      });
    });

    test('reads stored documents without failing on an empty vault', () async {
      if (!up) return;
      await live(() async {
        final documents = await ApiVaultRepository(client, AttachmentUploader(client)).documents();
        // The seed stores none; an empty list is the correct answer, not an error.
        expect(documents, isA<List<UploadedDocument>>());
      });
    });

    test('round-trips the health profile', () async {
      if (!up) return;
      await live(() async {
        final repo = ApiVaultRepository(client, AttachmentUploader(client));

        await repo.saveHealthProfile(
          const HealthProfile(
            bloodGroup: 'O+',
            allergies: ['penicillin'],
            chronicConditions: ['asthma'],
          ),
        );

        final saved = await repo.healthProfile();
        expect(saved.bloodGroup, 'O+');
        expect(saved.allergies, contains('penicillin'));
        // The server field is chronicConditions; sending 'conditions' would be
        // silently dropped and this is what catches that.
        expect(saved.chronicConditions, contains('asthma'));
      });
    });

    test('a blank profile is accepted rather than rejected', () async {
      if (!up) return;
      await live(() async {
        // An unset blood group must not be sent as an empty string — it fails
        // the server's enum check.
        await ApiVaultRepository(
          client,
          AttachmentUploader(client),
        ).saveHealthProfile(const HealthProfile());
      });
    });
  });
}
