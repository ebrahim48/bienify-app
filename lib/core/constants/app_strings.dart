/// Translation **keys** for every user-facing string in the app.
///
/// Screens never hold literal copy. They reference a key and append GetX's
/// `.tr` extension, which resolves against [AppTranslations] for the locale
/// currently selected by the language toggle:
///
/// ```dart
/// Text(AppStrings.login.tr)
/// ```
///
/// Adding a string is a three-step change: add the key here, then add the
/// English and Spanish values in `core/localization/app_translations.dart`.
class AppStrings {
  AppStrings._();

  // ─── App ─────────────────────────────────────────────────────────────────
  static const String appName = 'app_name';

  // ─── Location permission ─────────────────────────────────────────────────
  static const String allowYourLocation = 'allow_your_location';
  static const String deny = 'deny';
  static const String allow = 'allow';

  // ─── Onboarding ──────────────────────────────────────────────────────────
  static const String onboardingTitle1 = 'onboarding_title_1';
  static const String onboardingBody1 = 'onboarding_body_1';
  static const String onboardingTitle2 = 'onboarding_title_2';
  static const String onboardingBody2 = 'onboarding_body_2';
  static const String onboardingTitle3 = 'onboarding_title_3';
  static const String onboardingBody3 = 'onboarding_body_3';

  static const String signInWithGoogle = 'sign_in_with_google';
  static const String signInWithApple = 'sign_in_with_apple';
  static const String or = 'or';
  static const String enterPhoneNumber = 'enter_phone_number';
  static const String continueWithPhoneNumber = 'continue_with_phone_number';
  static const String alreadyHaveAnAccount = 'already_have_an_account';
  static const String joinAsADoctor = 'join_as_a_doctor';

  // ─── Phone / OTP ─────────────────────────────────────────────────────────
  static const String enterPhoneNumberTitle = 'enter_phone_number_title';
  static const String getOtp = 'get_otp';
  static const String enterOtp = 'enter_otp';
  static const String codeSentHeading = 'code_sent_heading';
  static const String codeSentSubtitle = 'code_sent_subtitle';
  static const String enterSixDigitCode = 'enter_six_digit_code';
  static const String codeNotReceived = 'code_not_received';
  static const String requestNewOtp = 'request_new_otp';
  static const String resendIn = 'resend_in';
  static const String next = 'next';
  static const String verifyNow = 'verify_now';

  // ─── Profile setup ───────────────────────────────────────────────────────
  static const String setUpYourProfile = 'set_up_your_profile';
  static const String name = 'name';
  static const String nameHint = 'name_hint';
  static const String gender = 'gender';
  static const String male = 'male';
  static const String female = 'female';
  static const String age = 'age';
  static const String email = 'email';
  static const String emailHint = 'email_hint';
  static const String password = 'password';
  static const String passwordHint = 'password_hint';
  static const String retypePasswordHint = 'retype_password_hint';
  static const String saveAndContinue = 'save_and_continue';

  // ─── Success ─────────────────────────────────────────────────────────────
  static const String allSetUp = 'all_set_up';
  static const String careStartsHere = 'care_starts_here';
  static const String getStarted = 'get_started';
  static const String passwordUpdated = 'password_updated';
  static const String loginNow = 'login_now';

  // ─── Login ───────────────────────────────────────────────────────────────
  static const String login = 'login';
  static const String forgotYourPassword = 'forgot_your_password';
  static const String resetNow = 'reset_now';
  static const String areYouNewMember = 'are_you_new_member';
  static const String signUpNow = 'sign_up_now';

  // ─── Reset password ──────────────────────────────────────────────────────
  static const String enterNewPassword = 'enter_new_password';
  static const String newPasswordHint = 'new_password_hint';
  static const String retypeNewPasswordHint = 'retype_new_password_hint';
  static const String resetPassword = 'reset_password';

  // ─── Country picker ──────────────────────────────────────────────────────
  static const String selectCountry = 'select_country';
  static const String searchCountry = 'search_country';

  // ─── Validation ──────────────────────────────────────────────────────────
  static const String errorNameRequired = 'error_name_required';
  static const String errorGenderRequired = 'error_gender_required';
  static const String errorAgeRequired = 'error_age_required';
  static const String errorEmailRequired = 'error_email_required';
  static const String errorEmailInvalid = 'error_email_invalid';
  static const String errorPasswordRequired = 'error_password_required';
  static const String errorPasswordTooShort = 'error_password_too_short';
  static const String errorPasswordMismatch = 'error_password_mismatch';
  static const String errorPhoneRequired = 'error_phone_required';
  static const String errorPhoneInvalid = 'error_phone_invalid';
  static const String errorOtpRequired = 'error_otp_required';
  static const String errorOtpInvalid = 'error_otp_invalid';

  // ─── Feedback ────────────────────────────────────────────────────────────
  static const String otpResent = 'otp_resent';
  static const String somethingWentWrong = 'something_went_wrong';
  static const String noInternetConnection = 'no_internet_connection';
  static const String comingSoon = 'coming_soon';
}
