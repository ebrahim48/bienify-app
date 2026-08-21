import 'dart:async';

import 'package:get/get.dart';

import '../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../core/network/socket_service.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../patient/chat/domain/entities/conversation.dart';
import '../../domain/entities/doctor_practice.dart';
import '../../domain/repositories/doctor_practice_repository.dart';

/// Backs the doctor's Message tab.
///
/// Opening a thread reuses the patient app's `ChatScreen` with the patient as
/// its `ConversationPeer` — one messaging screen serves both roles.
class DoctorMessagesController extends GetxController {
  DoctorMessagesController({
    DoctorPracticeRepository? repository,
    SocketService? socket,
  }) : _repository = repository ?? Get.find<DoctorPracticeRepository>(),
       _socket = socket ?? Get.find<SocketService>();

  final DoctorPracticeRepository _repository;
  final SocketService _socket;

  final RxList<PatientThread> threads = <PatientThread>[].obs;

  final RxString query = ''.obs;

  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();

  /// Which patients are connected right now, keyed by their user id. Mirrors
  /// the patient list's own dots — the same fact, read the same way.
  final RxMap<String, bool> presence = <String, bool>{}.obs;

  final List<StreamSubscription<dynamic>> _subscriptions = [];

  @override
  void onInit() {
    super.onInit();
    load();
    _watchPresence();
  }

  void _watchPresence() {
    _socket.connect();
    _subscriptions.addAll([
      _socket.presence.listen(
        (state) => presence[state.userId] = state.isOnline,
      ),
      // A reconnect drops room membership, and re-joining is what restores
      // the presence feed for these threads.
      _socket.connectionState.listen((isUp) {
        if (isUp) _subscribeToThreads();
      }),
    ]);
  }

  /// Joins each thread's room, then reads its patient's presence once —
  /// presence is only published on change, so somebody already online when
  /// this tab opened would otherwise never report in.
  void _subscribeToThreads() {
    for (final thread in threads) {
      if (thread.id.isNotEmpty) _socket.joinThread(thread.id);

      final patientId = thread.patientUserId;
      if (patientId.isEmpty) continue;
      unawaited(
        _socket.queryPresence(patientId).then((state) {
          if (state != null) presence[state.userId] = state.isOnline;
        }),
      );
    }
  }

  /// Null while unknown, so the row draws no dot rather than claiming the
  /// patient is offline.
  bool? isPatientOnline(PatientThread thread) => presence[thread.patientUserId];

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      threads.value = await _repository.threads();
      _subscribeToThreads();
    } on AppException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.onClose();
  }

  List<PatientThread> get visible {
    final search = query.value.trim().toLowerCase();
    if (search.isEmpty) return threads.toList();
    return threads
        .where((t) => t.patientName.toLowerCase().contains(search))
        .toList();
  }

  void openThread(PatientThread thread) {
    Get.toNamed<void>(
      AppRoutes.chat,
      arguments: ConversationPeer(
        // The patient's user id, not the appointment's: presence and typing
        // are addressed per user, and passing the thread id here made the
        // header ask about a user that does not exist.
        id: thread.patientUserId.isEmpty ? thread.id : thread.patientUserId,
        // A thread is keyed by its consultation, which is what makes the
        // messages behind it real rather than the sample conversation.
        appointmentId: thread.id,
        name: thread.patientName,
        // The doctor's side of the header shows why the patient is here, and
        // the preview is the nearest thing the list carries.
        specialty: thread.preview,
        photoUrl: thread.photoUrl,
        photoAsset: thread.photoAsset,
        // Left to the socket rather than asserted here: the header reads live
        // presence, and seeding it `true` made every patient look online.
      ),
    );
  }
}
