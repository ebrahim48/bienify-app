import 'package:get/get.dart';

import '../../features/Role/patient/appointments/presentation/bindings/appointments_bindings.dart';
import '../../features/Role/patient/appointments/presentation/screens/consultation_history_screen.dart';
import '../../features/Role/patient/appointments/presentation/screens/video_call_screen.dart';
import '../../features/Role/patient/auth/presentation/bindings/auth_bindings.dart';
import '../../features/Role/patient/auth/presentation/controllers/auth_flow.dart';
import '../../features/Role/patient/auth/presentation/screens/auth_status_screen.dart';
import '../../features/Role/patient/auth/presentation/screens/login_screen.dart';
import '../../features/Role/patient/auth/presentation/screens/new_password_screen.dart';
import '../../features/Role/patient/auth/presentation/screens/otp_screen.dart';
import '../../features/Role/patient/auth/presentation/screens/phone_number_screen.dart';
import '../../features/Role/patient/auth/presentation/screens/profile_credentials_screen.dart';
import '../../features/Role/patient/auth/presentation/screens/profile_setup_screen.dart';
import '../../features/Role/patient/booking/presentation/screens/payment_summary_screen.dart';
import '../../features/Role/patient/cash_payment_process/presentation/bindings/cash_payment_bindings.dart';
import '../../features/Role/patient/cash_payment_process/presentation/screens/how_to_pay_screen.dart';
import '../../features/Role/patient/cash_payment_process/presentation/screens/nearby_payment_points_screen.dart';
import '../../features/Role/patient/cash_payment_process/presentation/screens/payment_confirmed_screen.dart';
import '../../features/Role/patient/cash_payment_process/presentation/screens/payment_pending_screen.dart';
import '../../features/Role/patient/chat/presentation/controllers/media_viewer_controller.dart';
import '../../features/Role/patient/chat/presentation/screens/chat_screen.dart';
import '../../features/Role/patient/chat/presentation/screens/media_viewer_screen.dart';
import '../../features/Role/patient/chat/presentation/screens/messages_screen.dart';
import '../../features/Role/patient/notifications/presentation/bindings/notifications_bindings.dart';
import '../../features/Role/patient/notifications/presentation/screens/notifications_screen.dart';
import '../../features/Role/doctor_role/presentation/bindings/doctor_bindings.dart';
import '../../features/Role/doctor_role/presentation/screens/doctor_appointment_details_screen.dart';
import '../../features/Role/doctor_role/presentation/screens/choose_review_option_screen.dart';
import '../../features/Role/doctor_role/presentation/screens/doctor_edit_profile_screen.dart';
import '../../features/Role/doctor_role/presentation/screens/doctor_notifications_screen.dart';
import '../../features/Role/doctor_role/presentation/screens/earning_withdraw_screen.dart';
import '../../features/Role/doctor_role/presentation/screens/order_detail_screen.dart';
import '../../features/Role/doctor_role/presentation/screens/request_follow_up_screen.dart';
import '../../features/Role/doctor_role/presentation/screens/request_test_screen.dart';
import '../../features/Role/doctor_role/presentation/screens/results_to_review_screen.dart';
import '../../features/Role/doctor_role/presentation/screens/review_message_screen.dart';
import '../../features/Role/doctor_role/presentation/screens/review_patient_screen.dart';
import '../../features/Role/doctor_role/presentation/screens/doctor_shell_screen.dart';
import '../../features/Role/doctor_role/presentation/screens/write_prescription_screen.dart';
import '../../features/Role/doctor_role/presentation/screens/set_schedule_screen.dart';
import '../../features/Role/patient/doctors/presentation/bindings/doctors_bindings.dart';
import '../../features/Role/patient/doctors/presentation/screens/doctor_details_screen.dart';
import '../../features/Role/patient/doctors/presentation/screens/doctor_list_screen.dart';
import '../../features/Role/patient/doctors/presentation/screens/doctor_search_screen.dart';
import '../../features/Role/patient/main/presentation/bindings/main_binding.dart';
import '../../features/Role/patient/main/presentation/screens/main_shell_screen.dart';
import '../../features/Role/patient/medical_vault/presentation/bindings/medical_vault_bindings.dart';
import '../../features/Role/patient/medical_vault/presentation/screens/all_prescriptions_screen.dart';
import '../../features/Role/patient/medical_vault/presentation/screens/all_test_reports_screen.dart';
import '../../features/Role/patient/medical_vault/presentation/screens/health_profile_screen.dart';
import '../../features/Role/patient/medical_vault/presentation/screens/past_appointments_screen.dart';
import '../../features/Role/patient/medical_vault/presentation/screens/prescription_details_screen.dart';
import '../../features/Role/patient/medical_vault/presentation/screens/report_review_screen.dart';
import '../../features/Role/patient/medical_vault/presentation/screens/results_submitted_screen.dart';
import '../../features/Role/patient/medical_vault/presentation/screens/test_order_screen.dart';
import '../../features/Role/patient/medical_vault/presentation/screens/test_results_screen.dart';
import '../../features/Role/patient/medical_vault/presentation/screens/testing_centres_screen.dart';
import '../../features/Role/patient/medical_vault/presentation/screens/upload_report_screen.dart';
import '../../features/Role/patient/profile/presentation/bindings/profile_bindings.dart';
import '../../features/Role/patient/profile/presentation/screens/add_card_screen.dart';
import '../../features/Role/patient/profile/presentation/screens/become_partner_screen.dart';
import '../../features/Role/patient/profile/presentation/screens/change_password_screen.dart';
import '../../features/Role/patient/profile/presentation/screens/legal_screen.dart';
import '../../features/Role/patient/profile/presentation/screens/order_history_screen.dart';
import '../../features/Role/patient/profile/presentation/screens/payment_options_screen.dart';
import '../../features/Role/patient/profile/presentation/screens/profile_screen.dart';
import '../../features/Role/patient/profile/presentation/screens/review_shop_screen.dart';
import '../../features/Role/patient/profile/presentation/screens/settings_screen.dart';
import '../../features/Role/patient/profile/presentation/screens/wallet_accounts_screen.dart';
import '../../features/Role/patient/profile/presentation/screens/wallet_screen.dart';
import '../../features/Role/patient/pharmacy/presentation/bindings/pharmacy_bindings.dart';
import '../../features/Role/patient/pharmacy/presentation/screens/best_matches_screen.dart';
import '../../features/Role/patient/pharmacy/presentation/screens/delivery_feedback_screen.dart';
import '../../features/Role/patient/pharmacy/presentation/screens/live_tracking_screen.dart';
import '../../features/Role/patient/pharmacy/presentation/screens/order_status_screen.dart';
import '../../features/Role/patient/pharmacy/presentation/screens/pharmacy_cart_screen.dart';
import '../../features/Role/patient/pharmacy/presentation/screens/pharmacy_payment_screen.dart';
import '../../features/Role/patient/pharmacy/presentation/screens/select_medicines_screen.dart';
import '../../features/Role/patient/pharmacy/presentation/screens/upload_prescription_screen.dart';
import '../../features/Role/rider_role/presentation/bindings/rider_bindings.dart';
import '../../features/Role/rider_role/presentation/screens/rider_application_screen.dart';
import '../../features/Role/rider_role/presentation/screens/rider_delivered_screen.dart';
import '../../features/Role/rider_role/presentation/screens/rider_edit_profile_screen.dart';
import '../../features/Role/rider_role/presentation/screens/rider_guide_screen.dart';
import '../../features/Role/rider_role/presentation/screens/rider_shell_screen.dart';
import '../../features/Role/rider_role/presentation/screens/rider_tracking_screen.dart';
import '../../features/Role/pharmacy_owner_role/presentation/bindings/shop_bindings.dart';
import '../../features/Role/pharmacy_owner_role/presentation/screens/medicine_form_screen.dart';
import '../../features/Role/pharmacy_owner_role/presentation/screens/shop_edit_profile_screen.dart';
import '../../features/Role/pharmacy_owner_role/presentation/screens/shop_notifications_screen.dart';
import '../../features/Role/pharmacy_owner_role/presentation/screens/shop_order_details_screen.dart';
import '../../features/Role/pharmacy_owner_role/presentation/screens/shop_shell_screen.dart';
import '../../features/Role/patient/onboarding/presentation/screens/location_permission_screen.dart';
import '../../features/Role/patient/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/Role/patient/splash/presentation/screens/splash_screen.dart';
import 'app_routes.dart';

