import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_icons.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../../../patient/main/presentation/controllers/main_nav_controller.dart';
import '../../../patient/main/presentation/widgets/app_bottom_nav_bar.dart';
import '../controllers/doctor_shell_controller.dart';
import 'doctor_appointments_screen.dart';
import 'doctor_home_screen.dart';
import 'doctor_messages_screen.dart';
import 'doctor_profile_screen.dart';

/// The practitioner shell: Home, Appointments, Message, Profile.
///
/// Reuses `AppBottomNavBar` and `NavDestination` from the patient shell — the
/// bar is already generic over its destinations, so only the four entries
/// differ. `DoctorShellController` is separate from `MainNavController` so the
/// two shells never disturb each other's tab.
class DoctorShellScreen extends GetView<DoctorShellController> {
  const DoctorShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final index = controller.index;
      return AppScaffold(
        padded: false,
        scrollable: false,
        bottomBar: AppBottomNavBar(
          currentIndex: index,
          destinations: [
            const NavDestination(
              labelKey: AppStrings.navHome,
              icon: AppIcons.home,
            ),
            NavDestination(
              labelKey: AppStrings.navAppointments,
              icon: AppIcons.appointments,
              badgeCount: controller.pendingRequests.value,
            ),
            const NavDestination(
              labelKey: AppStrings.navMessage,
              icon: AppIcons.bottomMessage,
            ),
            const NavDestination(
              labelKey: AppStrings.navProfile,
              icon: AppIcons.person,
            ),
          ],
          onSelected: controller.selectIndex,
        ),
        // `IndexedStack` so a tab keeps its scroll position and its
        // controller, the same arrangement as the patient shell.
        child: IndexedStack(
          index: index,
          children: const [
            DoctorHomeScreen(),
            DoctorAppointmentsScreen(),
            DoctorMessagesScreen(),
            DoctorProfileScreen(),
          ],
        ),
      );
    });
  }
}
