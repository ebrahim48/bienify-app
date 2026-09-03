// Rewriting a message you already sent.
//
// Messenger's rule, which is the one people already know: your own words,
// text only, inside a quarter of an hour, and the bubble says it changed.
// The window is checked here as well as on the server — not to enforce it,
// which is the server's job, but so the menu never offers an edit that would
// come back refused.

import 'dart:async';

import 'package:bienify_app/core/models/chat_thread.dart';
import 'package:bienify_app/core/network/attachment_uploader.dart';
import 'package:bienify_app/core/network/socket_service.dart';
import 'package:bienify_app/core/network/token_store.dart';
import 'package:bienify_app/core/services/attachment_picker_service.dart';
import 'package:bienify_app/features/Role/patient/chat/domain/entities/conversation.dart';
import 'package:bienify_app/features/Role/patient/chat/domain/repositories/conversation_repository.dart';
import 'package:bienify_app/features/Role/patient/chat/presentation/controllers/chat_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

const _peer = ConversationPeer(
  id: 'doctor-1',
  thread: ChatThread.consultation('appt-1'),
  name: 'Dr Grace',
  specialty: 'Cardiology',
);

ChatMessage _mine({
  String id = 'm-1',
  String text = 'teh appointmnet is at 3',
  Duration age = Duration.zero,
  MessageKind kind = MessageKind.text,
  MessageAttachment? attachment,
  bool isPending = false,
}) => ChatMessage(
  id: id,
  text: text,
  sentAt: DateTime.now().subtract(age),
  author: MessageAuthor.me,
  kind: kind,
  attachment: attachment,
  isPending: isPending,
);

class _Socket extends SocketService {
  _Socket() : super(tokens: MemoryTokenStore());

  final _editFeed = StreamController<Map<String, dynamic>>.broadcast();

  /// Rewrites this side asked the server for, in order.
  final List<String> sent = [];

  @override
  Stream<Map<String, dynamic>> get edits => _editFeed.stream;

  @override
  void editMessage({
    required ChatThread thread,
    required String messageId,
    required String body,
  }) => sent.add('$messageId=$body');

  @override
  void connect() {}

  @override
  void joinThread(_) {}

  @override
  void setTyping(ChatThread thread, {required bool isTyping}) {}

  /// The other side rewrote something.
  void deliverEdit({
    required String id,
    required String body,
    String senderId = 'doctor-1',
    String appointmentId = 'appt-1',
    String deliveryId = '',
  }) => _editFeed.add({
    '_id': id,
    'appointmentId': appointmentId,
    'deliveryId': deliveryId,
    'senderId': senderId,
    'body': body,
    'kind': 'text',
    'createdAt': DateTime.now().toUtc().toIso8601String(),
    'editedAt': DateTime.now().toUtc().toIso8601String(),
  });

  @override
  void dispose() {
    unawaited(_editFeed.close());
    super.dispose();
  }
}

class _Picker implements AttachmentPickerService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Uploader implements AttachmentUploader {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Repository implements ConversationRepository {
  _Repository(this._messages);

  final List<ChatMessage> _messages;

  @override
  Future<List<ConversationThread>> threads() async => [];

  @override
  Future<List<ChatMessage>> messages(ChatThread thread) async => _messages;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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

  Future<ChatController> open(List<ChatMessage> messages) async {
    final controller = ChatController(
      peer: _peer,
      repository: _Repository(messages),
      socket: socket,
      picker: _Picker(),
      uploader: _Uploader(),
    );
    controller.onInit();
    await Future<void>.delayed(Duration.zero);
    addTearDown(controller.onClose);
    return controller;
  }

