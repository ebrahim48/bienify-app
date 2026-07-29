import 'dart:async';

import 'package:get/get.dart';

import '../../../../core/routes/app_routes.dart';
import '../../domain/entities/appointment.dart';

/// Backs the video consultation.
///
/// UI-only: there is no WebRTC session here. The feeds are images and the
/// controls toggle local state, so the screen can be walked and reviewed
/// before a calling SDK is wired in.
class VideoCallController extends GetxController {
  VideoCallController({required this.appointment});

  final Appointment appointment;

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
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => seconds.value++,
    );
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  void toggleMute() => isMuted.toggle();

  void toggleCamera() => isCameraOff.toggle();

  void openChat() => Get.toNamed<void>(AppRoutes.chat);

  /// Ending the call lands on the consultation summary, and `offNamed` keeps
  /// Back from returning to a call that is over.
  void endCall() => Get.offNamed<void>(AppRoutes.consultationHistory);
}
