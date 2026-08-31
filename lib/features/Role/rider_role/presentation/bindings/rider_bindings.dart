import 'package:get/get.dart';

import '../controllers/rider_application_controller.dart';
import '../controllers/rider_guide_controller.dart';
import '../controllers/rider_home_controller.dart';
import '../controllers/rider_orders_controller.dart';
import '../controllers/rider_profile_controller.dart';
import '../controllers/rider_shell_controller.dart';

/// Route bindings for the courier's section.

/// The shell and its four tabs are created together, because the shell keeps
/// every tab alive in an `IndexedStack` and each paints immediately.
class RiderShellBinding extends Bindings {
  @override
  void dependencies() {
    Get
      ..put(RiderShellController())
      ..put(RiderHomeController())
      ..put(RiderOrdersController())
      ..put(RiderProfileController());
  }
}

/// The guide is reached before the shell exists — it is what an applicant
/// reads on their way into applying — so it puts up the one controller its
/// masthead needs rather than the whole shell.
///
/// That controller reads the *account*, not the courier profile. It put up
/// the dashboard's before, which asks the server for a courier the reader has
/// not become yet and is refused.
class RiderGuideBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(RiderGuideController());
  }
}

/// The application is its own flow, entered from the guide.
class RiderApplicationBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(RiderApplicationController());
  }
}

/// Tracking reads the job the list picked, so it only needs the shell's
/// controller — already registered when reached from a tab. This covers
/// entering the route directly.
class RiderOrdersBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<RiderOrdersController>()) return;
    Get.put(RiderOrdersController());
  }
}

class RiderProfileBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<RiderProfileController>()) return;
    Get.put(RiderProfileController());
  }
}