/// The route table handed to `GetMaterialApp`.
///
/// Each entry pairs a screen with the binding that provides its controller,
/// so a route is the only place that knows how a screen is assembled.
abstract class AppPages {
  AppPages._();

  static const Transition _transition = Transition.cupertino;
  static const Duration _transitionDuration = Duration(milliseconds: 280);

  static final List<GetPage> routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.locationPermission,
      page: () => const LocationPermissionScreen(),
      binding: LocationPermissionBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingScreen(),
      binding: OnboardingBinding(),
      transition: Transition.fadeIn,
    ),

    // ─── Sign up ───────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.phoneNumber,
      page: () => const PhoneNumberScreen(),
      binding: PhoneNumberBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.otp,
      page: () => const OtpScreen(),
      binding: OtpBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.profileSetup,
      page: () => const ProfileSetupScreen(),
      binding: ProfileSetupBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.profileCredentials,
      page: () => const ProfileCredentialsScreen(),
      binding: ProfileSetupBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.signupSuccess,
      page: () => AuthStatusScreen.signUpComplete(),
      transition: Transition.fadeIn,
    ),

    // ─── Sign in ───────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      binding: LoginBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),

    // ─── Password recovery ─────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const PhoneNumberScreen(flow: AuthFlow.passwordReset),
      binding: PhoneNumberBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.newPassword,
      page: () => const NewPasswordScreen(),
      binding: NewPasswordBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.passwordUpdated,
      page: () => AuthStatusScreen.passwordUpdated(),
      transition: Transition.fadeIn,
    ),

    // ─── App ───────────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.home,
      page: () => const MainShellScreen(),
      binding: MainBinding(),
      transition: Transition.fadeIn,
    ),

    // ─── Discovery ─────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.search,
      page: () => const DoctorSearchScreen(),
      binding: DoctorSearchBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.doctorList,
      page: () => const DoctorListScreen(),
      binding: DoctorListBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.doctorDetails,
      page: () => const DoctorDetailsScreen(),
      binding: DoctorDetailsBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),

    // ─── Booking ───────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.paymentSummary,
      page: () => const PaymentSummaryScreen(),
      binding: PaymentBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.appointmentBooked,
      page: () => AuthStatusScreen.appointmentBooked(),
      transition: Transition.fadeIn,
    ),

    // ─── Cash Payment Process ──────────────────────────────────────────────
    GetPage(
      name: AppRoutes.howToPay,
      page: () => const HowToPayScreen(),
      binding: HowToPayBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.paymentPoints,
      page: () => const NearbyPaymentPointsScreen(),
      binding: PaymentPointsBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.paymentPending,
      page: () => const PaymentPendingScreen(),
      binding: PaymentPendingBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.paymentConfirmed,
      page: () => const PaymentConfirmedScreen(),
      binding: PaymentConfirmedBinding(),
      transition: Transition.fadeIn,
    ),

    // ─── Pharmacy ──────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.uploadPrescription,
      page: () => const UploadPrescriptionScreen(),
      binding: PrescriptionBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.pharmacyMatches,
      page: () => const BestMatchesScreen(),
      binding: PrescriptionBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.selectMedicines,
      page: () => const SelectMedicinesScreen(),
      binding: SelectMedicinesBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.pharmacyCart,
      page: () => const PharmacyCartScreen(),
      binding: PharmacyCartBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.pharmacyPayment,
      page: () => const PharmacyPaymentScreen(),
      binding: PharmacyCartBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.pharmacyOrder,
      page: () => const OrderStatusScreen(),
      binding: OrderTrackingBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.liveTracking,
      page: () => const LiveTrackingScreen(),
      binding: OrderTrackingBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.deliveryFeedback,
      page: () => const DeliveryFeedbackScreen(),
      transition: Transition.fadeIn,
    ),

    // ─── Consultation ──────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.videoCall,
      page: () => const VideoCallScreen(),
      binding: VideoCallBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.consultationHistory,
      page: () => const ConsultationHistoryScreen(),
      transition: Transition.fadeIn,
    ),

    // ─── Notifications ─────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsScreen(),
      binding: NotificationsBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),

    // ─── Messaging ─────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.messages,
      page: () => const MessagesScreen(),
      binding: MessagesBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.chat,
      page: () => const ChatScreen(),
      binding: ChatBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.mediaViewer,
      page: () => const MediaViewerScreen(),
      // Bound here rather than in a `Bindings` class: the controller needs the
      // arguments, which a binding cannot see until the page is being built.
      binding: BindingsBuilder(() {
        final args = Get.arguments as MediaViewerArgs;
        Get.put(
          MediaViewerController(
            items: args.items,
            initialIndex: args.initialIndex,
          ),
        );
      }),
      // Fades in from the bubble rather than sliding, which is what a photo
      // opening full screen is expected to do.
      transition: Transition.fadeIn,
      transitionDuration: _transitionDuration,
    ),

    // ─── Profile ───────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileScreen(),
      binding: ProfileBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.orderHistory,
      page: () => const OrderHistoryScreen(),
      binding: AccountBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.wallet,
      page: () => const WalletScreen(),
      binding: AccountBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.paymentOptions,
      page: () => const PaymentOptionsScreen(),
      binding: AccountBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.addDebitCard,
      page: () => const AddCardScreen(),
      binding: AddCardBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.walletAccounts,
      page: () => const WalletAccountsScreen(),
      binding: AccountBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.reviewShop,
      page: () => const ReviewShopScreen(),
      binding: AccountBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.becomePartner,
      page: () => const BecomePartnerScreen(),
      binding: PartnerBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsScreen(),
      binding: SettingsBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.changePassword,
      page: () => const ChangePasswordScreen(),
      binding: ChangePasswordBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    // One screen for About Us, Terms and Privacy; the document arrives as the
    // route argument.
    GetPage(
      name: AppRoutes.legal,
      page: () => const LegalScreen(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),

    // ─── Doctor ────────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.doctorHome,
      page: () => const DoctorShellScreen(),
      binding: DoctorShellBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.doctorSetSchedule,
      page: () => const SetScheduleScreen(),
      binding: DoctorScheduleBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.doctorAppointmentDetails,
      page: () => const DoctorAppointmentDetailsScreen(),
      binding: DoctorAppointmentsBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.doctorWritePrescription,
      page: () => const WritePrescriptionScreen(),
      binding: WritePrescriptionBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    // The call and its summary are the patient's own screens with the role
    // flipped — one video screen, one summary, two entry points.
    GetPage(
      name: AppRoutes.doctorVideoCall,
      page: () => const VideoCallScreen(),
      binding: DoctorVideoCallBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.doctorConsultationDone,
      page: () => const ConsultationHistoryScreen(isDoctor: true),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.doctorEarnings,
      page: () => const EarningWithdrawScreen(),
      binding: EarningsBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.doctorEditProfile,
      page: () => const DoctorEditProfileScreen(),
      binding: DoctorProfileBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.doctorNotifications,
      page: () => const DoctorNotificationsScreen(),
      binding: DoctorNotificationsBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),

    // Results to Review, and the ordering / reviewing flow behind it. Every
    // screen here reads the same controller, so one binding covers them all —
    // apart from the wizard, which is built for the order being placed.
    GetPage(
      name: AppRoutes.doctorResultsToReview,
      page: () => const ResultsToReviewScreen(),
      binding: ResultsToReviewBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.doctorReviewPatient,
      page: () => const ReviewPatientScreen(),
      binding: ResultsToReviewBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.doctorRequestTest,
      page: () => const RequestTestScreen(),
      binding: TestRequestBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.doctorOrderDetail,
      page: () => const OrderDetailScreen(),
      binding: ResultsToReviewBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.doctorChooseReview,
      page: () => const ChooseReviewOptionScreen(),
      binding: ResultsToReviewBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.doctorReviewMessage,
      page: () => const ReviewMessageScreen(),
      binding: ResultsToReviewBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.doctorRequestFollowUp,
      page: () => const RequestFollowUpScreen(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),

    // ─── Pharmacy owner ────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.shopHome,
      page: () => const ShopShellScreen(),
      binding: ShopShellBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.shopOrderDetails,
      page: () => const ShopOrderDetailsScreen(),
      binding: ShopOrdersBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.shopNotifications,
      page: () => const ShopNotificationsScreen(),
      binding: ShopNotificationsBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.shopMedicineForm,
      page: () => const MedicineFormScreen(),
      binding: ShopMedicinesBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.shopEditProfile,
      page: () => const ShopEditProfileScreen(),
      binding: ShopProfileBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),

    // ─── Rider ─────────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.riderGuide,
      page: () => const RiderGuideScreen(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.riderApply,
      page: () => const RiderApplicationScreen(),
      binding: RiderApplicationBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.riderReady,
      page: AuthStatusScreen.riderReady,
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.riderHome,
      page: () => const RiderShellScreen(),
      binding: RiderShellBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.riderTracking,
      page: () => const RiderTrackingScreen(),
      binding: RiderOrdersBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.riderDelivered,
      page: () => const RiderDeliveredScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.riderEditProfile,
      page: () => const RiderEditProfileScreen(),
      binding: RiderProfileBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),

    // ─── Medical vault ─────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.healthProfile,
      page: () => const HealthProfileScreen(),
      binding: DocumentsBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.allPrescriptions,
      page: () => const AllPrescriptionsScreen(),
      binding: DocumentsBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.allTestReports,
      page: () => const AllTestReportsScreen(),
      binding: DocumentsBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.prescriptionDetails,
      page: () => const PrescriptionDetailsScreen(),
      binding: DocumentsBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    // Reuses the Appointments controller and its card, so it binds the
    // appointments tab's dependencies rather than owning any of its own.
    GetPage(
      name: AppRoutes.pastAppointments,
      page: () => const PastAppointmentsScreen(),
      binding: PastAppointmentsBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.testResults,
      page: () => const TestResultsScreen(),
      binding: TestResultsBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.testOrder,
      page: () => const TestOrderScreen(),
      binding: TestResultsBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.testingCentres,
      page: () => const TestingCentresScreen(),
      binding: TestResultsBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.uploadTestReport,
      page: () => const UploadReportScreen(),
      binding: TestResultsBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
    GetPage(
      name: AppRoutes.resultsSubmitted,
      page: () => const ResultsSubmittedScreen(),
      binding: TestResultsBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.reportReview,
      page: () => const ReportReviewScreen(),
      binding: TestResultsBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
  ];
}
