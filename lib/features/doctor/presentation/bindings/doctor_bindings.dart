import 'package:get/get.dart';

import '../controllers/doctor_home_controller.dart';
import '../controllers/doctor_schedule_controller.dart';
import '../controllers/doctor_shell_controller.dart';

/// Route bindings for the practitioner section.

/// The shell and its Home tab are created together, because the shell keeps
/// every tab alive in an `IndexedStack` and Home paints immediately.
class DoctorShellBinding extends Bindings {
  @override
  void dependencies() {
    Get
      ..put(DoctorShellController())
      ..put(DoctorHomeController());
  }
}

/// Set Schedule owns its own editing state; the dashboard controller stays
/// registered underneath it.
class DoctorScheduleBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(DoctorScheduleController());
  }
}
