import 'package:get/get.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_strings.dart';

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
  }

  /// Updates the badge on a destination, e.g. when the feed reports unread
  /// appointment activity.
  void setBadge(int index, int count) {
    if (index < 0 || index >= destinations.length) return;
    destinations[index] = destinations[index].copyWith(badgeCount: count);
  }
}
