import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_snackbar.dart';
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

  /// UI-only: the application form itself is not designed yet, so this
  /// acknowledges the choice and returns.
  void submitApplication() {
    AppSnackbar.success(
      AppStrings.partnerApplicationSent.trParams({
        'role': labelFor(selected.value),
      }),
    );
    Get.back<void>();
  }
}
