import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_icons.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../../../patient/main/presentation/controllers/main_nav_controller.dart';
import '../../../patient/main/presentation/widgets/app_bottom_nav_bar.dart';
import '../controllers/rider_shell_controller.dart';
import 'rider_earnings_screen.dart';
import 'rider_home_screen.dart';
import 'rider_orders_screen.dart';
import 'rider_profile_screen.dart';

/// The courier's shell: Home, Orders, Earnings, Profile.
///
/// Reuses `AppBottomNavBar` and `NavDestination` from the patient shell — the
/// bar is already generic over its destinations, so only the four entries
/// differ. `RiderShellController` is separate from the other three shells'
/// controllers so switching tabs in one never disturbs another.
class RiderShellScreen extends GetView<RiderShellController> {
  const RiderShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final index = controller.index;
      return AppScaffold(
        padded: false,
        scrollable: false,
        bottomBar: AppBottomNavBar(
          currentIndex: index,
          destinations: const [
            NavDestination(labelKey: AppStrings.navHome, icon: AppIcons.home),
            NavDestination(
              labelKey: AppStrings.navOrders,
              icon: AppIcons.shoppingBag,
            ),
            NavDestination(
              labelKey: AppStrings.navEarnings,
              icon: AppIcons.wallet,
            ),
            NavDestination(
              labelKey: AppStrings.navProfile,
              icon: AppIcons.person,
            ),
          ],
          onSelected: controller.selectIndex,
        ),
        // `IndexedStack` so a tab keeps its scroll position and its
        // controller, the same arrangement as the other three shells.
        child: IndexedStack(
          index: index,
          children: const [
            RiderHomeScreen(),
            RiderOrdersScreen(),
            RiderEarningsScreen(),
            RiderProfileScreen(),
          ],
        ),
      );
    });
  }
}
