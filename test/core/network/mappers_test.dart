import 'dart:convert';

import 'package:bienify_app/core/network/mappers.dart';
import 'package:bienify_app/features/Role/patient/appointments/domain/entities/appointment.dart';
import 'package:bienify_app/features/Role/patient/home/domain/entities/lab_request.dart';
import 'package:flutter_test/flutter_test.dart';

/// The payloads below are copied verbatim from the running backend rather than
/// invented, so a field the server renames fails here instead of rendering an
/// empty card in someone's hands.
Map<String, dynamic> json_(String s) => jsonDecode(s) as Map<String, dynamic>;

const doctorJson = '''
{
  "_id": "6a7aaebd9edac194dd587765",
  "userId": {"_id": "6a7aaeb768ba3172df927815", "profile": {"name": "Dr Dana Okafor"}},
  "bio": "Demo cardiologist.",
  "consultationFeeMinor": 5000,
  "currency": "USD",
  "isAcceptingPatients": true,
  "specialties": ["cardiology", "general"],
  "yearsOfExperience": 12,
  "verificationStatus": "approved",
  "rating": {"average": 4.5, "count": 12}
}''';

const appointmentJson = '''
{
  "_id": "6a7aaebb68ba3172df92783b",
  "patientId": "6a7aaeb668ba3172df9277f7",
  "doctorProfileId": "6a7aaebd9edac194dd587765",
  "doctorUserId": {"_id": "6a7aaeb768ba3172df927815", "profile": {"name": "Dr Dana Okafor"}},
  "slotStart": "2026-08-13T09:00:00.000Z",
  "slotEnd": "2026-08-13T09:30:00.000Z",
  "status": "confirmed",
  "type": "video",
  "reason": "Medication review",
  "feeMinor": 5000
}''';

const labJson = '''
{
  "_id": "6a7aaebc68ba3172df927845",
  "patientId": "6a7aaeb668ba3172df9277f7",
  "requestedByDoctorId": {"_id": "6a7aaeb768ba3172df927815", "profile": {"name": "Dr Dana Okafor"}},
  "tests": ["Full blood count"],
  "status": "requested"
}''';

