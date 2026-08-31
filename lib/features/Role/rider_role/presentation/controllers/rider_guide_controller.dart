import 'package:get/get.dart';

import '../../../../../core/exceptions/app_exceptions.dart';
import '../../../patient/profile/domain/repositories/account_repository.dart';

/// Backs How It Works — the page read *before* applying to ride.
///
/// It names the signed-in **account**, not a courier profile. Whoever is
/// reading this page is by definition not a courier yet, and the server
/// refuses the whole `/riders` namespace to anyone whose role is not `rider`:
/// binding the dashboard's controller here meant opening How It Works fired
/// `GET /riders/me` and took a 403 back, so the masthead above the invitation
/// to apply was blank for every applicant it was written for.
class RiderGuideController extends GetxController {
  RiderGuideController({AccountRepository? account})
    : _account = account ?? Get.find<AccountRepository>();

  final AccountRepository _account;

  /// Empty until the account lands, so the masthead does not flash a name.
  final RxString name = ''.obs;

  final RxnString photoUrl = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    try {
      final me = await _account.me();
      name.value = me.name;
      photoUrl.value = me.photoUrl;
    } on AppException {
      // The masthead shows no name rather than a wrong one. The page is the
      // five steps and the apply button; the greeting is a nicety.
      name.value = '';
    }
  }
}
