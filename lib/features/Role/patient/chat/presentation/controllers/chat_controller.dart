import 'dart:async';

import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../../core/models/chat_thread.dart';
import '../../../../../../core/network/mappers.dart';
import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/network/attachment_uploader.dart';
import '../../../../../../core/network/socket_service.dart';
import '../../../../../../core/network/token_store.dart';
import '../../../../../../core/routes/app_routes.dart';
import '../../../../../../core/services/attachment_picker_service.dart';
import '../../../../../../core/services/call_service.dart';
import '../../../appointments/domain/entities/appointment.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../../data/static/chat_mock_data.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/conversation_repository.dart';
import '../screens/media_viewer_screen.dart';

/// Backs the message thread.
///
/// One controller for both conversations the app has: a consultation between
/// a patient and their doctor, and a delivery between a customer and their
/// courier. The server serves both from one set of events, so the only thing
/// that differs here is which id names the thread — held by [ChatThread].
///
/// A thread opened outside either — support, a doctor the patient has not
/// booked — has nowhere to send to and falls back to the sample conversation.
class ChatController extends GetxController {
  ChatController({
    required this.peer,
    ConversationRepository? repository,
    SocketService? socket,
    AttachmentPickerService? picker,
    AttachmentUploader? uploader,
  }) : _repository = repository ?? Get.find<ConversationRepository>(),
       _socket = socket ?? Get.find<SocketService>(),
       _picker = picker ?? Get.find<AttachmentPickerService>(),
       _uploader = uploader ?? Get.find<AttachmentUploader>();

  final ConversationPeer peer;

  final ConversationRepository _repository;
  final SocketService _socket;
  final AttachmentPickerService _picker;
  final AttachmentUploader _uploader;

  /// True when there is a real conversation behind this screen.
  bool get isLive => peer.thread?.isLive ?? false;

  /// The conversation this screen is bound to. Only read once [isLive].
  ChatThread get _thread => peer.thread!;

  final RxBool isLoading = true.obs;
  final RxBool isSending = false.obs;
  final RxnString error = RxnString();

  final TextEditingController inputController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxBool canSend = false.obs;

  Timer? _replyTimer;
  Timer? _typingDebounce;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  /// True while the other party is typing, for the indicator under the header.
  final RxBool isPeerTyping = false.obs;

  /// The message being rewritten, or null when the composer is sending a new
  /// one. Held rather than a bare flag so the composer can show what is being
  /// changed and `send` knows which row to replace.
  final Rxn<ChatMessage> editing = Rxn<ChatMessage>();

  /// The other party's presence, shown as "Online" or "last seen …".
  final Rxn<PresenceState> peerPresence = Rxn<PresenceState>();

  /// How long a `typing:start` stands before it is retracted.
  ///
  /// Typing is fire-and-forget — the stop event can be lost, or the sender can
  /// background the app mid-word — so the indicator expires on its own rather
  /// than sticking on forever.
  static const Duration _typingTimeout = Duration(seconds: 5);
  Timer? _peerTypingExpiry;

  @override
  void onInit() {
    super.onInit();
    inputController.addListener(_onInputChanged);
    load();
    // The thread opens at the newest message, as a chat should.
    WidgetsBinding.instance.addPostFrameCallback((_) => jumpToLatest());
    if (isLive) _listen();
  }

  /// Subscribes to the socket for this thread.
  ///
  /// Replaces a three-second poll: the other side's messages now arrive when
  /// they are sent rather than up to three seconds later, and an idle thread
  /// costs nothing instead of twenty requests a minute.
  void _listen() {
    final thread = _thread;
    _socket
      ..connect()
      ..joinThread(thread);

    _subscriptions.addAll([
      _socket.messages.listen((json) => _onMessage(json, thread)),
      _socket.edits.listen((json) => _onEdit(json, thread)),
      _socket.receipts.listen((receipt) {
        if (receipt.thread == thread) _onReceipt(receipt);
      }),
      _socket.typing.listen((event) {
        // Only the other party's typing; our own echo is not sent back, but
        // a second device of ours would be.
        if (event.thread != thread) return;
        if (event.userId == peer.id) _setPeerTyping(event.isTyping);
      }),
      _socket.presence.listen((state) {
        if (state.userId == peer.id) peerPresence.value = state;
      }),
      // A reconnect re-joins rooms but cannot replay what was missed while the
      // socket was down, so the thread re-reads once it is back.
      _socket.connectionState.listen((isUp) {
        if (isUp) unawaited(_reconcile());
      }),
    ]);

    unawaited(_loadPresence());
  }

