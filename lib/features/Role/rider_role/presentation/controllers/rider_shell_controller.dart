import 'package:get/get.dart';

import '../../domain/entities/rider.dart';

/// Which tab of the rider shell is showing.
///
/// Separate from the other three shells' controllers, so switching tabs in
/// one never disturbs another.
class RiderShellController extends GetxController {
  final Rx<RiderTab> tab = RiderTab.home.obs;

  int get index => RiderTab.values.indexOf(tab.value);

  void select(RiderTab value) => tab.value = value;

  void selectIndex(int value) => tab.value = RiderTab.values[value];
}
