// The typing indicator.
//
// The socket carried `typing` from the first release and the header printed
// `typing…` where `Online` normally sits — same place, same weight, same
// colour. Nothing changed where a reader actually looks, so the feature was
// there and nobody could see it. These pin both halves: the state the header
// reads, and the dots at the end of the conversation that make it visible.

import 'dart:async';

import 'package:bienify_app/core/models/chat_thread.dart';
import 'package:bienify_app/core/network/attachment_uploader.dart';
import 'package:bienify_app/core/services/attachment_picker_service.dart';
import 'package:bienify_app/core/network/socket_service.dart';
import 'package:bienify_app/core/network/token_store.dart';
import 'package:bienify_app/features/Role/patient/chat/domain/entities/conversation.dart';
import 'package:bienify_app/features/Role/patient/chat/domain/repositories/conversation_repository.dart';
import 'package:bienify_app/features/Role/patient/chat/presentation/controllers/chat_controller.dart';
import 'package:bienify_app/features/Role/patient/chat/presentation/widgets/typing_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

const _peer = ConversationPeer(
  id: 'doctor-1',
  thread: ChatThread.consultation('appt-1'),
  name: 'Dr Grace',
  specialty: 'Cardiology',
);

/// A socket whose typing feed a test drives, and which records what this side
/// announced about its own typing.
class _Socket extends SocketService {
  _Socket() : super(tokens: MemoryTokenStore());

  final _typingFeed = StreamController<TypingState>.broadcast();

  /// What we told the other side, in order.
  final List<bool> announced = [];

  @override
  Stream<TypingState> get typing => _typingFeed.stream;

  @override
  void setTyping(ChatThread thread, {required bool isTyping}) =>
      announced.add(isTyping);

  @override
  void connect() {}

  @override
  void joinThread(_) {}

  /// Someone starts or stops typing in a named thread, of either kind.
  void deliverTyping({
    required ChatThread thread,
    required String userId,
    required bool isTyping,
  }) => _typingFeed.add(
    TypingState(thread: thread, userId: userId, isTyping: isTyping),
  );

  /// Someone starts or stops typing in a thread.
  void peerTypes({
    required String userId,
    required bool isTyping,
    String appointmentId = 'appt-1',
  }) => _typingFeed.add(
    TypingState(
      thread: ChatThread.consultation(appointmentId),
      userId: userId,
      isTyping: isTyping,
    ),
  );

  @override
  void dispose() {
    unawaited(_typingFeed.close());
    super.dispose();
  }
}

/// Neither is reached by anything these tests do; the controller only asks
/// for them when a file is attached.
class _Picker implements AttachmentPickerService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Uploader implements AttachmentUploader {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Repository implements ConversationRepository {
  @override
  Future<List<ConversationThread>> threads() async => [];

  @override
  Future<List<ChatMessage>> messages(ChatThread thread) async => [];

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

  Future<ChatController> open() async {
    final controller = ChatController(
      peer: _peer,
      repository: _Repository(),
      socket: socket,
      picker: _Picker(),
      uploader: _Uploader(),
    );
    controller.onInit();
    await Future<void>.delayed(Duration.zero);
    addTearDown(controller.onClose);
    return controller;
  }

  group('what the reader is told', () {
    test('shows the indicator while the other party writes', () async {
      final controller = await open();
      expect(controller.isPeerTyping.value, isFalse);

      socket.peerTypes(userId: 'doctor-1', isTyping: true);
      await Future<void>.delayed(Duration.zero);

      expect(controller.isPeerTyping.value, isTrue);
    });

    test('takes it down when they stop', () async {
      final controller = await open();
      socket.peerTypes(userId: 'doctor-1', isTyping: true);
      await Future<void>.delayed(Duration.zero);

      socket.peerTypes(userId: 'doctor-1', isTyping: false);
      await Future<void>.delayed(Duration.zero);

      expect(controller.isPeerTyping.value, isFalse);
    });

    test('ignores typing in another thread', () async {
      // One socket carries every thread this person is in. A second
      // conversation open behind this one must not move these dots.
      final controller = await open();

      socket.peerTypes(
        userId: 'doctor-1',
        isTyping: true,
        appointmentId: 'appt-other',
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.isPeerTyping.value, isFalse);
    });

    test('ignores a third party typing in this thread', () async {
      final controller = await open();

      socket.peerTypes(userId: 'someone-else', isTyping: true);
      await Future<void>.delayed(Duration.zero);

      expect(controller.isPeerTyping.value, isFalse);
    });
  });

