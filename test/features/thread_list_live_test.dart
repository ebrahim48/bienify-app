// The message list, while it is open.
//
// Both lists joined every thread's room and then threw away every message that
// arrived in them: the preview, its time and the order of the list were
// whatever they had been when the screen opened. A reply could arrive, be
// visible inside the thread, and leave the row above it unchanged until the
// screen was left and come back to.

import 'dart:async';
import 'dart:convert';

import 'package:bienify_app/core/models/chat_thread.dart';
import 'package:bienify_app/core/network/socket_service.dart';
import 'package:bienify_app/core/network/token_store.dart';
import 'package:bienify_app/features/Role/patient/chat/domain/entities/conversation.dart';
import 'package:bienify_app/features/Role/patient/chat/domain/repositories/conversation_repository.dart';
import 'package:bienify_app/features/Role/patient/chat/presentation/controllers/messages_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// A socket a test can publish messages onto.
class _Socket extends SocketService {
  _Socket() : super(tokens: MemoryTokenStore());

  final _feed = StreamController<Map<String, dynamic>>.broadcast();

  @override
  Stream<Map<String, dynamic>> get messages => _feed.stream;

  /// Never opens a connection; these drive the stream the server publishes on.
  @override
  void connect() {}

  @override
  void joinThread(ChatThread thread) {}

  @override
  Future<PresenceState?> queryPresence(String userId) async => null;

  void deliver(Map<String, dynamic> json) => _feed.add(json);

  @override
  void dispose() {
    unawaited(_feed.close());
    super.dispose();
  }
}

class _Repository implements ConversationRepository {
  _Repository(this.rows);

  List<ConversationThread> rows;
  int reads = 0;

  @override
  Future<List<ConversationThread>> threads() async {
    reads += 1;
    return List.of(rows);
  }

  @override
  Future<List<ChatMessage>> messages(ChatThread thread) async => const [];

  @override
  Future<ChatMessage> send({
    required ChatThread thread,
    required String body,
    String? clientId,
    Map<String, dynamic>? attachment,
  }) async => throw UnimplementedError();
}

/// A JWT the token store can read a subject out of: header.payload.signature,
/// payload base64url with its padding stripped.
String _tokenFor(String userId) {
  String b64(Map<String, Object?> claims) => base64Url
      .encode(utf8.encode(jsonEncode(claims)))
      .replaceAll('=', '');
  return '${b64({'alg': 'HS256'})}.${b64({'sub': userId, 'role': 'patient'})}.sig';
}

