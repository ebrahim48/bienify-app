import '../../features/Role/patient/auth/domain/entities/user_role.dart';
import 'app_routes.dart';

/// Where a signed-in account lands.
///
/// Each role has its own shell, and sign-in used to send every account to the
/// patient one — so a practitioner, a shop owner or a courier could only reach
/// their own section through the links that sign people up for it, and a
/// courier who was already signed up could not reach it at all.
String homeForRole(UserRole role) => switch (role) {
  UserRole.doctor => AppRoutes.doctorHome,
  UserRole.pharmacyOwner => AppRoutes.shopHome,
  UserRole.rider => AppRoutes.riderHome,
  // Admin has no app section of its own — the operator tools are the web
  // dashboard — so an admin signing in gets the patient app, as before.
  UserRole.patient || UserRole.admin => AppRoutes.home,
};