  group('what may be edited', () {
    test('a message just sent', () async {
      final message = _mine();
      final controller = await open([message]);

      expect(controller.canEdit(message), isTrue);
    });

    test('one sent fourteen minutes ago', () async {
      final message = _mine(age: const Duration(minutes: 14));
      final controller = await open([message]);

      expect(controller.canEdit(message), isTrue);
    });

    test('not one sent sixteen minutes ago', () async {
      // Long enough to catch the typo you notice as the bubble lands; short
      // enough that nobody can quietly rewrite what they said in a
      // consultation an hour later.
      final message = _mine(age: const Duration(minutes: 16));
      final controller = await open([message]);

      expect(controller.canEdit(message), isFalse);
    });

    test('not the other party’s message', () async {
      final theirs = ChatMessage(
        id: 'm-2',
        text: 'what the doctor said',
        sentAt: DateTime.now(),
        author: MessageAuthor.peer,
      );
      final controller = await open([theirs]);

      expect(controller.canEdit(theirs), isFalse);
    });

    test('not one still on its way to the server', () async {
      // It has no stored id yet, so there is nothing for the server to find.
      final message = _mine(isPending: true);
      final controller = await open([message]);

      expect(controller.canEdit(message), isFalse);
    });

    test('not an attachment', () async {
      // Its body is a caption for a file that would no longer match.
      final message = _mine(
        kind: MessageKind.image,
        attachment: const MessageAttachment(
          name: 'rash.jpg',
          mime: 'image/jpeg',
          size: 1,
        ),
      );
      final controller = await open([message]);

      expect(controller.canEdit(message), isFalse);
    });
  });

  group('rewriting one', () {
    test('sends the new text and marks the bubble edited', () async {
      final controller = await open([_mine()]);

      controller.beginEdit(controller.messages.first);
      controller.inputController.text = 'the appointment is at 3';
      await controller.send();

      expect(socket.sent, ['m-1=the appointment is at 3']);
      expect(controller.messages.first.text, 'the appointment is at 3');
      expect(controller.messages.first.wasEdited, isTrue);
    });

    test('does not add a second bubble', () async {
      // Edit mode reuses the composer; without the branch in `send` a rewrite
      // would post the text again as a new message.
      final controller = await open([_mine()]);
      final before = controller.messages.length;

      controller.beginEdit(controller.messages.first);
      controller.inputController.text = 'fixed';
      await controller.send();

      expect(controller.messages.length, before);
    });

    test('leaves edit mode afterwards', () async {
      final controller = await open([_mine()]);

      controller.beginEdit(controller.messages.first);
      controller.inputController.text = 'fixed';
      await controller.send();

      // Otherwise the next thing typed silently rewrites the same bubble
      // instead of sending a message.
      expect(controller.editing.value, isNull);
      expect(controller.inputController.text, isEmpty);
    });

    test('loads the old text into the composer to be corrected', () async {
      final controller = await open([_mine(text: 'teh time')]);

      controller.beginEdit(controller.messages.first);

      // Retyping the whole message to fix one letter is not an edit feature.
      expect(controller.inputController.text, 'teh time');
    });

    test('cancelling changes nothing', () async {
      final controller = await open([_mine(text: 'original')]);

      controller.beginEdit(controller.messages.first);
      controller.inputController.text = 'half a rewrite';
      controller.cancelEdit();

      expect(socket.sent, isEmpty);
      expect(controller.messages.first.text, 'original');
      expect(controller.messages.first.wasEdited, isFalse);
      expect(controller.inputController.text, isEmpty);
    });

    test('refuses to begin on a message past the window', () async {
      final stale = _mine(age: const Duration(minutes: 20));
      final controller = await open([stale]);

      controller.beginEdit(controller.messages.first);

      expect(controller.editing.value, isNull);
    });
  });

