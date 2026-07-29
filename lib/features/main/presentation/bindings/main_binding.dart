import 'package:get/get.dart';

import '../../../appointments/presentation/controllers/appointments_controller.dart';
import '../../../doctors/presentation/controllers/find_doctor_controller.dart';
import '../../../home/domain/usecases/home_usecases.dart';
import '../../../home/presentation/controllers/home_controller.dart';
import '../../../pharmacy/presentation/controllers/pharmacy_controller.dart';
import '../controllers/main_nav_controller.dart';

/// Everything the signed-in shell needs.
///
/// All four tab controllers are created up front because the shell keeps the
/// tabs alive in an `IndexedStack` — a lazily bound controller would be built
/// on first paint anyway, and eager creation keeps tab switches instant.
class MainBinding extends Bindings {
  @override
  void dependencies() {
    Get
      ..put(MainNavController())
      ..put(HomeController(getHomeFeed: Get.find<GetHomeFeed>()))
      ..put(AppointmentsController())
      ..put(FindDoctorController())
      ..put(PharmacyController());
  }
}
