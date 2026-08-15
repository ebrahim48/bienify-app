import 'dart:async';

import 'package:get/get.dart';

import '../../../../../../core/network/api_client.dart';
import '../../../../../../core/routes/app_routes.dart';
import '../../../../../../core/services/video_call_service.dart';
import '../../../chat/domain/entities/conversation.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/repositories/appointment_repository.dart';

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
    AppointmentRepository? appointments,
  }) : _service = service ?? AgoraVideoCallService(Get.find<ApiClient>()),
       _appointments = appointments;

  final Appointment appointment;

  /// Which side of the call this is. The screen is identical for both; only
  /// where the call ends differs.
  final bool isDoctor;

  final VideoCallService _service;

  /// Only needed to close the consultation, which only the doctor does, so it
  /// is resolved on use rather than required of every caller.
  final AppointmentRepository? _appointments;

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
      // The clock starts when the two of them first meet, and then runs to the
      // end of the call without pausing.
      //
      // It used to stop whenever this side lost the other, which sounds
      // right and is not: a blink either side sees — a dropped frame of
      // network, a re-join — pauses one clock and not the other, and the two
      // never agree again. Measured across a real call, one screen read 02:40
      // while the other read 03:38. A call timer that keeps counting through a
      // reconnection is also what every phone does.
      if (state.stage == CallStage.live) {
        _hasConnected = true;
        _startClock();
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

  /// Closes the consultation, without letting a failure interrupt leaving the
  /// call — the doctor is already on their way to the summary, and a booking
  /// that will not close is not something they can act on from there.
  Future<void> _completeQuietly() async {
    try {
      final repository = _appointments ?? Get.find<AppointmentRepository>();
      await repository.complete(appointment.id);
    } catch (_) {
      // Deliberately silent; see above.
    }
  }

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

    // The consultation has been held, so close it. Nothing else moves a
    // booking off `in_progress`, and one left there stays in the doctor's New
    // list still offering to be joined. The doctor's action alone: the server
    // refuses it from anyone else.
    if (isDoctor) unawaited(_completeQuietly());

    Get.offNamed<void>(
      isDoctor
          ? AppRoutes.doctorConsultationDone
          : AppRoutes.consultationHistory,
    );
  }
}
