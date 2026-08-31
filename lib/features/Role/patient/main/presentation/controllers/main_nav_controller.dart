import 'package:get/get.dart';

import '../../../../../../core/constants/app_icons.dart';
import '../../../../../../core/constants/app_strings.dart';
import '../../../appointments/presentation/controllers/appointments_controller.dart';
import '../../../home/presentation/controllers/home_controller.dart';
import '../../../pharmacy/presentation/controllers/pharmacy_controller.dart';

/// One destination in the bottom navigation.
class NavDestination {
  const NavDestination({
    required this.labelKey,
    required this.icon,
    this.badgeCount = 0,
  });

  final String labelKey;
  final String icon;

  /// Unread count drawn as a red badge on the icon; 0 hides it.
  final int badgeCount;

  NavDestination copyWith({int? badgeCount}) => NavDestination(
    labelKey: labelKey,
    icon: icon,
    badgeCount: badgeCount ?? this.badgeCount,
  );
}

/// Owns which tab is showing.
///
/// Kept separate from the individual tab controllers so switching tabs never
/// rebuilds or disposes their state.
class MainNavController extends GetxController {
  final RxInt currentIndex = 0.obs;

  final RxList<NavDestination> destinations = <NavDestination>[
    const NavDestination(labelKey: AppStrings.navHome, icon: AppIcons.home),
    const NavDestination(
      labelKey: AppStrings.navAppointments,
      icon: AppIcons.appointments,
    ),
    const NavDestination(
      labelKey: AppStrings.navDoctors,
      icon: AppIcons.doctors,
    ),
    const NavDestination(
      labelKey: AppStrings.navPharmacy,
      icon: AppIcons.pharmacy,
    ),
  ].obs;

  void select(int index) {
    if (index == currentIndex.value) return;
    currentIndex.value = index;
    _refreshTab(index);
  }

  /// Tabs sit in an `IndexedStack` (see `MainShellScreen`) so switching
  /// never rebuilds or disposes them — the point is to keep scroll position
  /// and in-progress state. Left alone, that also means whatever a tab
  /// fetched on the app's very first frame is what it shows for the rest of
  /// the session, since nothing else ever asks it to fetch again.
  /// Refetching into the same instance here fixes the staleness without
  /// touching that "never disposed" guarantee.
  void _refreshTab(int index) {
    switch (index) {
      case 0:
        if (Get.isRegistered<HomeController>()) {
          // Not `load()`: that flashes the whole feed back to a loading
          // skeleton, which is jarring on every tab switch. `refreshFeed()`
          // is the same pull-to-refresh call, keeping the feed on screen
          // while it reloads underneath.
          Get.find<HomeController>().refreshFeed();
        }
      case 1:
        if (Get.isRegistered<AppointmentsController>()) {
          Get.find<AppointmentsController>().load();
        }
      case 3:
        if (Get.isRegistered<PharmacyController>()) {
          Get.find<PharmacyController>().load();
        }
    }
  }

  /// Updates the badge on a destination, e.g. when the feed reports unread
  /// appointment activity.
  void setBadge(int index, int count) {
    if (index < 0 || index >= destinations.length) return;
    destinations[index] = destinations[index].copyWith(badgeCount: count);
  }
}