  /// True on a consultation thread, which is the only kind with a room to
  /// call into. A courier and their customer message; they do not consult.
  bool get canCall => isLive && _thread.isConsultation;

  /// Rings the other party, from the thread they are already in.
  ///
  /// The consultation is the call *and* the conversation, so the two are
  /// reachable from each other rather than being separate things a booking had
  /// to choose between.
  void startVideoCall() {
    if (!canCall) return;
    Get.find<CallService>().ring(
      // The call screen reads an `Appointment`; the thread already carries
      // everything it draws.
      Appointment(
        id: _thread.id,
        doctorName: peer.name,
        specialty: peer.specialty,
        scheduledAt: DateTime.now(),
        doctorPhotoUrl: peer.photoUrl,
      ),
      callee: CallParty(
        id: peer.id,
        name: peer.name,
        avatarUrl: peer.photoUrl,
      ),
    );
  }

  Future<void> _loadPresence() async {
    final state = await _socket.queryPresence(peer.id);
    if (state != null) peerPresence.value = state;
  }

  /// A message arrived — ours echoed back, or theirs.
  void _onMessage(Map<String, dynamic> json, ChatThread thread) {
    // Both kinds arrive on one event, so a screen watching a delivery must
    // ignore a consultation's messages and the other way round.
    if (ChatThread.fromJson(json) != thread) return;

    final incoming = chatMessageFrom(json, _myIdFor(json));
    final clientId = incoming.clientId;

    // Our own optimistic bubble coming back: replace it in place rather than
    // appending, or the message shows twice until the next reload.
    if (clientId != null) {
      final pending = messages.indexWhere((m) => m.clientId == clientId);
      if (pending != -1) {
        messages[pending] = incoming;
        return;
      }
    }

    if (messages.any((m) => m.id == incoming.id)) return;

    final shouldFollow = _isNearBottom;
    messages.add(incoming);
    if (shouldFollow) _scrollToLatest();

    // Their message, and this thread is open — so it is both delivered and
    // being read right now.
    if (!incoming.isMine) _socket.markRead(thread);
  }

  /// The sender rewrote a message: replace it where it stands.
  ///
  /// Its own handler rather than the arrival path, which appends and reports
  /// the message read — neither of which a rewrite of words already on screen
  /// should do.
  void _onEdit(Map<String, dynamic> json, ChatThread thread) {
    if (ChatThread.fromJson(json) != thread) return;

    final edited = chatMessageFrom(json, _myIdFor(json));
    final index = messages.indexWhere((m) => m.id == edited.id);
    if (index == -1) return;

    // The receipts this device already knows about are kept: the server sends
    // the message, not the reader's state, so taking its word for those would
    // drop a bubble from Seen back to Delivered.
    final current = messages[index];
    messages[index] = current.copyWith(
      text: edited.text,
      editedAt: edited.editedAt,
      reactions: edited.reactions,
    );
  }

  /// Whether a payload was sent by us, decided the same way the mapper does.
  String _myIdFor(Map<String, dynamic> json) =>
      '${json['senderId'] ?? ''}' == peer.id ? '' : '${json['senderId'] ?? ''}';

  void _onReceipt(ReceiptState receipt) {
    final ids = receipt.messageIds.toSet();
    final now = DateTime.now();
    for (var i = 0; i < messages.length; i++) {
      final message = messages[i];
      if (!message.isMine || !ids.contains(message.id)) continue;
      messages[i] = receipt.isRead
          ? message.copyWith(readAt: now, deliveredAt: message.deliveredAt ?? now)
          : message.copyWith(deliveredAt: now);
    }
  }

  void _setPeerTyping(bool isTyping) {
    final wasTyping = isPeerTyping.value;
    isPeerTyping.value = isTyping;
    _peerTypingExpiry?.cancel();
    if (isTyping) {
      _peerTypingExpiry = Timer(_typingTimeout, () => isPeerTyping.value = false);
      // The dots are drawn past the last message, so someone sitting at the
      // bottom of the thread would otherwise have them appear just under the
      // fold — the one place they are no use. Anyone who has scrolled up is
      // left where they are, as they are for an arriving message.
      if (!wasTyping && _isNearBottom) _scrollToLatest();
    }
  }

