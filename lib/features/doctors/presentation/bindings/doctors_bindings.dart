import 'package:get/get.dart';

import '../../../booking/presentation/controllers/payment_controller.dart';
import '../../../appointments/domain/entities/appointment.dart';
import '../../../chat/data/static/chat_mock_data.dart';
import '../../../chat/domain/entities/conversation.dart';
import '../../../chat/presentation/controllers/chat_controller.dart';
import '../../domain/entities/doctor.dart';
import '../../domain/usecases/doctor_usecases.dart';
import '../controllers/doctor_details_controller.dart';
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

class DoctorDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(
      DoctorDetailsController(
        doctor: Get.arguments as Doctor,
        getDetails: Get.find<GetDoctorDetails>(),
        getAvailability: Get.find<GetDoctorAvailability>(),
      ),
    );
  }
}

class PaymentBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(PaymentController(appointment: Get.arguments as Appointment));
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
