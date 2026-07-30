import 'package:get/get.dart';

import '../controllers/account_controller.dart';
import '../controllers/add_card_controller.dart';
import '../controllers/change_password_controller.dart';
import '../controllers/partner_controller.dart';
import '../controllers/profile_controller.dart';
import '../controllers/settings_controller.dart';

/// Route bindings for the account section.

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ProfileController());
  }
}

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(SettingsController());
  }
}

class ChangePasswordBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ChangePasswordController());
  }
}

class PartnerBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(PartnerController());
  }
}

/// Shared by My Order History, My Wallet, Payment options and Review shop —
/// all views of the same account state, so the saved cards and the chosen
/// filter survive moving between them.
class AccountBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<AccountController>()) return;
    Get.put(AccountController());
  }
}

/// Add Debit Card writes into the account, so it needs both.
class AddCardBinding extends Bindings {
  @override
  void dependencies() {
    AccountBinding().dependencies();
    Get.put(AddCardController());
  }
}
