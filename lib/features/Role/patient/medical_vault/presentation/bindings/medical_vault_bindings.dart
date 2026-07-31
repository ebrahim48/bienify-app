import 'package:get/get.dart';

import '../../../appointments/presentation/controllers/appointments_controller.dart';
import '../controllers/documents_controller.dart';
import '../controllers/test_results_controller.dart';

/// Route bindings for My Health profile and the tests-and-results journey.

class DocumentsBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<DocumentsController>()) return;
    Get.put(DocumentsController());
  }
}

/// Past Appointments reuses the Appointments tab's controller and cards.
///
/// Reached from inside the signed-in shell, `MainBinding` has already put it —
/// this only covers the case where the route is entered directly, so the
/// screen never depends on a tab having been visited first.
class PastAppointmentsBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<AppointmentsController>()) return;
    Get.put(AppointmentsController());
  }
}

/// Shared by every screen of the tests journey: the list, the order sheet,
/// the centre picker, the upload form and the review. The chosen order and
/// centre have to survive all of them, so the first screen to need it
/// registers it and the rest reuse it.
///
/// Not `permanent`: the list route sits under the whole journey and keeps the
/// controller alive, and leaving the journey should discard the selection
/// rather than carry it into the next session.
class TestResultsBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<TestResultsController>()) return;
    Get.put(TestResultsController());
  }
}
