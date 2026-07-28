import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../data/static/medicine_mock_data.dart';
import '../../domain/entities/medicine.dart';

/// Backs the Pharmacy tab.
class PharmacyController extends GetxController {
  final RxList<Medicine> medicines = <Medicine>[].obs;
  final RxList<String> cart = <String>[].obs;
  final RxBool isLoading = true.obs;

  int get cartCount => cart.length;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    await Future<void>.delayed(const Duration(milliseconds: 400));
    medicines.value = MedicineMockData.all;
    isLoading.value = false;
  }

  bool isInCart(Medicine medicine) => cart.contains(medicine.id);

  void addToCart(Medicine medicine) {
    if (!medicine.isInStock || isInCart(medicine)) return;
    cart.add(medicine.id);
    AppSnackbar.success(AppStrings.addedToCart.tr);
  }
}
