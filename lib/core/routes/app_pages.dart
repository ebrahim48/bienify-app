import 'package:get/get.dart';

import '../../features/appointments/presentation/bindings/appointments_bindings.dart';
import '../../features/appointments/presentation/screens/consultation_history_screen.dart';
import '../../features/appointments/presentation/screens/video_call_screen.dart';
import '../../features/auth/presentation/bindings/auth_bindings.dart';
import '../../features/auth/presentation/controllers/auth_flow.dart';
import '../../features/auth/presentation/screens/auth_status_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/new_password_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/phone_number_screen.dart';
import '../../features/auth/presentation/screens/profile_credentials_screen.dart';
import '../../features/auth/presentation/screens/profile_setup_screen.dart';
import '../../features/booking/presentation/screens/payment_summary_screen.dart';
import '../../features/cash_payment_process/presentation/bindings/cash_payment_bindings.dart';
import '../../features/cash_payment_process/presentation/screens/how_to_pay_screen.dart';
import '../../features/cash_payment_process/presentation/screens/nearby_payment_points_screen.dart';
import '../../features/cash_payment_process/presentation/screens/payment_confirmed_screen.dart';
import '../../features/cash_payment_process/presentation/screens/payment_pending_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/doctors/presentation/bindings/doctors_bindings.dart';
import '../../features/doctors/presentation/screens/doctor_details_screen.dart';
import '../../features/doctors/presentation/screens/doctor_list_screen.dart';
import '../../features/doctors/presentation/screens/doctor_search_screen.dart';
import '../../features/main/presentation/bindings/main_binding.dart';
import '../../features/main/presentation/screens/main_shell_screen.dart';
import '../../features/pharmacy/presentation/bindings/pharmacy_bindings.dart';
import '../../features/pharmacy/presentation/screens/best_matches_screen.dart';
import '../../features/pharmacy/presentation/screens/delivery_feedback_screen.dart';
import '../../features/pharmacy/presentation/screens/live_tracking_screen.dart';
import '../../features/pharmacy/presentation/screens/order_status_screen.dart';
import '../../features/pharmacy/presentation/screens/pharmacy_cart_screen.dart';
import '../../features/pharmacy/presentation/screens/pharmacy_payment_screen.dart';
import '../../features/pharmacy/presentation/screens/select_medicines_screen.dart';
import '../../features/pharmacy/presentation/screens/upload_prescription_screen.dart';
import '../../features/onboarding/presentation/screens/location_permission_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
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

    // ─── Messaging ─────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.chat,
      page: () => const ChatScreen(),
      binding: ChatBinding(),
      transition: _transition,
      transitionDuration: _transitionDuration,
    ),
  ];
}
