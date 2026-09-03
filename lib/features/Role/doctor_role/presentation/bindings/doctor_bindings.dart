import '../controllers/doctor_credentials_controller.dart';
import 'package:get/get.dart';

import '../../../patient/appointments/domain/entities/appointment.dart';
import '../../../patient/appointments/presentation/controllers/video_call_controller.dart';
import '../../domain/entities/test_request.dart';
import '../controllers/results_to_review_controller.dart';
import '../controllers/test_request_controller.dart';
import '../controllers/doctor_appointments_controller.dart';
import '../controllers/doctor_home_controller.dart';
import '../controllers/doctor_profile_controller.dart';
import '../controllers/earnings_controller.dart';
import '../controllers/doctor_messages_controller.dart';
import '../controllers/doctor_schedule_controller.dart';
import '../controllers/doctor_notifications_controller.dart';
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
/// The credentials screen reads the practitioner's own profile.
class DoctorCredentialsBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(DoctorCredentialsController());
  }
}

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
    // An answered call arrives with the consultation it is on, built from the
    // invite. Preferred over the selection, which is whatever booking the
    // doctor last tapped — for a call that rang while they were looking at a
    // different patient, that is the wrong room.
    final incoming = Get.arguments;
    if (incoming is Appointment) {
      Get.put(VideoCallController(isDoctor: true, appointment: incoming));
      return;
    }

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
class DoctorNotificationsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(DoctorNotificationsController.new);
  }
}

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
        // An empty patient rather than a fixture: `submit` already refuses an
        // order with no patient id and says so. Falling back to the first
        // demo patient meant a wizard opened without one would file a real
        // order against a person the doctor never chose.
        patient:
            results.patient.value ??
            ReviewPatient(
              id: '',
              name: '',
              code: '',
              age: 0,
              gender: '',
              complaint: '',
              seenOn: DateTime.now(),
              photoUrl: '',
            ),
      ),
    );
  }
}