  /// Re-reads the thread after a reconnect, since events sent while the socket
  /// was down are gone rather than queued.
  Future<void> _reconcile() async {
    if (!isLive) return;
    try {
      final latest = await _repository.messages(_thread);
      final known = messages.map((m) => m.id).toSet();
      final arrived = latest.where((m) => !known.contains(m.id)).toList();
      if (arrived.isEmpty) return;
      final shouldFollow = _isNearBottom;
      messages.addAll(arrived);
      if (shouldFollow) _scrollToLatest();
    } on AppException {
      // Nothing to say over an open thread; the messages already read are
      // still on screen and the next reconnect tries again.
    }
  }

  /// Within a screenful of the newest message.
  bool get _isNearBottom {
    if (!scrollController.hasClients) return true;
    final position = scrollController.position;
    return position.maxScrollExtent - position.pixels < 120;
  }

  Future<void> load() async {
    if (!isLive) {
      messages.value = ChatMockData.thread();
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    error.value = null;
    try {
      messages.value = await _repository.messages(_thread);
      // Opening the thread is reading it.
      _socket.markRead(_thread);
    } on AppException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
    _scrollToLatest();
  }

  @override
  void onClose() {
    if (isLive) {
      // Stop any indicator we left showing on the other side.
      _socket
        ..setTyping(_thread, isTyping: false)
        ..leaveThread(_thread);
    }
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _replyTimer?.cancel();
    _typingDebounce?.cancel();
    _peerTypingExpiry?.cancel();
    inputController
      ..removeListener(_onInputChanged)
      ..dispose();
    scrollController.dispose();
    super.onClose();
  }

  void _onInputChanged() {
    canSend.value = inputController.text.trim().isNotEmpty;
    _announceTyping();
  }

  /// Tells the other side we are typing, and retracts it once we stop.
  ///
  /// Debounced rather than emitted per keystroke: a `typing:start` per
  /// character would be dozens of events a sentence, all saying the same
  /// thing. The stop is what the timer is really for.
  void _announceTyping() {
    if (!isLive) return;
    final thread = _thread;

    if (inputController.text.trim().isEmpty) {
      _typingDebounce?.cancel();
      _socket.setTyping(thread, isTyping: false);
      return;
    }

    if (_typingDebounce?.isActive != true) {
      _socket.setTyping(thread, isTyping: true);
    }
    _typingDebounce?.cancel();
    _typingDebounce = Timer(
      const Duration(seconds: 2),
      () => _socket.setTyping(thread, isTyping: false),
    );
  }

  /// Whether [message] can still be rewritten, right now.
  ///
  /// Asked at the moment the menu opens rather than stored on the row, so a
  /// bubble that has aged past the window while the thread sat open does not
  /// still offer an edit the server would refuse.
  bool canEdit(ChatMessage message) =>
      isLive && message.canEditAt(DateTime.now());

  /// Puts the composer into edit mode for [message].
  void beginEdit(ChatMessage message) {
    if (!canEdit(message)) return;
    editing.value = message;
    inputController.text = message.text;
    inputController.selection = TextSelection.collapsed(
      offset: inputController.text.length,
    );
  }

  /// Leaves edit mode without changing anything.
  void cancelEdit() {
    if (editing.value == null) return;
    editing.value = null;
    inputController.clear();
  }

  /// Commits the rewrite the composer is holding.
  ///
  /// The bubble changes here rather than waiting for the echo, for the same
  /// reason a sent message is drawn before the server has it — and it is safe
  /// for the same reason: the echo replaces this row rather than adding one.
  Future<void> _commitEdit(ChatMessage target, String text) async {
    editing.value = null;
    inputController.clear();

    final index = messages.indexWhere((m) => m.id == target.id);
    if (index != -1 && messages[index].text != text) {
      messages[index] = messages[index].copyWith(
        text: text,
        editedAt: DateTime.now(),
      );
    }

    _typingDebounce?.cancel();
    _socket
      ..setTyping(_thread, isTyping: false)
      ..editMessage(thread: _thread, messageId: target.id, body: text);
  }

  Future<void> send() async {
    final text = inputController.text.trim();
    if (text.isEmpty || isSending.value) return;

    // In edit mode the composer rewrites a bubble instead of adding one.
    final target = editing.value;
    if (target != null) {
      await _commitEdit(target, text);
      return;
    }

    if (!isLive) {
      _sendLocally(text);
      return;
    }

    final thread = _thread;
    final clientId = 'c-${DateTime.now().microsecondsSinceEpoch}';

    // Shown immediately, marked pending.
    //
    // The previous version waited for the server before drawing anything,
    // which made every message feel as slow as the round trip. The bubble is
    // safe to show early *because* `clientId` lets the stored row replace it
    // rather than duplicate it — and because a send that never lands is
    // removed again below rather than left looking delivered.
    final optimistic = ChatMessage(
      id: clientId,
      text: text,
      sentAt: DateTime.now(),
      author: MessageAuthor.me,
      isPending: true,
      clientId: clientId,
    );
    messages.add(optimistic);
    inputController.clear();
    _scrollToLatest();

    _typingDebounce?.cancel();
    _socket.setTyping(thread, isTyping: false);

    isSending.value = true;
    try {
      final viaSocket = await _socket.sendMessage(
        thread: thread,
        body: text,
        clientId: clientId,
      );
      // The socket echoes `message:new` to the room, and `_onMessage` swaps
      // the pending bubble for the stored row. Nothing more to do here.
      if (viaSocket != null) return;

      // Socket down or the ack never came. The same `clientId` goes over HTTP,
      // so if the socket send did land after all, the server returns that same
      // message instead of storing a second one.
      final stored = await _repository.send(
        thread: thread,
        body: text,
        clientId: clientId,
      );
      final index = messages.indexWhere((m) => m.clientId == clientId);
      if (index != -1) messages[index] = stored;
    } on AppException catch (e) {
      // Take the bubble back rather than leave a message on screen that the
      // server never accepted.
      messages.removeWhere((m) => m.clientId == clientId);
      AppSnackbar.error(e.message);
    } finally {
      isSending.value = false;
    }
  }

  /// The sample thread's behaviour: append the outgoing bubble and schedule a
  /// reply, so a chat with nothing behind it still exercises both styles.
  void _sendLocally(String text) {
    messages.add(
      ChatMessage(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        text: text,
        sentAt: DateTime.now(),
        author: MessageAuthor.me,
      ),
    );
    inputController.clear();
    _scrollToLatest();

    _replyTimer?.cancel();
    _replyTimer = Timer(const Duration(milliseconds: 900), () {
      messages.add(ChatMockData.autoReply());
      _scrollToLatest();
    });
  }

  /// The newest of my messages the other side has read.
  ///
  /// Messenger shows the reader's face against exactly one bubble rather than
  /// a tick on every one, so this is the only id the seen marker is drawn on.
  String? get lastReadByPeerId {
    for (var i = messages.length - 1; i >= 0; i--) {
      final message = messages[i];
      if (message.isMine && message.readAt != null) return message.id;
    }
    return null;
  }

  /// Sets, replaces or clears my reaction to a message.
  ///
  /// Applied locally first: the round trip is a few hundred milliseconds and a
  /// reaction that lags behind the tap feels broken. The server echoes the
  /// whole message back, which overwrites this with the authoritative list.
  void react(ChatMessage message, String emoji) {
    if (!isLive) return;

    final mine = message.reactions
        .where((r) => r.userId == _myUserId)
        .firstOrNull;
    // The picker returns an empty string when the reader taps the reaction
    // they already had, and the same emoji twice is the same intent — both
    // clear, which is what the server does too.
    final next = (emoji.isEmpty || mine?.emoji == emoji) ? null : emoji;

    final index = messages.indexWhere((m) => m.id == message.id);
    if (index != -1) {
      messages[index] = messages[index].copyWith(
        reactions: [
          ...message.reactions.where((r) => r.userId != _myUserId),
          if (next != null) MessageReaction(userId: _myUserId, emoji: next),
        ],
      );
    }

    _socket.react(
      thread: _thread,
      messageId: message.id,
      kind: next,
    );
  }

  /// Opens [message]'s attachment full screen.
  ///
  /// Hands the viewer every viewable attachment in the thread, not just this
  /// one, so it can page sideways through the conversation's media the way a
  /// gallery does. An attachment still uploading is skipped: it has no signed
  /// URL yet and would open on a blank page.
  void openMedia(ChatMessage message) {
    final items = <MediaItem>[];
    var initialIndex = 0;

    for (final candidate in messages) {
      if (candidate.uploadProgress != null) continue;
      final item = MediaItem.fromMessage(candidate);
      if (item == null) continue;
      if (candidate.id == message.id) initialIndex = items.length;
      items.add(item);
    }

    if (items.isEmpty) return;
    Get.toNamed<void>(
      AppRoutes.mediaViewer,
      arguments: MediaViewerArgs(items: items, initialIndex: initialIndex),
    );
  }

  /// Who "my" reactions belong to, from the access token's `sub` claim.
  ///
  /// This used to be a field that was declared and then never assigned, so it
  /// stayed empty: no stored reaction ever matched it, my own reaction was
  /// never found, and the second tap that should have removed it added it
  /// again instead. The server's own toggle hid most of it — the round trip
  /// corrected the list a moment later — which is why it survived so long.
  late final String _myUserId = Get.find<TokenStore>().userId ?? '';

  /// Picks a file and sends it.
  ///
  /// The bubble appears immediately with its upload progress, so a large video
  /// shows something happening rather than an unresponsive button. A failed or
  /// cancelled upload takes the bubble away again rather than leaving a
  /// message that was never sent.
  Future<void> attach(AttachmentSource source) async {
    if (!isLive) {
      AppSnackbar.info(AppStrings.attachmentsNeedConsultation.tr);
      return;
    }

    final picked = await _picker.pick(source);
    if (picked == null) return;

    if (picked.size > AttachmentPickerService.maxBytes) {
      AppSnackbar.error(AppStrings.fileTooLarge.tr);
      return;
    }

    final thread = _thread;
    final clientId = 'a-${DateTime.now().microsecondsSinceEpoch}';
    final cancelToken = CancelToken();
    _uploads[clientId] = cancelToken;

    messages.add(
      ChatMessage(
        id: clientId,
        text: '',
        sentAt: DateTime.now(),
        author: MessageAuthor.me,
        isPending: true,
        clientId: clientId,
        kind: _kindOf(picked.mime),
        attachment: MessageAttachment(
          name: picked.name,
          mime: picked.mime,
          size: picked.size,
          // The local file, so the preview shows before the upload finishes.
          url: picked.file.path,
          width: picked.width,
          height: picked.height,
        ),
        uploadProgress: 0,
      ),
    );
    _scrollToLatest();

    try {
      final uploaded = await _uploader.upload(
        thread: thread,
        attachment: picked,
        cancelToken: cancelToken,
        onProgress: (progress) {
          final index = messages.indexWhere((m) => m.clientId == clientId);
          if (index != -1) {
            messages[index] = messages[index].copyWith(uploadProgress: progress);
          }
        },
      );

      final sent = await _socket.sendMessage(
        thread: thread,
        body: '',
        clientId: clientId,
        attachment: uploaded.toJson(),
      );

      // The socket echoes `message:new`, which swaps the pending bubble for
      // the stored row. Only fall back to HTTP when it did not.
      if (sent == null) {
        final stored = await _repository.send(
          thread: thread,
          body: '',
          clientId: clientId,
          attachment: uploaded.toJson(),
        );
        final index = messages.indexWhere((m) => m.clientId == clientId);
        if (index != -1) messages[index] = stored;
      }
    } on AppException catch (e) {
      messages.removeWhere((m) => m.clientId == clientId);
      AppSnackbar.error(e.message);
    } catch (_) {
      // Cancelled, or the transfer failed. Either way the bubble goes.
      messages.removeWhere((m) => m.clientId == clientId);
    } finally {
      _uploads.remove(clientId);
    }
  }

  /// Abandons an upload still in flight.
  void cancelUpload(ChatMessage message) {
    final clientId = message.clientId;
    if (clientId == null) return;
    _uploads[clientId]?.cancel('cancelled by sender');
  }

  final Map<String, CancelToken> _uploads = {};

  static MessageKind _kindOf(String mime) {
    if (mime.startsWith('image/')) return MessageKind.image;
    if (mime.startsWith('video/')) return MessageKind.video;
    if (mime.startsWith('audio/')) return MessageKind.audio;
    return MessageKind.file;
  }

  void jumpToLatest() {
    if (!scrollController.hasClients) return;
    scrollController.jumpTo(scrollController.position.maxScrollExtent);
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }
}