void main() {
  group('doctor', () {
    test('reads the name out of the populated user reference', () {
      expect(doctorFrom(json_(doctorJson)).name, 'Dr Dana Okafor');
    });

    test('shows the first specialty, readably', () {
      // The card used to print the server's own `cardiology`.
      expect(doctorFrom(json_(doctorJson)).specialty, 'Cardiology');
    });

    // Minor units are integers on the wire so no money is ever held as a
    // float; the card wants dollars.
    test('converts the fee from minor units', () {
      expect(doctorFrom(json_(doctorJson)).consultationFee, 50.0);
    });

    test('carries the rating and review count', () {
      final d = doctorFrom(json_(doctorJson));
      expect(d.rating, 4.5);
      expect(d.reviewCount, 12);
    });

    test('survives a doctor with no specialties, rating or name', () {
      final d = doctorFrom(json_('{"_id":"x"}'));
      expect(d.id, 'x');
      expect(d.name, 'Doctor');
      expect(d.specialty, 'General');
      expect(d.rating, 0);
      expect(d.consultationFee, 0);
    });

    test('treats a doctor not accepting patients as unavailable', () {
      final d = doctorFrom(json_('{"_id":"x","isAcceptingPatients":false}'));
      expect(d.isAvailable, isFalse);
    });
  });

  group('lab order for the doctor', () {
    Map<String, dynamic> order({
      String status = 'completed',
      bool withCentre = true,
      bool withResult = true,
    }) => {
      '_id': 'order-1',
      'status': status,
      'kind': 'lab',
      'tests': ['Complete Blood Count'],
      'notes': 'Routine',
      'createdAt': '2026-08-31T09:57:17.108Z',
      'patientId': {
        '_id': 'p1',
        'profile': {'name': 'Ebrahim'},
      },
      if (withCentre)
        'testingCentreId': {
          '_id': 'c1',
          'name': 'Springfield Diagnostics',
          'addressLine': '9 Lab Road',
          'city': 'Springfield',
        },
      if (withResult) 'resultRecordId': 'rec-1',
    };

    test('carries the centre and the uploaded report', () {
      // Both were dropped, so `hasResults` was false for every real order:
      // the detail screen said "Awaiting patient upload" however much had been
      // uploaded, and the button that starts the review was never drawn. The
      // whole Results to Review flow was reachable only from the sample data.
      final request = testRequestFrom(order());

      expect(request.resultRecordId, 'rec-1');
      expect(request.hasResults, isTrue);
      expect(request.hospitalName, 'Springfield Diagnostics');
      expect(request.hospitalAddress, '9 Lab Road, Springfield');
    });

    test('has no results before the patient has uploaded one', () {
      final request = testRequestFrom(
        order(status: 'requested', withCentre: false, withResult: false),
      );

      expect(request.hasResults, isFalse);
      expect(request.hospitalName, isNull);
    });

    test('keeps every field when the signed link arrives', () {
      // An omitted field silently reverts to its default; that is how a
      // courier's masthead once reset itself to zero.
      final request = testRequestFrom(order());
      final signed = request.withDocumentUrl('https://example.test/report.jpg');

      expect(signed.documentUrl, 'https://example.test/report.jpg');
      expect(signed.resultRecordId, request.resultRecordId);
      expect(signed.hospitalName, request.hospitalName);
      expect(signed.hospitalAddress, request.hospitalAddress);
      expect(signed.title, request.title);
      expect(signed.status, request.status);
      expect(signed.stage, request.stage);
      expect(signed.patient.name, request.patient.name);
      expect(signed.clinicalNotes, request.clinicalNotes);
    });
  });

  group('appointment', () {
    test('reads the doctor name and slot time', () {
      final a = appointmentFrom(json_(appointmentJson));
      expect(a.doctorName, 'Dr Dana Okafor');
      // The same instant, in the device's own zone. `Api.date` converts on
      // the way in, because every `.hour` read off a UTC `DateTime` afterwards
      // prints somebody else's clock — which is what made a chat bubble jump
      // by the whole offset the moment the stored row replaced it.
      expect(a.scheduledAt.isUtc, isFalse);
      expect(
        a.scheduledAt,
        DateTime.parse('2026-08-13T09:00:00.000Z').toLocal(),
      );
    });

    // The server has more states than the three tabs the UI offers, so each
    // one has to land somewhere sensible rather than defaulting to upcoming.
    test('collapses every server state onto a tab', () {
      expect(appointmentStatusFrom('completed'), AppointmentStatus.completed);
      expect(appointmentStatusFrom('cancelled'), AppointmentStatus.cancelled);
      expect(appointmentStatusFrom('no_show'), AppointmentStatus.cancelled);
      expect(appointmentStatusFrom('refunded'), AppointmentStatus.cancelled);
      expect(appointmentStatusFrom('confirmed'), AppointmentStatus.upcoming);
      // Was collapsed onto AppointmentStatus.upcoming — indistinguishable from
      // a paid, confirmed booking — which is what let a patient tap a live
      // "Join Visit" button on an appointment nobody had paid for yet.
      expect(
        appointmentStatusFrom('pending_payment'),
        AppointmentStatus.pendingPayment,
      );
    });

    // `doctorUserId` is expanded on the home feed and a bare id on the list
    // endpoint. Neither shape may crash the card.
    test('handles an unpopulated doctor reference', () {
      final a = appointmentFrom(
        json_(
          '{"_id":"a","doctorUserId":"6a7a","slotStart":"2026-08-13T09:00:00.000Z","status":"confirmed"}',
        ),
      );
      expect(a.doctorName, 'Doctor');
      expect(a.id, 'a');
    });

    test('falls back to epoch rather than throwing on a missing date', () {
      final a = appointmentFrom(json_('{"_id":"a"}'));
      expect(a.scheduledAt.year, 1970);
    });
  });

  group('lab request', () {
    test('joins the requested tests into a title', () {
      expect(labRequestFrom(json_(labJson)).title, 'Full blood count');
    });

    test('names the requesting doctor', () {
      expect(labRequestFrom(json_(labJson)).requestedBy, 'Dr Dana Okafor');
    });

    test('maps the lifecycle onto the three badges', () {
      expect(labStatusFrom('requested'), LabRequestStatus.requestSent);
      expect(labStatusFrom('collected'), LabRequestStatus.inProgress);
      expect(labStatusFrom('resulted'), LabRequestStatus.ready);
    });
  });

  group('home feed', () {
    test('maps the whole payload', () {
      final feed = homeFeedFrom(
        json_('''
{
  "patientName": "Pat Patient",
  "location": null,
  "labRequests": [$labJson],
  "upcomingAppointments": [$appointmentJson],
  "nearbyDoctors": [$doctorJson],
  "unreadNotifications": 3
}'''),
      );

      expect(feed.patientName, 'Pat Patient');
      expect(
        feed.location,
        '',
        reason: 'a null location is not the string "null"',
      );
      expect(feed.labRequests, hasLength(1));
      expect(feed.upcomingAppointments, hasLength(1));
      expect(feed.nearbyDoctors.single.name, 'Dr Dana Okafor');
      expect(feed.unreadNotifications, 3);
    });

    test('an empty payload produces an empty feed, not an error', () {
      final feed = homeFeedFrom(json_('{}'));
      expect(feed.isEmpty, isTrue);
      expect(feed.patientName, '');
    });
  });

  group('Api.label', () {
    test('turns a server code into something readable', () {
      // The home feed printed "in_person" under a doctor's name: the visit
      // type is the fallback when the doctor profile is not populated.
      expect(Api.label('in_person'), 'In person');
      expect(Api.label('video'), 'Video');
      expect(Api.label('cardiology'), 'Cardiology');
    });

    test('sentence case, not title case', () {
      expect(Api.label('general_practice'), 'General practice');
    });

    test('falls back rather than printing an empty line', () {
      expect(Api.label(null, 'Consultation'), 'Consultation');
      expect(Api.label('', 'Consultation'), 'Consultation');
      expect(Api.label('  ', 'Consultation'), 'Consultation');
    });
  });
}
