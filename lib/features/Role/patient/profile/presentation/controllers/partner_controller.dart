import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/routes/app_routes.dart';
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

  /// Both partners have a section of their own, the way "Join as a Doctor"
  /// enters the practitioner shell. A pharmacy owner lands straight in their
  /// shop; a courier reads How It Works first, because their side has an
  /// application to fill in before the shell means anything.
  void submitApplication() => switch (selected.value) {
    PartnerRole.pharmacyOwner => Get.toNamed<void>(AppRoutes.shopHome),
    PartnerRole.rider => Get.toNamed<void>(AppRoutes.riderGuide),
  };
}
