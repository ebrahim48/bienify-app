import 'package:get/get.dart';

import '../../../../../core/constants/app_assets.dart';
import '../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../core/routes/app_routes.dart';
import '../../../patient/chat/domain/entities/conversation.dart';
import '../../domain/entities/doctor_practice.dart';
import '../../domain/repositories/doctor_practice_repository.dart';

/// Backs the doctor's Message tab.
///
/// Opening a thread reuses the patient app's `ChatScreen` with the patient as
/// its `ConversationPeer` — one messaging screen serves both roles.
class DoctorMessagesController extends GetxController {
  DoctorMessagesController({DoctorPracticeRepository? repository})
    : _repository = repository ?? Get.find<DoctorPracticeRepository>();

  final DoctorPracticeRepository _repository;

  final RxList<PatientThread> threads = <PatientThread>[].obs;

  final RxString query = ''.obs;

  final RxBool isLoading = true.obs;
  final RxnString error = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    try {
      threads.value = await _repository.threads();
    } on AppException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
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
        // A thread is keyed by its consultation, which is what makes the
        // messages behind it real rather than the sample conversation.
        appointmentId: thread.id,
        name: thread.patientName,
        // The doctor's side of the header shows why the patient is here, and
        // the preview is the nearest thing the list carries.
        specialty: thread.preview,
        photoUrl: thread.photoUrl,
        photoAsset: thread.photoAsset ?? AppAssets.doctorPlaceholder,
        isOnline: true,
      ),
    );
  }
}
