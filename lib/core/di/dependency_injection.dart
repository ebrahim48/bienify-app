import 'package:get/get.dart';
import '../../features/home/presentation/controllers/home_controller.dart';
import '../services/storage_service.dart';

class DependencyInjection {
  DependencyInjection._();

  static Future<void> init() async {
    // StorageService — async init
    final storageService = StorageService();
    await storageService.init();
    Get.put<StorageService>(storageService, permanent: true);

    // Home controller
    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);
  }

  static void clear() => Get.deleteAll(force: true);
}
