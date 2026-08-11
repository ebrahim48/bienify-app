import '../../constants/api_constants.dart';
import '../api_client.dart';

/// Every `reviews` endpoint the backend serves.
///
/// One method per route, generated against the backend route table so the
/// app cannot drift onto a path the server does not answer.
class ReviewsApi {
  ReviewsApi(this._c);

  final ApiClient _c;

  /// `POST /api/v1/reviews`
  Future<dynamic> createReviews({Object? body}) =>
      _c.post(ApiConstants.postReviews, body: body);

  /// `GET /api/v1/reviews/doctors/:id`
  Future<dynamic> getDoctors({
    required String id,
    Map<String, dynamic>? query,
  }) => _c.get(ApiConstants.reviewsDoctors(id), query: query);

  /// `GET /api/v1/reviews/me`
  Future<dynamic> getMe({Map<String, dynamic>? query}) =>
      _c.get(ApiConstants.reviewsMe, query: query);

  /// `GET /api/v1/reviews/pharmacies/:id`
  Future<dynamic> getPharmacies({
    required String id,
    Map<String, dynamic>? query,
  }) => _c.get(ApiConstants.reviewsPharmacies(id), query: query);

  /// `GET /api/v1/reviews/riders/:id`
  Future<dynamic> getRiders({
    required String id,
    Map<String, dynamic>? query,
  }) => _c.get(ApiConstants.reviewsRiders(id), query: query);
}
