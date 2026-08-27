import 'package:get/get.dart';

import '../../domain/entities/appointment.dart';
import '../controllers/video_call_controller.dart';

/// Bindings for the consultation screens.
///
/// The Appointments tab controller itself is created by `MainBinding`,
/// because the shell keeps every tab alive.
class VideoCallBinding extends Bindings {
  @override
  void dependencies() {
    // Opened without an appointment — a deep link, or a reload that dropped
    // the argument. This used to fall back to the sample booking, so the
    // patient joined a video call for a consultation with a doctor they had
    // never booked, at a time nobody had agreed.
    final appointment = Get.arguments;
    if (appointment is! Appointment) {
      Get.back<void>();
      return;
    }
    Get.put(VideoCallController(appointment: appointment));
  }
}
