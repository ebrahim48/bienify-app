import 'package:get/get.dart';

import '../../../patient/appointments/domain/entities/appointment.dart';
import '../../../patient/appointments/presentation/controllers/video_call_controller.dart';
import '../../data/static/doctor_orders_data.dart';
import '../../domain/entities/test_request.dart';
import '../controllers/results_to_review_controller.dart';
import '../controllers/test_request_controller.dart';
import '../controllers/doctor_appointments_controller.dart';
import '../controllers/doctor_home_controller.dart';
import '../controllers/doctor_profile_controller.dart';
import '../controllers/earnings_controller.dart';
import '../controllers/doctor_messages_controller.dart';
import '../controllers/doctor_schedule_controller.dart';
import '../controllers/doctor_shell_controller.dart';
import '../controllers/write_prescription_controller.dart';

/// Route bindings for the practitioner section.

/// The shell and its three built tabs are created together, because the shell
/// keeps every tab alive in an `IndexedStack` and each paints immediately.
class DoctorShellBinding extends Bindings {
  @override
  void dependencies() {
    Get
      ..put(DoctorShellController())
      ..put(DoctorHomeController())
      ..put(DoctorAppointmentsController())
      ..put(DoctorMessagesController())
      ..put(DoctorProfileController());
  }
}

/// Set Schedule owns its own editing state; the dashboard controller stays
/// registered underneath it.
class DoctorScheduleBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(DoctorScheduleController());
  }
}

/// Appointment Details reads the row the list selected, so it only needs the
/// shell's controller — which is already registered when reached from the tab.
/// This covers entering the route directly.
class DoctorAppointmentsBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<DoctorAppointmentsController>()) return;
    Get.put(DoctorAppointmentsController());
  }
}

class WritePrescriptionBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<WritePrescriptionController>()) return;
    Get.put(WritePrescriptionController());
  }
}

/// The practitioner's side of the call. Same controller and screen as the
/// patient's; `isDoctor` only changes where the call ends.
class DoctorVideoCallBinding extends Bindings {
  @override
  void dependencies() {
    DoctorAppointmentsBinding().dependencies();
    final selected = Get.find<DoctorAppointmentsController>().selected.value;
    Get.put(
      VideoCallController(
        isDoctor: true,
        // The call screen's header reads an `Appointment`, so the doctor's
        // booking is mapped onto one rather than the screen being forked.
        appointment: Appointment(
          id: selected?.id ?? 'doctor-call',
          doctorName: selected?.patientName ?? '',
          specialty: selected?.complaint ?? '',
          scheduledAt: selected?.scheduledAt ?? DateTime.now(),
        ),
      ),
    );
  }
}

class EarningsBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<EarningsController>()) return;
    Get.put(EarningsController());
  }
}

/// Edit Profile writes into the profile tab's controller, which the shell has
/// already registered when reached from there.
class DoctorProfileBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<DoctorProfileController>()) return;
    Get.put(DoctorProfileController());
  }
}

/// Every screen in Results to Review reads the one controller: the list picks
/// the patient and the order, and the detail, review options and their
/// destinations all read them back. Registered once and kept for the flow.
class ResultsToReviewBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<ResultsToReviewController>()) return;
    Get.put(ResultsToReviewController());
  }
}

/// The wizard is built for the order being placed, so its controller is
/// replaced on every entry rather than reused with stale answers.
class TestRequestBinding extends Bindings {
  @override
  void dependencies() {
    ResultsToReviewBinding().dependencies();
    final results = Get.find<ResultsToReviewController>();
    Get.put(
      TestRequestController(
        kind: Get.arguments is OrderKind
            ? Get.arguments as OrderKind
            : OrderKind.lab,
        patient: results.patient.value ?? DoctorOrdersData.patients.first,
      ),
    );
  }
}
