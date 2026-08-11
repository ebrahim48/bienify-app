import '../../constants/api_constants.dart';
import '../api_client.dart';

/// Every `admin` endpoint the backend serves.
///
/// One method per route, generated against the backend route table so the
/// app cannot drift onto a path the server does not answer.
class AdminApi {
  AdminApi(this._c);

  final ApiClient _c;

  /// `GET /api/v1/admin/appointments`
  Future<dynamic> getAppointments({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.adminAppointments, query: query);

  /// `GET /api/v1/admin/dashboard/approval-queues`
  Future<dynamic> getDashboardapprovalqueues({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.adminDashboardApprovalQueues, query: query);

  /// `PATCH /api/v1/admin/dashboard/pharmacies/:id/verification`
  Future<dynamic> updateDashboardpharmaciesverification({
    required String id,
    Object? body,
  }) => _c.patch(
    ApiConstants.updateAdminDashboardPharmaciesVerification(id),
    body: body,
  );

  /// `GET /api/v1/admin/dashboard/pharmacies/pending`
  Future<dynamic> getDashboardpharmaciespending({
    Map<String, dynamic>? query,
  }) => _c.get(ApiConstants.adminDashboardPharmaciesPending, query: query);

  /// `GET /api/v1/admin/dashboard/riders/pending`
  Future<dynamic> getDashboardriderspending({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.adminDashboardRidersPending, query: query);

  /// `GET /api/v1/admin/dashboard/stats`
  Future<dynamic> getDashboardstats({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.adminDashboardStats, query: query);

  /// `PATCH /api/v1/admin/doctors/:id/verification`
  Future<dynamic> updateDoctorsverification({
    required String id,
    Object? body,
  }) => _c.patch(ApiConstants.updateAdminDoctorsVerification(id), body: body);

  /// `GET /api/v1/admin/doctors/pending`
  Future<dynamic> getDoctorspending({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.adminDoctorsPending, query: query);

  /// `GET /api/v1/admin/lab-orders`
  Future<dynamic> getLaborders({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.adminLabOrders, query: query);

  /// `GET /api/v1/admin/orders`
  Future<dynamic> getOrders({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.adminOrders, query: query);

  /// `GET /api/v1/admin/partner-applications`
  Future<dynamic> getPartnerapplications({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.adminPartnerApplications, query: query);

  /// `PATCH /api/v1/admin/partner-applications/:id`
  Future<dynamic> updatePartnerapplications({
    required String id,
    Object? body,
  }) => _c.patch(ApiConstants.updateAdminPartnerApplications(id), body: body);

  /// `GET /api/v1/admin/prescriptions`
  Future<dynamic> getPrescriptions({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.adminPrescriptions, query: query);

  /// `GET /api/v1/admin/reports/:kind`
  Future<dynamic> getReports({
    required String kind,
    Map<String, dynamic>? query,
  }) => _c.get(ApiConstants.adminReportsKind(kind), query: query);

  /// `PATCH /api/v1/admin/riders/:id/verification`
  Future<dynamic> updateRidersverification({
    required String id,
    Object? body,
  }) => _c.patch(ApiConstants.updateAdminRidersVerification(id), body: body);

  /// `GET /api/v1/admin/settings`
  Future<dynamic> getSettings({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.adminSettings, query: query);

  /// `PUT /api/v1/admin/settings`
  Future<dynamic> replaceSettings({Object? body}) =>
      _c.put(ApiConstants.putAdminSettings, body: body);

  /// `GET /api/v1/admin/tests`
  Future<dynamic> getTests({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.adminTests, query: query);

  /// `POST /api/v1/admin/tests`
  Future<dynamic> createTests({Object? body}) =>
      _c.post(ApiConstants.postAdminTests, body: body);

  /// `DELETE /api/v1/admin/tests/:id`
  Future<dynamic> removeTests({required String id, Object? body}) =>
      _c.delete(ApiConstants.deleteAdminTests(id), body: body);

  /// `PATCH /api/v1/admin/tests/:id`
  Future<dynamic> updateTests({required String id, Object? body}) =>
      _c.patch(ApiConstants.updateAdminTests(id), body: body);

  /// `GET /api/v1/admin/transactions`
  Future<dynamic> getTransactions({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.adminTransactions, query: query);

  /// `GET /api/v1/admin/users`
  Future<dynamic> getUsers({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.adminUsers, query: query);

  /// `PATCH /api/v1/admin/users/:id/status`
  Future<dynamic> updateUsersstatus({required String id, Object? body}) =>
      _c.patch(ApiConstants.updateAdminUsersStatus(id), body: body);

  /// `GET /api/v1/admin/withdrawals`
  Future<dynamic> getWithdrawals({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.adminWithdrawals, query: query);

  /// `PATCH /api/v1/admin/withdrawals/:id`
  Future<dynamic> updateWithdrawals({required String id, Object? body}) =>
      _c.patch(ApiConstants.updateAdminWithdrawals(id), body: body);
}