  group('a courier thread, by the same rules', () {
    // A courier and their customer are the same conversation to everyone
    // involved. The screen is shared, so the only way this breaks is somebody
    // gating a feature on `isConsultation` — which is exactly what these
    // catch.
    const courier = ConversationPeer(
      id: 'rider-1',
      thread: ChatThread.delivery('del-1'),
      name: 'Sam',
      specialty: 'motorbike · Springfield',
    );

    Future<ChatController> openDelivery(List<ChatMessage> messages) async {
      final controller = ChatController(
        peer: courier,
        repository: _Repository(messages),
        socket: socket,
        picker: _Picker(),
        uploader: _Uploader(),
      );
      controller.onInit();
      await Future<void>.delayed(Duration.zero);
      addTearDown(controller.onClose);
      return controller;
    }

    test('a message to the courier can be rewritten', () async {
      final controller = await openDelivery([_mine(text: 'flat 3')]);

      expect(controller.canEdit(controller.messages.first), isTrue);

      controller.beginEdit(controller.messages.first);
      controller.inputController.text = 'flat 8, sorry';
      await controller.send();

      expect(socket.sent, ['m-1=flat 8, sorry']);
      expect(controller.messages.single.wasEdited, isTrue);
    });

    test('the same window applies', () async {
      final controller = await openDelivery([
        _mine(age: const Duration(minutes: 16)),
      ]);

      expect(controller.canEdit(controller.messages.first), isFalse);
    });

    test('the courier rewriting theirs changes it here', () async {
      final theirs = ChatMessage(
        id: 'm-9',
        text: 'five minutes',
        sentAt: DateTime.now(),
        author: MessageAuthor.peer,
      );
      final controller = await openDelivery([theirs]);

      socket.deliverEdit(
        id: 'm-9',
        body: 'ten minutes, sorry',
        senderId: 'rider-1',
        appointmentId: '',
        deliveryId: 'del-1',
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.messages.single.text, 'ten minutes, sorry');
      expect(controller.messages.length, 1);
    });

    test('a consultation edit does not touch a courier thread', () async {
      final controller = await openDelivery([_mine(text: 'flat 3')]);

      socket.deliverEdit(id: 'm-1', body: 'from a consultation');
      await Future<void>.delayed(Duration.zero);

      expect(controller.messages.single.text, 'flat 3');
    });
  });

  group('when the other party rewrites theirs', () {
    test('the bubble changes where it stands', () async {
      final theirs = ChatMessage(
        id: 'm-9',
        text: 'come at 4',
        sentAt: DateTime.now(),
        author: MessageAuthor.peer,
      );
      final controller = await open([theirs]);

      socket.deliverEdit(id: 'm-9', body: 'come at 5');
      await Future<void>.delayed(Duration.zero);

      expect(controller.messages.single.text, 'come at 5');
      expect(controller.messages.single.wasEdited, isTrue);
    });

    test('does not append it as a new message', () async {
      final theirs = ChatMessage(
        id: 'm-9',
        text: 'come at 4',
        sentAt: DateTime.now(),
        author: MessageAuthor.peer,
      );
      final controller = await open([theirs]);

      socket.deliverEdit(id: 'm-9', body: 'come at 5');
      await Future<void>.delayed(Duration.zero);

      // A rewrite is not an arrival; treating it as one would show the words
      // twice and pull the thread to the top of the list.
      expect(controller.messages.length, 1);
    });

    test('keeps the receipts this device already knows about', () async {
      final read = DateTime.now();
      final mine = _mine().copyWith(deliveredAt: read, readAt: read);
      final controller = await open([mine]);

      socket.deliverEdit(id: 'm-1', body: 'rewritten', senderId: '');
      await Future<void>.delayed(Duration.zero);

      // The server sends the message, not the reader's state; taking its word
      // would drop a bubble from Seen back to Delivered.
      expect(controller.messages.single.readAt, isNotNull);
    });

    test('ignores an edit in another thread', () async {
      final controller = await open([_mine()]);

      socket.deliverEdit(
        id: 'm-1',
        body: 'from somewhere else',
        appointmentId: 'appt-other',
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.messages.single.text, 'teh appointmnet is at 3');
    });

    test('ignores an edit for a message not on screen', () async {
      final controller = await open([_mine()]);

      socket.deliverEdit(id: 'not-here', body: 'nothing to change');
      await Future<void>.delayed(Duration.zero);

      expect(controller.messages.single.text, 'teh appointmnet is at 3');
      expect(controller.messages.length, 1);
    });
  });
}
