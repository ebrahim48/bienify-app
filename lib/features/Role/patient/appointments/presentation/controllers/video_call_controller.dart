import 'dart:async';

import 'package:get/get.dart';

import '../../../../../../core/network/api_client.dart';
import '../../../../../../core/routes/app_routes.dart';
import '../../../../../../core/services/video_call_service.dart';
import '../../../chat/domain/entities/conversation.dart';
import '../../domain/entities/appointment.dart';

/// Backs the video consultation.
///
/// The call is real: [VideoCallService] joins the Agora channel the server
/// opens for this appointment. This controller owns when that happens and
/// what the screen is told about it.
class VideoCallController extends GetxController {
  VideoCallController({
    required this.appointment,
    this.isDoctor = false,
    VideoCallService? service,
  }) : _service = service ?? AgoraVideoCallService(Get.find<ApiClient>());

  final Appointment appointment;

  /// Which side of the call this is. The screen is identical for both; only
  /// where the call ends differs.
  final bool isDoctor;

  final VideoCallService _service;

  VideoCallService get service => _service;

  final RxInt seconds = 0.obs;
  final RxBool isMuted = false.obs;
  final RxBool isCameraOff = false.obs;

  final Rx<CallState> call = const CallState().obs;

  Timer? _timer;
  StreamSubscription<CallState>? _subscription;

  /// `00:03`.
  String get durationLabel {
    final minutes = (seconds.value ~/ 60).toString().padLeft(2, '0');
    final remainder = (seconds.value % 60).toString().padLeft(2, '0');
    return '$minutes:$remainder';
  }

  @override
  void onInit() {
    super.onInit();

    _subscription = _service.states.listen((state) {
      call.value = state;
      // The clock measures the consultation — the time the two of them were
      // actually together — so it runs only while both are in the channel.
      // Starting it on join instead would give each side a different figure,
      // counting however long they each waited for the other.
      if (state.stage == CallStage.live) {
        _hasConnected = true;
        _startClock();
      } else {
        _pauseClock();
      }

      // The other side hung up. A call only one person has left is not a call,
      // so this side leaves too rather than sitting on a dead channel.
      if (state.stage == CallStage.ended) endCall();
    });

    unawaited(_service.join(appointment.id));
  }

  void _startClock() {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => seconds.value++);
  }

  /// Holds the count where it is. If the other party drops and comes back the
  /// consultation resumes rather than restarting, so the total still reflects
  /// the time spent together.
  void _pauseClock() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void onClose() {
    _timer?.cancel();
    unawaited(_subscription?.cancel());
    unawaited(_service.dispose());
    super.onClose();
  }

  Future<void> toggleMute() async {
    isMuted.toggle();
    await _service.setMuted(isMuted.value);
  }

  Future<void> toggleCamera() async {
    isCameraOff.toggle();
    await _service.setCameraOff(isCameraOff.value);
  }

  Future<void> switchCamera() => _service.switchCamera();

  /// The thread beside the call is the consultation's own, so it carries the
  /// appointment — which is what makes its messages real rather than the
  /// sample conversation.
  void openChat() => Get.toNamed<void>(
    AppRoutes.chat,
    arguments: ConversationPeer(
      id: appointment.id,
      appointmentId: appointment.id,
      name: appointment.doctorName,
      specialty: appointment.specialty,
      photoUrl: appointment.doctorPhotoUrl,
      isOnline: true,
    ),
  );

  /// Ending the call lands on the consultation summary — the doctor's own,
  /// which offers to write the prescription. `offNamed` keeps Back from
  /// returning to a call that is over.
  /// Guarded because both sides can reach it at once: the local hang-up and
  /// the peer's `ended` arriving together would otherwise push the summary
  /// twice and leave a screen stranded on the stack.
  bool _hasLeft = false;

  /// Whether the two of them were ever in the room together.
  bool _hasConnected = false;

  void endCall() {
    if (_hasLeft) return;
    _hasLeft = true;

    // Hanging up on a call nobody answered is not a finished consultation, so
    // it does not land on the summary that congratulates the doctor and
    // offers to write a prescription. It just goes back.
    if (!_hasConnected) {
      Get.back<void>();
      return;
    }

    Get.offNamed<void>(
      isDoctor
          ? AppRoutes.doctorConsultationDone
          : AppRoutes.consultationHistory,
    );
  }
}
