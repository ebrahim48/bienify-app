import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/doctor_practice.dart';

/// Which tab of the practitioner shell is showing.
///
/// Separate from `MainNavController` on purpose: the two shells have different
/// destinations, and a doctor switching tabs must not disturb the patient
/// shell's state, or vice versa.
class DoctorShellController extends GetxController {
  final Rx<DoctorTab> tab = DoctorTab.home.obs;

  /// Badge on the Appointments destination.
  final RxInt pendingRequests = 1.obs;

  int get index => DoctorTab.values.indexOf(tab.value);

  void select(DoctorTab value) => tab.value = value;

  void selectIndex(int index) => select(DoctorTab.values[index]);

  String labelFor(DoctorTab value) => switch (value) {
    DoctorTab.home => AppStrings.navHome.tr,
    DoctorTab.appointments => AppStrings.navAppointments.tr,
    // Three s's, as the design spells it.
    DoctorTab.message => AppStrings.navMesssage.tr,
    DoctorTab.profile => AppStrings.navProfile.tr,
  };
}
