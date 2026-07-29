import 'package:get/get.dart';

import '../../data/static/appointment_mock_data.dart';
import '../../domain/entities/appointment.dart';
import '../controllers/video_call_controller.dart';

/// Bindings for the consultation screens.
///
/// The Appointments tab controller itself is created by `MainBinding`,
/// because the shell keeps every tab alive.
class VideoCallBinding extends Bindings {
  @override
  void dependencies() {
    // Opening the call without an appointment (a deep link, or the Home
    // shortcut) falls back to the sample booking rather than crashing.
    Get.put(
      VideoCallController(
        appointment: Get.arguments is Appointment
            ? Get.arguments as Appointment
            : AppointmentMockData.upcoming().first,
      ),
    );
  }
}
