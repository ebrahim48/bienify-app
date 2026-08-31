import 'package:get/get.dart';

import '../../../../../../core/base/base_controller.dart';
import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../../core/widgets/app_snackbar.dart';
import '../../domain/repositories/pharmacy_repository.dart';

/// Backs the Feedback screen shown once a courier marks an order delivered.
///
/// It exists for one reason: the screen had no controller and no arguments, so
/// the stars it collected had nowhere to go and were dropped on the floor. A
/// rider review is keyed by the **delivery** — `review.service.ts:55` resolves
/// the courier from it — so the tracking screen hands that id over on the way
/// here.
class DeliveryFeedbackController extends GetxController with SubmissionMixin {
  DeliveryFeedbackController({this.deliveryId, PharmacyRepository? repository})
    : _repository = repository ?? Get.find<PharmacyRepository>();

  /// The delivery being rated, or null when the screen was reached without
  /// one — an order that was never dispatched has no courier to rate.
  final String? deliveryId;

  final PharmacyRepository _repository;

  bool get canReview => deliveryId != null;

  /// Files the rating and reports whether it landed.
  Future<bool> submitRiderReview(int rating) async {
    final id = deliveryId;
    if (id == null) return false;

    try {
      await _repository.reviewRider(deliveryId: id, rating: rating);
    } on AppException catch (e) {
      // A repeat review, or a delivery the server does not consider finished.
      AppSnackbar.error(e.message);
      return false;
    }
    AppSnackbar.success(AppStrings.reviewSubmitted.tr);
    return true;
  }
}
