import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/routes/app_routes.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/profile.dart';

/// Backs Become a Partner: two options, one of which is always selected.
///
/// The design shows Rider selected on open, which is why that is the initial
/// value rather than `null`.
class PartnerController extends GetxController {
  final Rx<PartnerRole> selected = PartnerRole.rider.obs;

  bool isSelected(PartnerRole role) => selected.value == role;

  void select(PartnerRole role) => selected.value = role;

  String labelFor(PartnerRole role) => switch (role) {
    PartnerRole.pharmacyOwner => AppStrings.joinAsPharmacyOwner.tr,
    PartnerRole.rider => AppStrings.joinAsRider.tr,
  };

  /// A pharmacy owner has a whole section of their own, so applying enters it
  /// — the same way "Join as a Doctor" enters the practitioner shell. The
  /// rider's side is not designed yet, so that choice acknowledges and
  /// returns.
  void submitApplication() {
    if (selected.value == PartnerRole.pharmacyOwner) {
      Get.toNamed<void>(AppRoutes.shopHome);
      return;
    }
    AppSnackbar.success(
      AppStrings.partnerApplicationSent.trParams({
        'role': labelFor(selected.value),
      }),
    );
    Get.back<void>();
  }
}