  group('what the writer announces', () {
    test('announces typing once, not once per keystroke', () async {
      final controller = await open();

      controller.inputController.text = 'h';
      controller.inputController.text = 'he';
      controller.inputController.text = 'hel';

      // A `typing:start` per character would be dozens of events a sentence,
      // all saying the same thing.
      expect(socket.announced.where((it) => it).length, 1);
    });

    test('retracts it when the box is emptied', () async {
      final controller = await open();
      controller.inputController.text = 'hello';
      socket.announced.clear();

      controller.inputController.text = '';

      // Clearing the box is the one stop that must not wait for the timer:
      // there is plainly nothing being written any more.
      expect(socket.announced, [false]);
    });

    test('says nothing while the box stays empty', () async {
      final controller = await open();
      socket.announced.clear();

      controller.inputController.text = '';

      expect(socket.announced.where((it) => it), isEmpty);
    });
  });

  group('a courier thread, by the same rules', () {
    const courier = ConversationPeer(
      id: 'rider-1',
      thread: ChatThread.delivery('del-1'),
      name: 'Sam',
      specialty: 'motorbike · Springfield',
    );

    Future<ChatController> openDelivery() async {
      final controller = ChatController(
        peer: courier,
        repository: _Repository(),
        socket: socket,
        picker: _Picker(),
        uploader: _Uploader(),
      );
      controller.onInit();
      await Future<void>.delayed(Duration.zero);
      addTearDown(controller.onClose);
      return controller;
    }

    test('shows the courier typing', () async {
      final controller = await openDelivery();

      socket.deliverTyping(
        thread: const ChatThread.delivery('del-1'),
        userId: 'rider-1',
        isTyping: true,
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.isPeerTyping.value, isTrue);
    });

    test('announces the customer typing to the courier', () async {
      final controller = await openDelivery();

      controller.inputController.text = 'I am round the back';

      expect(socket.announced.where((it) => it).length, 1);
    });

    test('a consultation typing does not move a courier thread', () async {
      // One socket carries both kinds; a delivery screen must ignore the
      // other conversation entirely.
      final controller = await openDelivery();

      socket.peerTypes(userId: 'rider-1', isTyping: true);
      await Future<void>.delayed(Duration.zero);

      expect(controller.isPeerTyping.value, isFalse);
    });
  });

  group('the dots at the end of the conversation', () {
    testWidgets('are drawn only while the other party writes', (tester) async {
      // Built directly rather than through `open`: awaiting a zero-duration
      // future inside `testWidgets` never returns, because fake async only
      // advances when the tester pumps.
      final controller = ChatController(
        peer: _peer,
        repository: _Repository(),
        socket: socket,
        picker: _Picker(),
        uploader: _Uploader(),
      );
      controller.onInit();

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, _) => MaterialApp(
            home: Scaffold(
              body: Obx(
                () => controller.isPeerTyping.value
                    ? const TypingBubble()
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(TypingBubble), findsNothing);

      socket.peerTypes(userId: 'doctor-1', isTyping: true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(TypingBubble), findsOneWidget);

      // Closed inside the test rather than in a tear-down: the indicator holds
      // a five-second retraction timer, and the binding checks for pending
      // timers before tear-downs run.
      controller.onClose();
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('animate rather than sitting still', (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, _) =>
              const MaterialApp(home: Scaffold(body: TypingBubble())),
        ),
      );
      await tester.pump();

      Offset dotAt() => tester.getCenter(find.byType(Opacity).first);
      final first = dotAt();
      await tester.pump(const Duration(milliseconds: 200));
      final later = dotAt();

      // Three still dots read as a rendering artefact; the movement is what
      // says somebody is at the other end right now.
      expect(later, isNot(first));
      // Left running, so the widget must be disposed cleanly.
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
