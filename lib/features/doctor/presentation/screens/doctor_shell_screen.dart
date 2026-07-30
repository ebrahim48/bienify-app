import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../main/presentation/controllers/main_nav_controller.dart';
import '../../../main/presentation/widgets/app_bottom_nav_bar.dart';
import '../../domain/entities/doctor_practice.dart';
import '../controllers/doctor_shell_controller.dart';
import 'doctor_home_screen.dart';

/// The practitioner shell: Home, Appointments, Messsage, Profile.
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
              labelKey: AppStrings.navMesssage,
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
            _NotAvailableYet(tab: DoctorTab.appointments),
            _NotAvailableYet(tab: DoctorTab.message),
            _NotAvailableYet(tab: DoctorTab.profile),
          ],
        ),
      );
    });
  }
}

/// Placeholder for the three tabs whose designs have not arrived yet.
///
/// Deliberately explicit rather than an empty screen: a doctor tapping
/// Appointments should be told the section is coming, not shown a blank page.
class _NotAvailableYet extends StatelessWidget {
  const _NotAvailableYet({required this.tab});

  final DoctorTab tab;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      scrollable: false,
      child: Center(
        child: AppEmptyState(
          icon: Icons.construction_outlined,
          title: AppStrings.notAvailableYet.tr,
          body: AppStrings.notAvailableYetBody.tr,
        ),
      ),
    );
  }
}
