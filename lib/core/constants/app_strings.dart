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

  // ─── Bottom navigation ───────────────────────────────────────────────────
  static const String navHome = 'nav_home';
  static const String navAppointments = 'nav_appointments';
  static const String navDoctors = 'nav_doctors';
  static const String navPharmacy = 'nav_pharmacy';

  // ─── Home ────────────────────────────────────────────────────────────────
  static const String searchSpecialty = 'search_specialty';
  static const String upcomingAppointments = 'upcoming_appointments';
  static const String nearbyDoctors = 'nearby_doctors';
  static const String seeAll = 'see_all';
  static const String seeAvailability = 'see_availability';
  static const String join = 'join';
  static const String reviewRequest = 'review_request';
  static const String requestedBy = 'requested_by';
  static const String statusRequestSent = 'status_request_sent';
  static const String statusInProgress = 'status_in_progress';
  static const String statusReady = 'status_ready';
  static const String noUpcomingAppointments = 'no_upcoming_appointments';
  static const String noDoctorsFound = 'no_doctors_found';
  static const String retry = 'retry';

  // ─── Search & directory ──────────────────────────────────────────────────
  static const String search = 'search';
  static const String filterAll = 'filter_all';

  // ─── Doctor details ──────────────────────────────────────────────────────
  static const String doctorDetails = 'doctor_details';
  static const String reviewsCount = 'reviews_count';
  static const String perConsultation = 'per_consultation';
  static const String yearsCount = 'years_count';
  static const String experience = 'experience';
  static const String patients = 'patients';
  static const String workingTime = 'working_time';
  static const String biography = 'biography';
  static const String selectYearAndDate = 'select_year_and_date';
  static const String availableTime = 'available_time';
  static const String bookAppointment = 'book_appointment';
  static const String selectTimeSlot = 'select_time_slot';

  // ─── Payment ─────────────────────────────────────────────────────────────
  static const String paymentSummary = 'payment_summary';
  static const String medicalDocument = 'medical_document';
  static const String attachment = 'attachment';
  static const String camera = 'camera';
  static const String attachmentAdded = 'attachment_added';
  static const String consultationFee = 'consultation_fee';
  static const String vat = 'vat';
  static const String totalPayable = 'total_payable';
  static const String rxWallet = 'rx_wallet';
  static const String walletBalance = 'wallet_balance';
  static const String walletDeduction = 'wallet_deduction';
  static const String choosePaymentMethod = 'choose_payment_method';
  static const String paymentDebitCredit = 'payment_debit_credit';
  static const String paymentApplePay = 'payment_apple_pay';
  static const String paymentBankTransfer = 'payment_bank_transfer';
  static const String paymentTpago = 'payment_tpago';
  static const String paymentPaypal = 'payment_paypal';
  static const String paymentCash = 'payment_cash';
  static const String payAmount = 'pay_amount';
  static const String appointmentScheduled = 'appointment_scheduled';
  static const String backToAppointment = 'back_to_appointment';

  // ─── Cash payment process ────────────────────────────────────────────────
  static const String howToPaymentWorks = 'how_to_payment_works';
  static const String payStep1Title = 'pay_step_1_title';
  static const String payStep1Body = 'pay_step_1_body';
  static const String payStep2Title = 'pay_step_2_title';
  static const String payStep2Body = 'pay_step_2_body';
  static const String payStep3Title = 'pay_step_3_title';
  static const String payStep3Body = 'pay_step_3_body';
  static const String payStep4Title = 'pay_step_4_title';
  static const String payStep4Body = 'pay_step_4_body';

  static const String yourPaymentCode = 'your_payment_code';
  static const String paymentCode = 'payment_code';
  static const String useCodeAtAgent = 'use_code_at_agent';
  static const String copyCode = 'copy_code';
  static const String codeCopied = 'code_copied';
  static const String codeCopiedDetail = 'code_copied_detail';
  static const String validForHours = 'valid_for_hours';
  static const String codeExpiresAfter = 'code_expires_after';
  static const String remaining = 'remaining';
  static const String amountToPay = 'amount_to_pay';
  static const String findPaymentLocation = 'find_payment_location';

  static const String nearbyPaymentPoints = 'nearby_payment_points';
  static const String mapView = 'map_view';
  static const String listView = 'list_view';
  static const String yourLocation = 'your_location';
  static const String allNearby = 'all_nearby';
  static const String directions = 'directions';
  static const String go = 'go';
  static const String openNow = 'open_now';
  static const String openLabel = 'open_label';
  static const String closedLabel = 'closed_label';
  static const String foundALocation = 'found_a_location';

  static const String paymentPending = 'payment_pending';
  static const String waitingForPayment = 'waiting_for_payment';
  static const String waitingForPaymentBody = 'waiting_for_payment_body';
  static const String timeRemaining = 'time_remaining';
  static const String codeValidFrom = 'code_valid_from';
  static const String autoChecking = 'auto_checking';
  static const String checkPaymentStatus = 'check_payment_status';
  static const String viewNearbyLocations = 'view_nearby_locations';

  static const String paymentConfirmed = 'payment_confirmed';
  static const String paymentConfirmedBody = 'payment_confirmed_body';
  static const String bookingDetails = 'booking_details';
  static const String orderId = 'order_id';
  static const String date = 'date';
  static const String estimatedDelivery = 'estimated_delivery';
  static const String pharmacyLabel = 'pharmacy_label';
  static const String prescription = 'prescription';
  static const String medicinesCount = 'medicines_count';
  static const String totalPaid = 'total_paid';
  static const String paidViaCash = 'paid_via_cash';
  static const String goHome = 'go_home';

  // ─── Chat ────────────────────────────────────────────────────────────────
  static const String online = 'online';
  static const String typeYourMessage = 'type_your_message';

  // ─── Appointments tab ────────────────────────────────────────────────────
  static const String myAppointments = 'my_appointments';
  static const String upcoming = 'upcoming';
  static const String past = 'past';
  static const String noAppointmentsYet = 'no_appointments_yet';
  static const String findADoctor = 'find_a_doctor';
  static const String joinOpensSoon = 'join_opens_soon';

  // ─── Pharmacy tab ────────────────────────────────────────────────────────
  static const String pharmacyTitle = 'pharmacy_title';
  static const String pharmacySubtitle = 'pharmacy_subtitle';
  static const String addToCart = 'add_to_cart';
  static const String addedToCart = 'added_to_cart';
  static const String inStock = 'in_stock';
  static const String outOfStock = 'out_of_stock';

  // ─── Feedback ────────────────────────────────────────────────────────────
  static const String otpResent = 'otp_resent';
  static const String somethingWentWrong = 'something_went_wrong';
  static const String noInternetConnection = 'no_internet_connection';
}
