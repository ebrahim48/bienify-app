import 'package:get/get.dart';

import '../../domain/entities/pharmacy_shop.dart';

/// Which tab of the pharmacy shell is showing.
///
/// Deliberately separate from `MainNavController` and `DoctorShellController`:
/// the three shells have different destinations, and switching tabs in one
/// must not disturb another.
class ShopShellController extends GetxController {
  final Rx<ShopTab> tab = ShopTab.home.obs;

  int get index => ShopTab.values.indexOf(tab.value);

  void select(ShopTab value) => tab.value = value;

  void selectIndex(int value) => tab.value = ShopTab.values[value];
}
