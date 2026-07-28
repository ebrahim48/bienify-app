import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../main/presentation/controllers/main_nav_controller.dart';
import '../../data/static/appointment_mock_data.dart';
import '../../domain/entities/appointment.dart';

/// Backs the Appointments tab, split into upcoming and past.
class AppointmentsController extends GetxController {
  final RxList<Appointment> appointments = <Appointment>[].obs;
  final RxInt selectedTab = 0.obs;
  final RxBool isLoading = true.obs;

  List<Appointment> get upcoming => appointments
      .where((a) => a.status == AppointmentStatus.upcoming)
      .toList();

  List<Appointment> get past => appointments
      .where((a) => a.status != AppointmentStatus.upcoming)
      .toList();

  List<Appointment> get visible => selectedTab.value == 0 ? upcoming : past;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    await Future<void>.delayed(const Duration(milliseconds: 400));
    appointments.value = AppointmentMockData.all();
    isLoading.value = false;
  }

  void selectTab(int index) => selectedTab.value = index;

  /// A video room opens shortly before the slot; outside that window the
  /// patient is told when to come back rather than dropped into an empty call.
  void join(Appointment appointment) {
    if (!appointment.canJoin) {
      AppSnackbar.info(AppStrings.joinOpensSoon.tr);
      return;
    }
    Get.toNamed<void>(AppRoutes.chat);
  }

  /// Empty state action — hop to the Doctors tab.
  void findDoctor() => Get.find<MainNavController>().select(2);
}
