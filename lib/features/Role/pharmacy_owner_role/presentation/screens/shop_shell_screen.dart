import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_icons.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../../../patient/main/presentation/controllers/main_nav_controller.dart';
import '../../../patient/main/presentation/widgets/app_bottom_nav_bar.dart';
import '../controllers/shop_shell_controller.dart';
import 'shop_home_screen.dart';
import 'shop_medicines_screen.dart';
import 'shop_orders_screen.dart';
import 'shop_profile_screen.dart';

/// The pharmacy owner's shell: Home, Orders, Medicines, Profile.
///
/// Reuses `AppBottomNavBar` and `NavDestination` from the patient shell — the
/// bar is already generic over its destinations, so only the four entries
/// differ. `ShopShellController` is separate from the other two shells'
/// controllers so switching tabs in one never disturbs another.
class ShopShellScreen extends GetView<ShopShellController> {
  const ShopShellScreen({super.key});

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
              labelKey: AppStrings.navMedicines,
              icon: AppIcons.pharmacy,
            ),
            NavDestination(
              labelKey: AppStrings.navProfile,
              icon: AppIcons.person,
            ),
          ],
          onSelected: controller.selectIndex,
        ),
        // `IndexedStack` so a tab keeps its scroll position and its
        // controller, the same arrangement as the other two shells.
        child: IndexedStack(
          index: index,
          children: const [
            ShopHomeScreen(),
            ShopOrdersScreen(),
            ShopMedicinesScreen(),
            ShopProfileScreen(),
          ],
        ),
      );
    });
  }
}
