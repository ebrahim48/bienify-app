import 'package:get/get.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../patient/chat/domain/entities/conversation.dart';
import '../../data/static/doctor_practice_data.dart';
import '../../domain/entities/doctor_practice.dart';

/// Backs the doctor's Message tab.
///
/// UI-only. Opening a thread reuses the patient app's `ChatScreen` with the
/// patient as its `ConversationPeer` — one messaging screen serves both roles.
class DoctorMessagesController extends GetxController {
  final RxList<PatientThread> threads = <PatientThread>[].obs;

  final RxString query = ''.obs;

  @override
  void onInit() {
    super.onInit();
    threads.value = List.of(DoctorPracticeData.threads);
  }

  List<PatientThread> get visible {
    final search = query.value.trim().toLowerCase();
    if (search.isEmpty) return threads.toList();
    return threads
        .where((t) => t.patientName.toLowerCase().contains(search))
        .toList();
  }

  void openThread(PatientThread thread) {
    Get.toNamed<void>(
      AppRoutes.chat,
      arguments: ConversationPeer(
        id: thread.id,
        name: thread.patientName,
        // The doctor's side of the header shows why the patient is here, and
        // the preview is the nearest thing the list carries.
        specialty: thread.preview,
        photoAsset: thread.photoAsset ?? AppAssets.doctorPlaceholder,
        isOnline: true,
      ),
    );
  }
}
