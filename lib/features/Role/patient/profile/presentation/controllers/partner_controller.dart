import 'package:get/get.dart';

import '../../../../../../core/base/base_controller.dart';
import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../../core/routes/app_routes.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/partner_repository.dart';

/// Backs Become a Partner: two options, one of which is always selected.
///
/// The design shows Rider selected on open, which is why that is the initial
/// value rather than `null`.
class PartnerController extends GetxController with SubmissionMixin {
  PartnerController({PartnerRepository? repository})
    : _repository = repository ?? Get.find<PartnerRepository>();

  final PartnerRepository _repository;

  final Rx<PartnerRole> selected = PartnerRole.rider.obs;

  /// The application already on file, once it has been read.
  final Rxn<PartnerApplication> application = Rxn<PartnerApplication>();

  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      final existing = await _repository.latestApplication();
      application.value = existing;
      if (existing != null) selected.value = existing.role;
    } on AppException {
      // An application that will not load leaves the form usable; the server
      // refuses a duplicate anyway, so the worst case is a clear error on
      // submit rather than a screen that will not open.
      application.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  bool isSelected(PartnerRole role) => selected.value == role;

  void select(PartnerRole role) => selected.value = role;

  String labelFor(PartnerRole role) => switch (role) {
    PartnerRole.pharmacyOwner => AppStrings.joinAsPharmacyOwner.tr,
    PartnerRole.rider => AppStrings.joinAsRider.tr,
  };

  /// Whether the button files an application or opens the shell.
  bool get isApproved => application.value?.isApproved ?? false;

  /// True while an application is waiting on an admin, so the screen can say
  /// so instead of inviting a second one the server will refuse.
  bool get isPending =>
      application.value?.status == PartnerApplicationStatus.pending;

  String get actionLabel =>
      isApproved ? AppStrings.continueLabel.tr : AppStrings.applyNow.tr;

  /// Files the application, or enters the partner's shell when one has already
  /// been approved.
  ///
  /// It used to route straight into the rider or pharmacy home for everybody.
  /// That is a role only an admin can grant (`partner.service.ts:6`), so the
  /// app was handing out a shell the server had never agreed to, and the
  /// admin's review queue was fed by nothing.
  Future<void> submitApplication() async {
    if (isApproved) {
      _openShell(application.value!.role);
      return;
    }

    final role = selected.value;
    final ok = await submit(() async {
      application.value = await _repository.apply(role: role);
    });
    if (!ok) return;

    AppSnackbar.success(
      AppStrings.partnerApplicationSent.trParams({'role': labelFor(role)}),
    );
  }

  void _openShell(PartnerRole role) => switch (role) {
    // A pharmacy owner lands in their shop; a courier reads How It Works
    // first, because their side has an onboarding step of its own.
    PartnerRole.pharmacyOwner => Get.toNamed<void>(AppRoutes.shopHome),
    PartnerRole.rider => Get.toNamed<void>(AppRoutes.riderGuide),
  };
}
