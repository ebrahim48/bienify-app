import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../appointments/presentation/screens/appointments_screen.dart';
import '../../../doctors/presentation/screens/find_doctor_screen.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../pharmacy/presentation/screens/pharmacy_screen.dart';
import '../controllers/main_nav_controller.dart';
import '../widgets/app_bottom_nav_bar.dart';

/// The signed-in shell: four tabs behind one persistent bottom navigation.
///
/// Tabs live in an `IndexedStack` so each keeps its scroll position and state
/// when the user moves between them — switching back to Home should not
/// re-fetch the feed or jump to the top.
class MainShellScreen extends GetView<MainNavController> {
  const MainShellScreen({super.key});

  static const List<Widget> _tabs = [
    HomeScreen(),
    AppointmentsScreen(),
    FindDoctorScreen(),
    PharmacyScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.overlayStyle.copyWith(
        systemNavigationBarColor: AppColors.surface,
      ),
      child: Obx(
        () => PopScope(
          // Android back on a secondary tab returns to Home rather than
          // leaving the app.
          canPop: controller.currentIndex.value == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) controller.select(0);
          },
          child: Scaffold(
            backgroundColor: AppColors.authBackground,
            body: IndexedStack(
              index: controller.currentIndex.value,
              children: _tabs,
            ),
            bottomNavigationBar: AppBottomNavBar(
              currentIndex: controller.currentIndex.value,
              // Copying inside the `Obx` closure is what subscribes to the
              // list. Handing over the `RxList` itself would not: the child
              // reads it during its own build, outside this tracking scope,
              // so badge changes would never repaint.
              destinations: controller.destinations.toList(),
              onSelected: controller.select,
            ),
          ),
        ),
      ),
    );
  }
}
