// The unread badge on the doctor's message list.
//
// It counted up when a patient wrote and never came down. Clearing only ever
// happened on a fresh fetch of the whole list, so the number sat on the row
// through opening the conversation, reading every message and coming back —
// which is the one thing an unread count must never do.

import 'dart:async';
import 'dart:convert';

import 'package:bienify_app/core/network/socket_service.dart';
import 'package:bienify_app/core/network/token_store.dart';
import 'package:bienify_app/features/Role/doctor_role/data/repositories/static_doctor_practice_repository.dart';
import 'package:bienify_app/features/Role/doctor_role/domain/entities/doctor_practice.dart';
import 'package:bienify_app/features/Role/doctor_role/presentation/controllers/doctor_messages_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

String _tokenFor(String userId) {
  String b64(Map<String, Object?> claims) =>
      base64Url.encode(utf8.encode(jsonEncode(claims))).replaceAll('=', '');
  return '${b64({'alg': 'HS256'})}.${b64({'sub': userId, 'role': 'doctor'})}.sig';
}

/// A socket that publishes arrivals and nothing else.
class _Socket extends SocketService {
  _Socket() : super(tokens: MemoryTokenStore());

  final _feed = StreamController<Map<String, dynamic>>.broadcast();

  @override
  Stream<Map<String, dynamic>> get messages => _feed.stream;

  @override
  void connect() {}

  @override
  void joinThread(_) {}

  void deliver(Map<String, dynamic> json) => _feed.add(json);

  @override
  void dispose() {
    unawaited(_feed.close());
    super.dispose();
  }
}

/// The static repository's rows, so the ids are real ones.
class _Repository extends StaticDoctorPracticeRepository {}

void main() {
  late _Socket socket;

  setUp(() {
    Get.testMode = true;
    socket = _Socket();
  });

  tearDown(() {
    socket.dispose();
    Get.reset();
  });

  Future<DoctorMessagesController> open() async {
    final controller = DoctorMessagesController(
      repository: _Repository(),
      socket: socket,
      tokens: MemoryTokenStore(access: _tokenFor('me')),
    );
    controller.onInit();
    await Future<void>.delayed(Duration.zero);
    addTearDown(controller.onClose);
    return controller;
  }

  Map<String, dynamic> from(PatientThread thread) => {
    '_id': 'm-${DateTime.now().microsecondsSinceEpoch}',
    'appointmentId': thread.id,
    'senderId': 'the-patient',
    'body': 'my chest hurts',
    'createdAt': DateTime.now().toUtc().toIso8601String(),
  };

  test('clears the badge when the conversation is opened', () async {
    final controller = await open();
    expect(controller.threads, isNotEmpty);
    final target = controller.threads.first;

    socket.deliver(from(target));
    await Future<void>.delayed(Duration.zero);

    final counted = controller.threads.firstWhere((t) => t.id == target.id);
    expect(counted.unreadCount, greaterThan(0));

    controller.openThread(counted);

    expect(
      controller.threads.firstWhere((t) => t.id == target.id).unreadCount,
      0,
    );
  });

  test('opening one conversation leaves the others counted', () async {
    final controller = await open();
    final first = controller.threads.first;
    final second = controller.threads.firstWhere((t) => t.id != first.id);

    socket.deliver(from(first));
    socket.deliver(from(second));
    await Future<void>.delayed(Duration.zero);

    final before = controller.threads
        .firstWhere((t) => t.id == second.id)
        .unreadCount;
    controller.openThread(
      controller.threads.firstWhere((t) => t.id == first.id),
    );

    expect(
      controller.threads.firstWhere((t) => t.id == second.id).unreadCount,
      before,
    );
  });

  test('the badge does not come back when the same row is reopened', () async {
    final controller = await open();
    final target = controller.threads.first;
    socket.deliver(from(target));
    await Future<void>.delayed(Duration.zero);

    // The caller still holds the row as it was, count and all; clearing must
    // read the list rather than trust what it was handed.
    final stale = controller.threads.firstWhere((t) => t.id == target.id);
    controller.openThread(stale);
    controller.openThread(stale);

    expect(
      controller.threads.firstWhere((t) => t.id == target.id).unreadCount,
      0,
    );
  });
}
