import 'package:flutter/widgets.dart';
import '../../../../../../core/services/avatar_service.dart';
import 'package:get/get.dart';

import '../../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../../core/routes/app_routes.dart';
import '../../../../../../core/utils/app_navigator.dart';
import '../../../auth/domain/usecases/email_auth_usecases.dart';
import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/models/delivery_address.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../../../pharmacy/presentation/widgets/location_dialog.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/account_repository.dart';

/// Backs the Profile screen: the patient card and the menu below it.
///
/// Logging out clears the session and the stack; everything else pushes a
/// route.
class ProfileController extends GetxController with AvatarChanging {
  ProfileController({AccountRepository? repository, Logout? logout})
    : _repository = repository ?? Get.find<AccountRepository>(),
      _logout = logout ?? Get.find<Logout>();

  final AccountRepository _repository;
  final Logout _logout;

  /// Empty until the first load lands, so the card does not flash a name and
  /// a number belonging to nobody.
  final Rx<PatientProfile> patient = const PatientProfile(
    name: '',
    maskedPhone: '',
  ).obs;

  /// The saved delivery address, shown on the menu row so the patient can see
  /// where their orders go without opening anything.
  final Rxn<DeliveryAddress> address = Rxn<DeliveryAddress>();

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
      patient.value = await _repository.me();
      address.value = await _repository.savedAddress();
    } on AppException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Navigation ──────────────────────────────────────────────────────────

  void openHealthProfile() => Get.toNamed<void>(AppRoutes.healthProfile);

  /// The address every order is delivered to unless the patient points one
  /// order somewhere else at checkout.
  ///
  /// Edited through the same dialog the checkout uses, so the two cannot
  /// drift apart — but without its "also save" opt-in, since saving is the
  /// only reason to open it from here.
  Future<void> editDeliveryAddress(BuildContext context) async {
    final saved = address.value;
    final edit = await LocationDialog.show(
      context,
      address: saved ?? const DeliveryAddress(line1: ''),
      isEditing: saved != null,
    );
    if (edit == null) return;

    address.value = edit.address;
    try {
      await _repository.saveAddress(edit.address);
      AppSnackbar.success(AppStrings.addressSaved.tr);
    } on AppException catch (e) {
      AppSnackbar.error(e.message);
    }
  }


  /// Promoted to the top level by the design, so it is reachable both here
  /// and from inside the health profile.
  void openTestsAndResults() => Get.toNamed<void>(AppRoutes.testResults);

  void openOrderHistory() => Get.toNamed<void>(AppRoutes.orderHistory);

  void openWallet() => Get.toNamed<void>(AppRoutes.wallet);

  void openSettings() => Get.toNamed<void>(AppRoutes.settings);

  void openPartner() => Get.toNamed<void>(AppRoutes.becomePartner);

  // ─── Actions ─────────────────────────────────────────────────────────────

  /// Editing the profile and replacing the photo both land on the existing
  /// sign-up profile form, which is the screen that already collects them.
  void edit() => Get.toNamed<void>(AppRoutes.profileSetup);

  /// Changes the account photo.
  ///
  /// This opened the edit form, which has no photo field — so the control did
  /// nothing at all, in all four roles.
  Future<void> changePhoto(BuildContext context) => changePhotoWith(context);

  @override
  Future<void> reloadProfile() => load();

  /// Called once the confirm dialog resolves.
  ///
  /// The session is cleared before leaving, so the next sign-in does not
  /// inherit this patient's tokens.
  Future<void> logOut() async {
    try {
      await _logout();
    } on AppException {
      // A server that refuses the sign-out still has to let the patient
      // leave; the local tokens are dropped either way.
    }
    AppNavigator.resetTo(AppRoutes.onboarding);
  }
}
