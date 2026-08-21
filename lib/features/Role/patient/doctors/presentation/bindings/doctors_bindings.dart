import 'package:get/get.dart';

import '../../../booking/presentation/controllers/payment_controller.dart';
import '../../../appointments/domain/entities/appointment.dart';
import '../../../chat/data/static/chat_mock_data.dart';
import '../../../chat/domain/entities/conversation.dart';
import '../../../chat/presentation/controllers/chat_controller.dart';
import '../../../chat/presentation/controllers/messages_controller.dart';
import '../../data/static/doctor_mock_data.dart';
import '../../domain/entities/doctor.dart';
import '../../domain/entities/doctor_category.dart';
import '../../domain/usecases/doctor_usecases.dart';
import '../controllers/doctor_details_controller.dart';
import '../controllers/doctor_list_controller.dart';
import '../controllers/doctor_search_controller.dart';

/// Route bindings for discovery, booking and messaging.

class DoctorSearchBinding extends Bindings {
  @override
  void dependencies() {
    // The Doctors tab already owns one; reuse it so a query typed in the tab
    // survives opening the dedicated Search screen.
    if (Get.isRegistered<DoctorSearchController>()) return;
    Get.put(
      DoctorSearchController(
        searchDoctors: Get.find<SearchDoctors>(),
        getSpecialties: Get.find<GetSpecialties>(),
      ),
    );
  }
}

class DoctorListBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(
      DoctorListController(
        category: Get.arguments is DoctorCategory
            ? Get.arguments as DoctorCategory
            : DoctorMockData.generalCategory,
      ),
    );
  }
}

class DoctorDetailsBinding extends Bindings {
  @override
  void dependencies() {
    // Two ways in: a `Doctor` to book with, or a `RescheduleRequest` carrying
    // the lapsed consultation to move. The screen is the same; the argument
    // decides what confirming does.
    final args = Get.arguments;
    final rescheduling = args is RescheduleRequest ? args : null;

    Get.put(
      DoctorDetailsController(
        doctor: rescheduling == null
            ? args as Doctor
            : _doctorFor(rescheduling.appointment),
        getDetails: Get.find<GetDoctorDetails>(),
        getAvailability: Get.find<GetDoctorAvailability>(),
        rescheduling: rescheduling,
      ),
    );
  }

  /// The lapsed booking names its doctor but is not a `Doctor`, so this builds
  /// the minimum the details screen needs while it loads the rest.
  static Doctor _doctorFor(Appointment appointment) => Doctor(
    id: appointment.doctorProfileId,
    name: appointment.doctorName,
    specialty: appointment.specialty,
    photoUrl: appointment.doctorPhotoUrl,
    consultationFee: appointment.consultationFee,
  );
}

class PaymentBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(PaymentController(appointment: Get.arguments as Appointment));
  }
}

class MessagesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(MessagesController.new);
  }
}

class ChatBinding extends Bindings {
  @override
  void dependencies() {
    // Opening a thread without a peer (e.g. from the header shortcut) falls
    // back to the sample conversation rather than crashing.
    final peer = Get.arguments is ConversationPeer
        ? Get.arguments as ConversationPeer
        : ChatMockData.peer;
    Get.put(ChatController(peer: peer));
  }
}
