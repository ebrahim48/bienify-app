import 'dart:async';

import 'package:get/get.dart';

import '../../../../../../core/routes/app_routes.dart';
import '../../../chat/domain/entities/conversation.dart';
import '../../domain/entities/appointment.dart';

/// Backs the video consultation.
///
/// UI-only: there is no WebRTC session here. The feeds are images and the
/// controls toggle local state, so the screen can be walked and reviewed
/// before a calling SDK is wired in.
class VideoCallController extends GetxController {
  VideoCallController({required this.appointment, this.isDoctor = false});

  final Appointment appointment;

  /// Which side of the call this is. The screen is identical for both; only
  /// where the call ends differs.
  final bool isDoctor;

  final RxInt seconds = 0.obs;
  final RxBool isMuted = false.obs;
  final RxBool isCameraOff = false.obs;

  Timer? _timer;

  /// `00:03`.
  String get durationLabel {
    final minutes = (seconds.value ~/ 60).toString().padLeft(2, '0');
    final remainder = (seconds.value % 60).toString().padLeft(2, '0');
    return '$minutes:$remainder';
  }

  @override
  void onInit() {
    super.onInit();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => seconds.value++);
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  void toggleMute() => isMuted.toggle();

  void toggleCamera() => isCameraOff.toggle();

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
  void endCall() => Get.offNamed<void>(
    isDoctor ? AppRoutes.doctorConsultationDone : AppRoutes.consultationHistory,
  );
}
