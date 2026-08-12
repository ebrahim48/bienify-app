import 'package:get/get.dart';

import '../controllers/shop_home_controller.dart';
import '../controllers/shop_medicines_controller.dart';
import '../controllers/shop_notifications_controller.dart';
import '../controllers/shop_orders_controller.dart';
import '../controllers/shop_profile_controller.dart';
import '../controllers/shop_shell_controller.dart';

/// Route bindings for the pharmacy owner's section.

/// The shell and its four tabs are created together, because the shell keeps
/// every tab alive in an `IndexedStack` and each paints immediately.
class ShopShellBinding extends Bindings {
  @override
  void dependencies() {
    Get
      ..put(ShopShellController())
      ..put(ShopHomeController())
      ..put(ShopOrdersController())
      ..put(ShopMedicinesController())
      ..put(ShopProfileController());
  }
}

/// Order Details reads the row the list selected, so it only needs the
/// shell's controller — already registered when reached from a tab. This
/// covers entering the route directly.
class ShopOrdersBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<ShopOrdersController>()) return;
    Get.put(ShopOrdersController());
  }
}

class ShopMedicinesBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<ShopMedicinesController>()) return;
    Get.put(ShopMedicinesController());
  }
}

class ShopProfileBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<ShopProfileController>()) return;
    Get.put(ShopProfileController());
  }
}

/// The feed is its own screen off the dashboard's bell, and its own read —
/// the shell's tabs do not need it, so it is not created with them.
class ShopNotificationsBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ShopNotificationsController());
  }
}
