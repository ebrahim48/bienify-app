import 'package:get/get.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../auth/data/datasources/auth_local_data_source.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../onboarding/presentation/controllers/location_permission_controller.dart';
import '../../../onboarding/presentation/controllers/onboarding_controller.dart';
import '../../../splash/presentation/controllers/splash_controller.dart';
import '../../domain/usecases/email_auth_usecases.dart';
import '../../domain/usecases/password_recovery_usecases.dart';
import '../../domain/usecases/phone_auth_usecases.dart';
import '../../domain/usecases/registration_usecases.dart';
import '../controllers/auth_flow.dart';
import '../controllers/login_controller.dart';
import '../controllers/new_password_controller.dart';
import '../controllers/otp_controller.dart';
import '../controllers/phone_auth_controller.dart';
import '../controllers/profile_setup_controller.dart';

/// Route bindings.
///
/// Each screen declares exactly what it needs; GetX creates the controller
/// when the route opens and disposes it when the route is popped, so no auth
/// draft outlives its flow. Use cases and repositories come from
/// `DependencyInjection` — bindings never construct them.

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => SplashController(
        repository: Get.find<AuthRepository>(),
        local: Get.find<AuthLocalDataSource>(),
      ),
    );
  }
}

class LocationPermissionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => LocationPermissionController(
        local: Get.find<AuthLocalDataSource>(),
      ),
    );
  }
}

class OnboardingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(OnboardingController.new);
    _putPhoneAuthController();
  }
}

class PhoneNumberBinding extends Bindings {
  @override
  void dependencies() => _putPhoneAuthController();
}

class OtpBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => OtpController(
        arguments: Get.arguments as OtpArguments,
        verifyOtp: Get.find<VerifyOtp>(),
        requestOtp: Get.find<RequestOtp>(),
        requestPasswordResetOtp: Get.find<RequestPasswordResetOtp>(),
        verifyPasswordResetOtp: Get.find<VerifyPasswordResetOtp>(),
      ),
    );
  }
}

class ProfileSetupBinding extends Bindings {
  @override
  void dependencies() {
    // `fenix` keeps the draft alive across the two profile-setup screens and
    // recreates it if the user navigates back into the flow.
    Get.lazyPut(
      () => ProfileSetupController(
        saveProfileDetails: Get.find<SaveProfileDetails>(),
        saveCredentials: Get.find<SaveCredentials>(),
      ),
      fenix: true,
    );
  }
}

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => LoginController(loginWithEmail: Get.find<LoginWithEmail>()),
    );
  }
}

class NewPasswordBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => NewPasswordController(
        arguments: Get.arguments as NewPasswordArguments,
        resetPassword: Get.find<ResetPassword>(),
      ),
    );
  }
}

/// Shared by onboarding, "Enter Phone Number" and "Forgot password" so a
/// half-typed number survives the hop between them.
void _putPhoneAuthController() {
  if (Get.isRegistered<PhoneAuthController>()) return;
  Get.put(
    PhoneAuthController(
      requestOtp: Get.find<RequestOtp>(),
      requestPasswordResetOtp: Get.find<RequestPasswordResetOtp>(),
      signInWithProvider: Get.find<SignInWithProvider>(),
    ),
    permanent: true,
  );
}

/// Routes whose screens need no controller of their own (the two success
/// screens simply navigate onward).
const List<String> staticRoutes = [
  AppRoutes.signupSuccess,
  AppRoutes.passwordUpdated,
];
