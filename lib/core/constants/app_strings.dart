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

  // ─── Find a doctor ───────────────────────────────────────────────────────
  static const String findADoctorTitle = 'find_a_doctor_title';
  static const String exploreCategories = 'explore_categories';
  static const String findCategoryDoctors = 'find_category_doctors';
  static const String categoryDoctorLists = 'category_doctor_lists';

  // ─── Doctor filter ───────────────────────────────────────────────────────
  static const String priceRange = 'price_range';
  static const String rating = 'rating';
  static const String starCount = 'star_count';
  static const String reset = 'reset';
  static const String apply = 'apply';

  // ─── Doctor details ──────────────────────────────────────────────────────
  static const String doctorDetails = 'doctor_details';
  static const String reviewsCount = 'reviews_count';
  static const String perConsultation = 'per_consultation';
  static const String yearsCount = 'years_count';
  static const String experience = 'experience';
  static const String patients = 'patients';
  static const String workingTime = 'working_time';
  static const String languagesSpoken = 'languages_spoken';
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

  // ─── Appointments ────────────────────────────────────────────────────────
  static const String needCare = 'need_care';
  static const String needCareBody = 'need_care_body';
  static const String bookAppointmentCta = 'book_appointment_cta';
  static const String appointmentHistory = 'appointment_history';
  static const String upcomingAppointmentsTab = 'upcoming_appointments_tab';
  static const String pastAppointmentsTab = 'past_appointments_tab';
  static const String cancelledAppointmentTab = 'cancelled_appointment_tab';
  static const String today = 'today';
  static const String joinVisit = 'join_visit';
  static const String bookAgain = 'book_again';
  static const String review = 'review';
  static const String reschedule = 'reschedule';
  static const String cancelAppointment = 'cancel_appointment';
  static const String cancelReason = 'cancel_reason';
  static const String cancelReasonHint = 'cancel_reason_hint';
  static const String cancelNow = 'cancel_now';
  static const String appointmentCancelled = 'appointment_cancelled';
  static const String howWasYourExperience = 'how_was_your_experience';
  static const String submitReview = 'submit_review';
  static const String reviewSubmitted = 'review_submitted';
  static const String noAppointmentsInTab = 'no_appointments_in_tab';

  // ─── Video consultation ──────────────────────────────────────────────────
  static const String goodConnection = 'good_connection';

  /// What the call stage says before the other party's picture arrives.
  static const String callAskingPermission = 'call_asking_permission';
  static const String callConnecting = 'call_connecting';
  static const String callWaitingForOther = 'call_waiting_for_other';
  static const String callRinging = 'call_ringing';
  static const String doctorVideoFeed = 'doctor_video_feed';
  static const String you = 'you';
  static const String callDuration = 'call_duration';
  static const String consultationHistory = 'consultation_history';
  static const String consultationComplete = 'consultation_complete';
  static const String waitingForPrescriptions = 'waiting_for_prescriptions';
  static const String checkMedicalVault = 'check_medical_vault';
  static const String backToHome = 'back_to_home';

  // ─── Appointments tab ────────────────────────────────────────────────────
  static const String myAppointments = 'my_appointments';
  static const String upcoming = 'upcoming';
  static const String past = 'past';
  static const String noAppointmentsYet = 'no_appointments_yet';
  static const String findADoctor = 'find_a_doctor';
  static const String joinOpensSoon = 'join_opens_soon';

  // ─── Pharmacy ────────────────────────────────────────────────────────────
  static const String pharmacyTitle = 'pharmacy_title';
  static const String uploadPrescription = 'upload_prescription';
  static const String searchMedicines = 'search_medicines';
  static const String commonMedicines = 'common_medicines';
  static const String dermatologistCategories = 'dermatologist_categories';
  static const String storesNearYou = 'stores_near_you';
  static const String add = 'add';
  static const String addedToCart = 'added_to_cart';
  static const String percentOff = 'percent_off';

  static const String dropPrescriptionHere = 'drop_prescription_here';
  static const String prescriptionFileTypes = 'prescription_file_types';
  static const String browseFile = 'browse_file';

  static const String bestMatches = 'best_matches';
  static const String prescriptionOf = 'prescription_of';
  static const String medicinesIdentified = 'medicines_identified';
  static const String searchingNear = 'searching_near';
  static const String pharmaciesFound = 'pharmacies_found';
  static const String availableCount = 'available_count';
  static const String customizeMyOrder = 'customize_my_order';

  static const String selectMedicines = 'select_medicines';
  static const String change = 'change';
  static const String medicinesAvailable = 'medicines_available';
  static const String deselectAll = 'deselect_all';
  static const String selectAll = 'select_all';
  static const String notAvailable = 'not_available';
  static const String selectedCount = 'selected_count';
  static const String addToCart = 'add_to_cart';

  static const String yourCard = 'your_card';
  static const String deliveryFrom = 'delivery_from';
  static const String addOrRemoveMedicines = 'add_or_remove_medicines';
  static const String pickupYourself = 'pickup_yourself';
  static const String orderSummary = 'order_summary';
  static const String subtotalItems = 'subtotal_items';
  static const String deliveryFee = 'delivery_fee';
  static const String walletCredit = 'wallet_credit';
  static const String total = 'total';
  static const String proceedToPayment = 'proceed_to_payment';

  static const String payment = 'payment';
  static const String orderHeadline = 'order_headline';
  static const String medicinesInOrder = 'medicines_in_order';
  static const String noDeliveryAddress = 'no_delivery_address';
  static const String addDeliveryAddressFirst = 'add_delivery_address_first';
  static const String cartIsEmpty = 'cart_is_empty';
  static const String orderConfirmedRef = 'order_confirmed_ref';
  static const String deliveryAddress = 'delivery_address';
  static const String addLocation = 'add_location';
  static const String changeLocation = 'change_location';
  static const String uploadDoorImage = 'upload_door_image';
  static const String enterNote = 'enter_note';
  static const String updateLocation = 'update_location';
  static const String placeOrder = 'place_order';
  static const String securedNote = 'secured_note';

  static const String beingPrepared = 'being_prepared';
  static const String beingPreparedBody = 'being_prepared_body';
  static const String stepOf = 'step_of';
  static const String estimatedDelivery2 = 'estimated_delivery_2';
  static const String orderProgress = 'order_progress';
  static const String trackNow = 'track_now';

  static const String help = 'help';
  static const String stepsLeft = 'steps_left';
  static const String pickUpFrom = 'pick_up_from';
  static const String deliverTo = 'deliver_to';

  static const String feedback = 'feedback';
  static const String contactlessDelivered = 'contactless_delivered';
  static const String couriersResponsible = 'couriers_responsible';
  static const String writeOrderFeedback = 'write_order_feedback';
  static const String skipToOrderFeedback = 'skip_to_order_feedback';

  // ─── Profile ─────────────────────────────────────────────────────────────
  /// Generic dismiss label for confirm dialogs.
  static const String cancel = 'cancel';

  /// Generic advance label.
  static const String continueLabel = 'continue_label';

  static const String profileTitle = 'profile_title';
  static const String edit = 'edit';
  static const String myHealthProfile = 'my_health_profile';
  static const String myOrderHistory = 'my_order_history';
  static const String myWallet = 'my_wallet';
  static const String settings = 'settings';

  /// The Profile row. The screen it opens is titled [becomeAPartner] — the
  /// designs word the entry point and the destination differently.
  static const String partnerWithBienify = 'partner_with_bienify';
  static const String becomeAPartner = 'become_a_partner';
  static const String logOut = 'log_out';
  static const String readyToLogOut = 'ready_to_log_out';

  static const String changePassword = 'change_password';
  static const String aboutUs = 'about_us';
  static const String termsAndConditions = 'terms_and_conditions';
  static const String privacyPolicy = 'privacy_policy';

  static const String oldPasswordLabel = 'old_password_label';
  static const String oldPasswordHint = 'old_password_hint';
  static const String newPasswordLabel2 = 'new_password_label_2';
  static const String newPasswordHint2 = 'new_password_hint_2';
  static const String reEnterNewPasswordLabel = 're_enter_new_password_label';
  static const String reEnterNewPasswordHint = 're_enter_new_password_hint';
  static const String passwordChanged = 'password_changed';

  static const String joinAsPharmacyOwner = 'join_as_pharmacy_owner';
  static const String joinAsRider = 'join_as_rider';
  static const String partnerApplicationSent = 'partner_application_sent';

  static const String noOrdersYet = 'no_orders_yet';
  static const String noOrdersYetBody = 'no_orders_yet_body';
  static const String itemsOnDate = 'items_on_date';

  static const String noPaymentMethod = 'no_payment_method';
  static const String noPaymentMethodBody = 'no_payment_method_body';
  static const String addPaymentMethod = 'add_payment_method';
  static const String availableBalance = 'available_balance';

  // ─── Health profile ──────────────────────────────────────────────────────
  static const String records = 'records';
  static const String consultation = 'consultation';
  static const String bienifyHelp = 'bienify_help';
  static const String allPrescriptions = 'all_prescriptions';
  static const String allTestReports = 'all_test_reports';
  static const String orderHistory = 'order_history';
  static const String chatWithUs = 'chat_with_us';
  static const String callWithUs = 'call_with_us';
  static const String deleteAccount = 'delete_account';
  static const String deleteAccountQuestion = 'delete_account_question';
  static const String delete = 'delete';

  static const String yourPrescriptions = 'your_prescriptions';
  static const String yourMedicalVault = 'your_medical_vault';
  static const String labResult = 'lab_result';
  static const String view = 'view';
  static const String uploadPrescriptionAction = 'upload_prescription_action';
  static const String noUploadsYet = 'no_uploads_yet';
  static const String documentRemoved = 'document_removed';

  static const String labReports = 'lab_reports';
  static const String radiologyReports = 'radiology_reports';
  static const String digitalPrescriptionNumbered =
      'digital_prescription_numbered';

  static const String filterDelivered = 'filter_delivered';
  static const String filterPending = 'filter_pending';
  static const String filterCancelled = 'filter_cancelled';
  static const String orderSummaryLine = 'order_summary_line';

  static const String reviewShop = 'review_shop';
  static const String allMedicines = 'all_medicines';
  static const String writeReviews = 'write_reviews';

  static const String paymentOptions = 'payment_options';
  static const String debitCreditCard = 'debit_credit_card';
  static const String walletTitle = 'wallet_title';
  static const String addAccount = 'add_account';
  static const String availableBalanceCaps = 'available_balance_caps';
  static const String totalSpent = 'total_spent';
  static const String orderCount = 'order_count';
  static const String addedThisMonth = 'added_this_month';
  static const String activeSaver = 'active_saver';
  static const String transactionHistory = 'transaction_history';
  static const String noTransactionsYet = 'no_transactions_yet';
  static const String noNotificationsYet = 'no_notifications_yet';
  static const String noPaymentPointsNearby = 'no_payment_points_nearby';
  static const String paymentNotReceivedYet = 'payment_not_received_yet';
  static const String paymentCodeExpired = 'payment_code_expired';
  static const String nameOnCard = 'name_on_card';
  static const String addDebitCard = 'add_debit_card';
  static const String debitCard = 'debit_card';
  static const String cardNumber = 'card_number';
  static const String cardNumberHint = 'card_number_hint';
  static const String cardHolder = 'card_holder';
  static const String cardHolderHint = 'card_holder_hint';
  static const String cardExpiry = 'card_expiry';
  static const String cardExpiryHint = 'card_expiry_hint';
  static const String cardCvv = 'card_cvv';
  static const String cardCvvHint = 'card_cvv_hint';
  static const String saveCard = 'save_card';
  static const String cardSaved = 'card_saved';
  static const String makeDefault = 'make_default';
  static const String defaultCard = 'default_card';
  static const String errorCardNumber = 'error_card_number';
  static const String errorCardHolder = 'error_card_holder';
  static const String errorCardExpiry = 'error_card_expiry';
  static const String errorCardCvv = 'error_card_cvv';

  // ─── Medical vault ───────────────────────────────────────────────────────
  static const String prescriptions = 'prescriptions';
  static const String pastAppointmentsTitle = 'past_appointments_title';
  static const String myTestsAndResults = 'my_tests_and_results';

  static const String prescriptionDetails = 'prescription_details';
  static const String digitalPrescription = 'digital_prescription';
  static const String prescriptionId = 'prescription_id';
  static const String active = 'active';
  static const String expired = 'expired';
  static const String prescribedBy = 'prescribed_by';
  static const String diagnosis = 'diagnosis';
  static const String medications = 'medications';
  static const String dosageLabel = 'dosage_label';
  static const String frequencyLabel = 'frequency_label';
  static const String instructionsLabel = 'instructions_label';
  static const String downloadPrescription = 'download_prescription';

  static const String resultsFilterAll = 'results_filter_all';
  static const String labResults = 'lab_results';
  static const String radiologyResults = 'radiology_results';
  static const String activeOrders = 'active_orders';
  static const String resultsReady = 'results_ready';
  static const String reviewed = 'reviewed';
  static const String awaitingReview = 'awaiting_review';
  static const String requestSent = 'request_sent';
  static const String fromDoctor = 'from_doctor';
  static const String viewReview = 'view_review';
  static const String uploadReport = 'upload_report';
  static const String noTestsYet = 'no_tests_yet';

  static const String laboratoryResults = 'laboratory_results';
  static const String orderInformation = 'order_information';
  static const String orderDate = 'order_date';
  static const String validFor = 'valid_for';
  static const String patientInformation = 'patient_information';
  static const String patientNameLabel = 'patient_name_label';
  static const String dateOfBirth = 'date_of_birth';
  static const String medicalRecordNumber = 'medical_record_number';
  static const String insurance = 'insurance';
  static const String memberId = 'member_id';
  static const String studyOrdered = 'study_ordered';
  static const String modality = 'modality';
  static const String bodyRegion = 'body_region';
  static const String clinicalIndication = 'clinical_indication';
  static const String specialInstructions = 'special_instructions';
  static const String orderingPhysician = 'ordering_physician';
  static const String electronicallySigned = 'electronically_signed';
  static const String shaVerified = 'sha_verified';
  static const String confidentialNote = 'confidential_note';
  static const String downloadPdf = 'download_pdf';
  static const String chooseTestingLocation = 'choose_testing_location';
  static const String preferredHospitalSelected = 'preferred_hospital_selected';
  static const String bookInExternalApp = 'book_in_external_app';
  static const String completedMyTest = 'completed_my_test';

  static const String chooseLaboratoryCentre = 'choose_laboratory_centre';
  static const String awayOpenBookingApp = 'away_open_booking_app';

  static const String uploadYourReport = 'upload_your_report';
  static const String testComplete = 'test_complete';
  static const String testCompleteBody = 'test_complete_body';
  static const String yourNote = 'your_note';
  static const String optional = 'optional';
  static const String yourNoteHint = 'your_note_hint';
  static const String reportDocument = 'report_document';
  static const String addReportDocument = 'add_report_document';
  static const String uploadAndNotify = 'upload_and_notify';
  static const String resultsSubmitted = 'results_submitted';
  static const String resultsSubmittedBody = 'results_submitted_body';

  static const String reportAndDoctorReview = 'report_and_doctor_review';
  static const String reportIsWith = 'report_is_with';
  static const String reportIsWithBody = 'report_is_with_body';
  static const String chooseTheNextStep = 'choose_the_next_step';
  static const String doctorWantsToTalk = 'doctor_wants_to_talk';
  static const String acceptFollowUp = 'accept_follow_up';
  static const String message = 'message';
  static const String referAndEscalation = 'refer_and_escalation';
  static const String reasonForTestHint = 'reason_for_test_hint';

  // ─── Doctor ──────────────────────────────────────────────────────────────
  static const String earningWithdraw = 'earning_withdraw';
  static const String requestPayout = 'request_payout';
  static const String paidOut = 'paid_out';
  static const String recentConsultations = 'recent_consultations';
  static const String amountToWithdraw = 'amount_to_withdraw';
  static const String enterAValidAmount = 'enter_a_valid_amount';
  static const String noPayoutAccount = 'no_payout_account';
  static const String prescriptionNeedsAppointment =
      'prescription_needs_appointment';
  static const String testNeedsPatient = 'test_needs_patient';
  static const String selectPayoutMethod = 'select_payout_method';
  static const String payoutRequested = 'payout_requested';
  static const String addPayoutAccount = 'add_payout_account';
  static const String payoutAccountAdded = 'payout_account_added';
  static const String payoutAccountNeedsDetails = 'payout_account_needs_details';
  static const String payoutKindBank = 'payout_kind_bank';
  static const String payoutKindMobileMoney = 'payout_kind_mobile_money';
  static const String payoutAccountName = 'payout_account_name';
  static const String payoutAccountNumber = 'payout_account_number';
  static const String payoutBankName = 'payout_bank_name';
  static const String completed = 'completed';
  static const String editProfile = 'edit_profile';
  static const String fullName = 'full_name';
  static const String specialty = 'specialty';
  static const String countryOfPractice = 'country_of_practice';
  static const String preferredLanguage = 'preferred_language';
  static const String biographyLabel = 'biography_label';
  static const String biographyHint = 'biography_hint';
  static const String licenseNumber = 'license_number';
  static const String licenseNumberHint = 'license_number_hint';
  static const String uploadLicense = 'upload_license';
  static const String clickToUpload = 'click_to_upload';
  static const String licenseFileTypes = 'license_file_types';
  static const String licenseAttached = 'license_attached';
  static const String noteLabel = 'note_label';
  static const String registrationReviewNote = 'registration_review_note';
  static const String profileSubmitted = 'profile_submitted';
  static const String newAppointment = 'new_appointment';
  static const String completedAppointment = 'completed_appointment';
  static const String appointmentDetails = 'appointment_details';
  static const String patientsPrescription = 'patients_prescription';
  static const String roomNotOpenYet = 'room_not_open_yet';
  static const String joinVisit2 = 'join_visit_2';
  static const String writePrescriptions = 'write_prescriptions';
  static const String writePrescription = 'write_prescription';
  static const String addNewMedicine = 'add_new_medicine';
  static const String medicineName = 'medicine_name';
  static const String enterDurationInDays = 'enter_duration_in_days';
  static const String dailyDose = 'daily_dose';
  static const String instructionsField = 'instructions_field';
  static const String save = 'save';
  static const String submitYourPatients = 'submit_your_patients';
  static const String medicineAdded = 'medicine_added';
  static const String prescriptionSent = 'prescription_sent';
  static const String prescriptionNeedsFields = 'prescription_needs_fields';
  static const String timesDaily = 'times_daily';

  /// The structured prescription form: strength and its unit, how many doses
  /// a day, and when they are taken relative to eating.
  /// The prescription form asks for the drug alone; the pharmacy's own
  /// Add Medicine form keeps the strength in the product name, so the two
  /// hints cannot be shared.
  static const String prescriptionMedicineNameHint =
      'prescription_medicine_name_hint';
  static const String strengthLabel = 'strength_label';
  static const String strengthHint = 'strength_hint';
  static const String unitLabel = 'unit_label';
  static const String timesPerDayLabel = 'times_per_day_label';
  static const String whenToTakeLabel = 'when_to_take_label';
  static const String timingAnytime = 'timing_anytime';
  static const String timingBeforeMeal = 'timing_before_meal';
  static const String timingAfterMeal = 'timing_after_meal';
  static const String timingWithFood = 'timing_with_food';
  static const String notesLabel = 'notes_label';
  static const String notesHint = 'notes_hint';
  static const String searchPatientName = 'search_patient_name';
  static const String messageTitle = 'message_title';
  static const String navMessage = 'nav_message';
  static const String navProfile = 'nav_profile';
  static const String goodMorning = 'good_morning';
  static const String availableBalance2 = 'available_balance_2';
  static const String withdraw = 'withdraw';
  static const String pendingApptRequests = 'pending_appt_requests';
  static const String todaysPatients = 'todays_patients';
  static const String totalEarned = 'total_earned';
  static const String totalPatients = 'total_patients';
  static const String quickActions = 'quick_actions';
  static const String setSchedule = 'set_schedule';
  static const String setFees = 'set_fees';
  static const String resultsToReview = 'results_to_review';
  static const String appointmentsOverview = 'appointments_overview';
  static const String weekly = 'weekly';
  static const String monthly = 'monthly';
  static const String upcomingAppointments2 = 'upcoming_appointments_2';
  static const String confirmed = 'confirmed';
  static const String selectYear = 'select_year';
  static const String selectMonth = 'select_month';
  static const String selectWeek = 'select_week';
  static const String start = 'start';
  static const String end = 'end';
  static const String addSlot = 'add_slot';
  static const String currentSlots = 'current_slots';
  static const String weeklySummary = 'weekly_summary';
  static const String activeDays = 'active_days';
  static const String totalHours = 'total_hours';
  static const String maxPatients = 'max_patients';
  static const String saveSchedule = 'save_schedule';
  static const String scheduleSaved = 'schedule_saved';
  static const String slotNeedsBothTimes = 'slot_needs_both_times';
  static const String selectCurrency = 'select_currency';
  static const String consultationFeeLabel = 'consultation_fee_label';
  static const String saveConsultationFee = 'save_consultation_fee';
  static const String consultationFeeSaved = 'consultation_fee_saved';
  static const String notAvailableYet = 'not_available_yet';
  static const String notAvailableYetBody = 'not_available_yet_body';

  // ─── Results to Review ───────────────────────────────────────────────────
  static const String patientsTab = 'patients_tab';
  static const String labOrders = 'lab_orders';
  static const String radiologyOrders = 'radiology_orders';
  static const String labRequests = 'lab_requests';
  static const String radiologyRequests = 'radiology_requests';
  static const String filterInProgress = 'filter_in_progress';
  static const String filterToReview = 'filter_to_review';
  static const String critical = 'critical';
  static const String noRequestsYet = 'no_requests_yet';

  static const String requestTest = 'request_test';
  static const String chooseOrder = 'choose_order';
  static const String labOrder = 'lab_order';
  static const String radiologyOrder = 'radiology_order';
  static const String labTest = 'lab_test';
  static const String radiology = 'radiology';

  static const String requestLabTest = 'request_lab_test';
  static const String requestRadiologyTest = 'request_radiology_test';
  static const String laboratoryRequest = 'laboratory_request';
  static const String radiologyRequest = 'radiology_request';
  static const String externalBookingNote = 'external_booking_note';
  static const String searchLabTest = 'search_lab_test';
  static const String searchRadiologyTest = 'search_radiology_test';
  static const String selectLabTest = 'select_lab_test';
  static const String selectRadiologyTest = 'select_radiology_test';
  static const String selectRadiologySubtest = 'select_radiology_subtest';
  static const String enterNewLabTest = 'enter_new_lab_test';
  static const String enterTestName = 'enter_test_name';
  static const String study = 'study';
  static const String details = 'details';
  static const String reviewAndSubmit = 'review_and_submit';
  static const String clinicalNotes = 'clinical_notes';
  static const String patientsInstructions = 'patients_instructions';
  static const String patientsInstructionsHint = 'patients_instructions_hint';
  static const String electricSign = 'electric_sign';
  static const String clear = 'clear';
  static const String priority = 'priority';
  static const String priorityRoutine = 'priority_routine';
  static const String priorityUrgent = 'priority_urgent';
  static const String priorityStat = 'priority_stat';
  static const String submitImagingOrder = 'submit_imaging_order';
  static const String submitLabOrder = 'submit_lab_order';
  static const String orderSubmitted = 'order_submitted';
  static const String pickATestFirst = 'pick_a_test_first';
  static const String signatureSaved = 'signature_saved';
  static const String signFirst = 'sign_first';

  static const String ordered = 'ordered';
  static const String stepFacilitySelected = 'step_facility_selected';
  static const String stepTestCompleted = 'step_test_completed';
  static const String stepResultsReceived = 'step_results_received';
  static const String awaitingPatientUpload = 'awaiting_patient_upload';
  static const String awaitingPatientUploadBody =
      'awaiting_patient_upload_body';
  static const String patientsPreferredHospital = 'patients_preferred_hospital';
  static const String uploadedDocuments = 'uploaded_documents';
  static const String laboratoryReport = 'laboratory_report';
  static const String chooseYourReview = 'choose_your_review';

  static const String chooseReviewOption = 'choose_review_option';
  static const String chooseYourReviewOption = 'choose_your_review_option';
  static const String massagePatient = 'massage_patient';
  static const String requestFollowUpVisit = 'request_follow_up_visit';
  static const String orderAdditionalTest = 'order_additional_test';
  static const String referEscalateCare = 'refer_escalate_care';

  static const String writeMessage = 'write_message';
  static const String writeYourMessage = 'write_your_message';
  static const String submitPatients = 'submit_patients';
  static const String requestFollowUpTitle = 'request_follow_up_title';
  static const String followUpReason = 'follow_up_reason';
  static const String requestFollowUp = 'request_follow_up';
  static const String followUpRequested = 'follow_up_requested';
  static const String referEscalation = 'refer_escalation';
  static const String writeYourOption = 'write_your_option';
  static const String referOptionHint = 'refer_option_hint';
  static const String sentToPatient = 'sent_to_patient';

  // ─── Pharmacy owner ──────────────────────────────────────────────────────
  static const String navOrders = 'nav_orders';
  static const String navMedicines = 'nav_medicines';

  static const String newOrdersStat = 'new_orders_stat';
  static const String newPrescriptionsStat = 'new_prescriptions_stat';
  static const String todaysEarnings = 'todays_earnings';
  static const String lowStockItems = 'low_stock_items';
  static const String recentOrders = 'recent_orders';
  static const String lowStockAlerts = 'low_stock_alerts';
  static const String itemsLeft = 'items_left';
  static const String outOfStock = 'out_of_stock';

  static const String ordersTitle = 'orders_title';
  static const String orderDetailsTitle = 'order_details_title';
  static const String stateNew = 'state_new';
  static const String stateAccepted = 'state_accepted';
  static const String stateDeclined = 'state_declined';
  static const String statePreparing = 'state_preparing';
  static const String stateOutForDelivery = 'state_out_for_delivery';
  static const String stateDelivered = 'state_delivered';
  static const String patientInfo = 'patient_info';
  static const String prescriptionSection = 'prescription_section';
  static const String medicineList = 'medicine_list';
  static const String acceptOrder = 'accept_order';
  static const String declineOrder = 'decline_order';
  static const String orderAccepted = 'order_accepted';
  static const String orderDeclined = 'order_declined';
  static const String noOrdersHere = 'no_orders_here';

  static const String notifications = 'notifications';
  static const String seeMore = 'see_more';

  static const String medicinesTitle = 'medicines_title';
  static const String addLabel = 'add_label';
  static const String addMedicine = 'add_medicine';
  static const String editMedicine = 'edit_medicine';
  static const String updateMedicine = 'update_medicine';
  static const String medicineNameLabel = 'medicine_name_label';
  static const String medicineNameHint = 'medicine_name_hint';
  static const String categoryLabel = 'category_label';
  static const String medicineImageLabel = 'medicine_image_label';
  static const String medicineImageHint = 'medicine_image_hint';
  static const String priceUsdLabel = 'price_usd_label';
  static const String stockQuantityLabel = 'stock_quantity_label';
  static const String expiryDateLabel = 'expiry_date_label';
  static const String medicineSaved = 'medicine_saved';
  static const String medicineRemoved = 'medicine_removed';
  static const String medicineNeedsFields = 'medicine_needs_fields';
  static const String medicineDelisted = 'medicine_delisted';
  static const String deleteMedicineQuestion = 'delete_medicine_question';
  static const String noMedicinesYet = 'no_medicines_yet';

  static const String paymentsAndCredit = 'payments_and_credit';
  static const String businessEmail = 'business_email';
  static const String countryOfPharmacy = 'country_of_pharmacy';
  static const String pharmacyLocation = 'pharmacy_location';
  static const String businessLicenseNumber = 'business_license_number';
  static const String businessLicenseHint = 'business_license_hint';
  static const String uploadLicenseDocument = 'upload_license_document';
  static const String uploadShopLogo = 'upload_shop_logo';
  static const String uploadShopBanner = 'upload_shop_banner';
  static const String uploadHint = 'upload_hint';
  static const String uploadFileTypes = 'upload_file_types';
  static const String updateShopInformation = 'update_shop_information';
  static const String shopUpdated = 'shop_updated';

  /// The courier's own version of the two above — they edit a rider profile,
  /// not a pharmacy.
  static const String updateRiderInformation = 'update_rider_information';
  static const String riderUpdated = 'rider_updated';

  // ─── Photo upload ────────────────────────────────────────────────────────
  static const String takeAPhoto = 'take_a_photo';
  static const String chooseFromGallery = 'choose_from_gallery';
  static const String replacePhoto = 'replace_photo';
  static const String uploadPhoto = 'upload_photo';
  static const String photoNeeded = 'photo_needed';
  static const String licenceNumberNeeded = 'licence_number_needed';

  // ─── Rider ───────────────────────────────────────────────────────────────
  static const String navEarnings = 'nav_earnings';

  static const String riderGuide = 'rider_guide';
  static const String howItWorks = 'how_it_works';
  static const String howItWorksBody = 'how_it_works_body';
  static const String stepSignUp = 'step_sign_up';
  static const String stepSignUpBody = 'step_sign_up_body';
  static const String stepSignUpNote = 'step_sign_up_note';
  static const String stepGetOrders = 'step_get_orders';
  static const String stepGetOrdersBody = 'step_get_orders_body';
  static const String stepGetOrdersNote = 'step_get_orders_note';
  static const String stepPickDeliver = 'step_pick_deliver';
  static const String stepPickDeliverBody = 'step_pick_deliver_body';
  static const String stepPickDeliverNote = 'step_pick_deliver_note';
  static const String stepEarnMoney = 'step_earn_money';
  static const String stepEarnMoneyBody = 'step_earn_money_body';
  static const String stepEarnMoneyNote = 'step_earn_money_note';
  static const String stepBuildRating = 'step_build_rating';
  static const String stepBuildRatingBody = 'step_build_rating_body';
  static const String stepBuildRatingNote = 'step_build_rating_note';
  static const String applyRiderTitle = 'apply_rider_title';
  static const String applyRiderBody = 'apply_rider_body';
  static const String applyNow = 'apply_now';

  static const String uploadProfileTitle = 'upload_profile_title';
  static const String heyName = 'hey_name';
  static const String applyingForRider = 'applying_for_rider';
  static const String takeSelfie = 'take_selfie';
  static const String identityVerification = 'identity_verification';
  static const String frontOfIdCard = 'front_of_id_card';
  static const String backOfIdCard = 'back_of_id_card';
  static const String ensureClearPhoto = 'ensure_clear_photo';
  static const String vehicleInformation = 'vehicle_information';
  static const String vehiclesType = 'vehicles_type';
  static const String vehicleBicycle = 'vehicle_bicycle';
  static const String vehicleBike = 'vehicle_bike';
  static const String vehicleCar = 'vehicle_car';
  static const String drivingLicense = 'driving_license';
  static const String vehiclesPhoto = 'vehicles_photo';
  static const String locationAndAvailability = 'location_and_availability';
  static const String country = 'country';
  static const String city = 'city';
  static const String locationLabel = 'location_label';
  static const String preferredDeliveryZone = 'preferred_delivery_zone';
  static const String liveLocationPermission = 'live_location_permission';
  static const String paymentSetup = 'payment_setup';
  static const String riderReady = 'rider_ready';
  static const String riderReadyBody = 'rider_ready_body';
  static const String applicationSent = 'application_sent';

  static const String deliveries = 'deliveries';
  static const String onlineAcceptingOrders = 'online_accepting_orders';
  static const String offlineNotAccepting = 'offline_not_accepting';
  static const String viewOrders = 'view_orders';
  static const String ordersAvailable = 'orders_available';
  static const String earnings = 'earnings';
  static const String recentDeliveries = 'recent_deliveries';

  static const String orderRequests = 'order_requests';
  static const String newCount = 'new_count';
  static const String newRequest = 'new_request';
  static const String acceptedRequest = 'accepted_request';
  static const String cancelledRequest = 'cancelled_request';
  static const String decline = 'decline';
  static const String accept = 'accept';
  static const String trackLive = 'track_live';
  static const String requestAccepted = 'request_accepted';
  static const String requestDeclined = 'request_declined';
  static const String noRequestsHere = 'no_requests_here';

  static const String minutesAway = 'minutes_away';
  static const String nowArriving = 'now_arriving';
  static const String latestArrival = 'latest_arrival';
  static const String viewNote = 'view_note';
  static const String customerNote = 'customer_note';
  static const String customer = 'customer';
  static const String arrived = 'arrived';

  /// The two steps a parcel takes before it arrives, as the courier's one
  /// button names them in turn.
  static const String confirmPickedUp = 'confirm_picked_up';
  static const String confirmOnTheWay = 'confirm_on_the_way';
  static const String deliveryAlreadyFinished = 'delivery_already_finished';

  static const String deliveryCompleted = 'delivery_completed';
  static const String orderDeliveredTitle = 'order_delivered_title';
  static const String orderDeliveredBody = 'order_delivered_body';
  static const String orderIdLabel = 'order_id_label';
  static const String deliveredTo = 'delivered_to';
  static const String deliveryTime = 'delivery_time';

  static const String overview = 'overview';
  static const String earningsToday = 'earnings_today';
  static const String earningsThisWeek = 'earnings_this_week';
  static const String deliveriesCount = 'deliveries_count';
  static const String nextPayout = 'next_payout';
  static const String accumulated = 'accumulated';
  static const String minimumPayout = 'minimum_payout';
  static const String history = 'history';
  // ─── Feedback ────────────────────────────────────────────────────────────
  static const String otpResent = 'otp_resent';
  static const String somethingWentWrong = 'something_went_wrong';
  static const String noInternetConnection = 'no_internet_connection';
}