void main() {
  late _Socket socket;
  late _Repository repository;

  ConversationThread row(String id, String name, String preview, DateTime at) =>
      ConversationThread(
        peer: ConversationPeer(
          id: '$id-user',
          thread: ChatThread.consultation(id),
          name: name,
          specialty: 'Cardiology',
        ),
        preview: preview,
        lastMessageAt: at,
      );

  Map<String, dynamic> message({
    required String appointmentId,
    required String senderId,
    String body = 'a new reply',
    Map<String, dynamic>? attachment,
  }) => {
    '_id': 'm-${DateTime.now().microsecondsSinceEpoch}',
    'appointmentId': appointmentId,
    'senderId': senderId,
    'body': body,
    'attachment': ?attachment,
    'createdAt': DateTime.now().toUtc().toIso8601String(),
  };

  setUp(() {
    Get.testMode = true;
    socket = _Socket();
    repository = _Repository([
      row('a', 'Dr Grace', 'older', DateTime(2026, 9, 1, 9)),
      row('b', 'Dr Dana', 'newer', DateTime(2026, 9, 1, 10)),
    ]);
  });

  tearDown(() {
    socket.dispose();
    Get.reset();
  });

  Future<MessagesController> open() async {
    final controller = MessagesController(
      repository: repository,
      socket: socket,
      tokens: MemoryTokenStore(access: _tokenFor('me')),
    );
    controller.onInit();
    await Future<void>.delayed(Duration.zero);
    addTearDown(controller.onClose);
    return controller;
  }

  test('moves the thread to the top and shows what was said', () async {
    final controller = await open();
    expect(controller.threads.first.appointmentId, 'b');

    socket.deliver(
      message(appointmentId: 'a', senderId: 'a-user', body: 'I have a rash'),
    );
    await Future<void>.delayed(Duration.zero);

    expect(controller.threads.first.appointmentId, 'a');
    expect(controller.threads.first.preview, 'I have a rash');
  });

  test('counts their message as unread', () async {
    final controller = await open();

    socket.deliver(message(appointmentId: 'a', senderId: 'a-user'));
    await Future<void>.delayed(Duration.zero);

    expect(controller.threads.first.unreadCount, 1);
  });

  test('counts a message unread even when the peer id is unknown', () async {
    // `GET /consultations/threads` does not populate its counterpart, so a row
    // can carry an empty peer id. Deciding "is this mine" by comparing against
    // that read every message as ours and counted nothing.
    repository.rows = [
      ConversationThread(
        peer: const ConversationPeer(
          id: '',
          thread: ChatThread.consultation('a'),
          name: 'Dr Grace',
          specialty: 'Cardiology',
        ),
        preview: 'older',
        lastMessageAt: DateTime(2026, 9, 1, 9),
      ),
    ];
    final controller = await open();

    socket.deliver(message(appointmentId: 'a', senderId: 'someone-else'));
    await Future<void>.delayed(Duration.zero);

    expect(controller.threads.first.unreadCount, 1);
  });

  test('does not count our own message against us', () async {
    final controller = await open();

    // The server echoes a send back to the room, so the sender's own list sees
    // it too — and must move without claiming something is waiting to be read.
    socket.deliver(message(appointmentId: 'a', senderId: 'me'));
    await Future<void>.delayed(Duration.zero);

    expect(controller.threads.first.appointmentId, 'a');
    expect(controller.threads.first.unreadCount, 0);
  });

  test('names a file rather than previewing an empty line', () async {
    final controller = await open();

    socket.deliver(
      message(
        appointmentId: 'a',
        senderId: 'a-user',
        body: '',
        attachment: {'name': 'results.pdf', 'mime': 'application/pdf'},
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(controller.threads.first.preview, 'results.pdf');
  });

  test('keeps every other field on the row it moves', () async {
    final controller = await open();

    socket.deliver(message(appointmentId: 'a', senderId: 'a-user'));
    await Future<void>.delayed(Duration.zero);

    // An omitted field silently reverts to its default; that is how a
    // courier's masthead once reset itself to zero.
    final moved = controller.threads.first;
    expect(moved.peer.name, 'Dr Grace');
    expect(moved.peer.id, 'a-user');
    expect(moved.peer.thread?.id, 'a');
    expect(moved.peer.specialty, 'Cardiology');
  });

  group('courier threads share this list', () {
    // This list used to drop every delivery message on the floor, because
    // courier conversations were reachable only from the order-tracking
    // screen. They now sit here beside consultations, which is the only place
    // a last message, an unread count and an order by recency exist — so a
    // parcel message reaching a customer who is not watching the map had
    // nowhere at all to show before this.
    ConversationThread courierRow(String id, DateTime at) => ConversationThread(
      peer: ConversationPeer(
        id: 'rider-1',
        thread: ChatThread.delivery(id),
        name: 'Sam',
        specialty: 'Delivery',
      ),
      preview: 'on my way',
      lastMessageAt: at,
    );

    Map<String, dynamic> courierMessage({
      String deliveryId = 'd-1',
      String senderId = 'rider-1',
      String body = 'outside now',
    }) => {
      '_id': 'm-${DateTime.now().microsecondsSinceEpoch}',
      'deliveryId': deliveryId,
      'senderId': senderId,
      'body': body,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };

    test('a courier message moves its row to the top and counts unread', () async {
      repository = _Repository([
        courierRow('d-1', DateTime(2026, 9, 1, 8)),
        row('b', 'Dr Dana', 'newer', DateTime(2026, 9, 1, 10)),
      ]);
      final controller = await open();
      expect(controller.threads.first.appointmentId, 'b');

      socket.deliver(courierMessage());
      await Future<void>.delayed(Duration.zero);

      expect(controller.threads.first.appointmentId, 'd-1');
      expect(controller.threads.first.preview, 'outside now');
      expect(controller.threads.first.unreadCount, 1);
    });

    test('our own message to the courier is not counted unread', () async {
      repository = _Repository([courierRow('d-1', DateTime(2026, 9, 1, 8))]);
      final controller = await open();

      socket.deliver(courierMessage(senderId: 'me'));
      await Future<void>.delayed(Duration.zero);

      expect(controller.threads.first.unreadCount, 0);
      expect(controller.threads.first.preview, 'outside now');
    });

    test('a delivery id never lands on a consultation of the same id', () async {
      // The two kinds are numbered independently, so an id can name one of
      // each. Matching on the bare id would put a parcel's message on a
      // doctor's row.
      repository = _Repository([row('d-1', 'Dr Grace', 'older', DateTime(2026, 9, 1, 9))]);
      final controller = await open();
      final readsBefore = repository.reads;

      socket.deliver(courierMessage());
      await Future<void>.delayed(Duration.zero);

      expect(controller.threads.single.preview, 'older');
      // Unknown to this list, so it re-reads to learn who it is with — the
      // same thing it does for a consultation it has never seen.
      expect(repository.reads, readsBefore + 1);
    });

    test('a courier thread it has never seen re-reads the list', () async {
      final controller = await open();
      final readsBefore = repository.reads;

      socket.deliver(courierMessage(deliveryId: 'brand-new'));
      await Future<void>.delayed(Duration.zero);

      expect(repository.reads, readsBefore + 1);
      expect(controller.isLoading.value, isFalse);
    });
  });

  test('re-reads when a thread it has never seen speaks up', () async {
    final controller = await open();
    final readsBefore = repository.reads;

    // A consultation whose first message this is: the list has no row to move
    // and no way to know whose it is.
    socket.deliver(message(appointmentId: 'unknown', senderId: 'someone'));
    await Future<void>.delayed(Duration.zero);

    expect(repository.reads, readsBefore + 1);
    expect(controller.isLoading.value, isFalse);
  });

  test('clears the badge when the conversation is opened', () async {
    // The one thing an unread count must never do is survive being read. It
    // only ever cleared on a fresh fetch of the list, so the number sat on the
    // row for as long as the screen stayed alive — through opening the thread,
    // reading every message and coming back out.
    final controller = await open();
    socket.deliver(message(appointmentId: 'a', senderId: 'a-user'));
    await Future<void>.delayed(Duration.zero);

    final unread = controller.threads.firstWhere((t) => t.appointmentId == 'a');
    expect(unread.unreadCount, 1);

    controller.openThread(unread);

    expect(
      controller.threads.firstWhere((t) => t.appointmentId == 'a').unreadCount,
      0,
    );
  });

  test('opening one conversation leaves the others counted', () async {
    final controller = await open();
    socket.deliver(message(appointmentId: 'a', senderId: 'a-user'));
    socket.deliver(message(appointmentId: 'b', senderId: 'b-user'));
    await Future<void>.delayed(Duration.zero);

    controller.openThread(
      controller.threads.firstWhere((t) => t.appointmentId == 'a'),
    );

    expect(
      controller.threads.firstWhere((t) => t.appointmentId == 'b').unreadCount,
      1,
    );
  });

  test('the badge does not come back when the same thread is reopened', () async {
    final controller = await open();
    socket.deliver(message(appointmentId: 'a', senderId: 'a-user'));
    await Future<void>.delayed(Duration.zero);

    final thread = controller.threads.firstWhere((t) => t.appointmentId == 'a');
    controller.openThread(thread);
    // The caller still holds the row as it was, with its count on it; clearing
    // must read the list rather than trust what it was handed.
    controller.openThread(thread);

    expect(
      controller.threads.firstWhere((t) => t.appointmentId == 'a').unreadCount,
      0,
    );
  });
}
