import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_sizes.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../../domain/entities/test_request.dart';
import '../controllers/results_to_review_controller.dart';
import '../widgets/order_tracker.dart';
import '../widgets/patient_row_card.dart';

/// One order, from what was asked for to what came back.
///
/// The two designs are the same screen at two points in its life: before the
/// patient has been anywhere it says so, and once results are in it shows the
/// hospital, the notes, the report and the button that starts a review.
class OrderDetailScreen extends GetView<ResultsToReviewController> {
  const OrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      // The masthead runs edge to edge, so the page owns its own gutters.
      padded: false,
      child: Obx(() {
        final request = controller.request.value;
        if (request == null) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Masthead(request: request),
            Padding(
              padding: AppSpacing.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppSpacing.gapV(AppSpacing.base),
                  _PatientCard(request: request),
                  AppSpacing.gapV(AppSpacing.sm),
                  AppCard(
                    hasShadow: false,
                    borderColor: AppColors.transparent,
                    padding: EdgeInsets.all(AppSpacing.base.w),
                    child: OrderTracker(stage: request.stage),
                  ),
                  AppSpacing.gapV(AppSpacing.base),
                  if (request.hasResults)
                    ..._results(request)
                  else
                    const _AwaitingUpload(),
                  AppSpacing.gapV(AppSpacing.md),
                  if (request.hasResults)
                    AppButton(
                      label: AppStrings.chooseYourReview.tr,
                      radius: AppRadius.xl,
                      onPressed: controller.chooseReview,
                    ),
                  AppSpacing.gapV(AppSpacing.md),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  List<Widget> _results(TestRequest request) => [
    if (request.hospitalName != null) ...[
      _HospitalPanel(
        name: request.hospitalName!,
        address: request.hospitalAddress ?? '',
      ),
      AppSpacing.gapV(AppSpacing.base),
    ],
    if (request.clinicalNotes != null) ...[
      _NotesCard(notes: request.clinicalNotes!),
      AppSpacing.gapV(AppSpacing.base),
    ],
    if (request.hasResults)
      _Documents(
        asset: request.documentAsset,
        url: request.documentUrl,
      ),
  ];
}

/// The navy band: chevron, order title and the subtest under it.
class _Masthead extends StatelessWidget {
  const _Masthead({required this.request});

  final TestRequest request;

  static const double _height = 68;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _height.h,
      color: AppColors.actionFill,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm.w),
      child: Row(
        children: [
          InkResponse(
            onTap: () => Get.back<void>(),
            radius: AppSizes.xl2.r,
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xs.w),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: AppSizes.xl.w,
                color: AppColors.white,
              ),
            ),
          ),
          AppSpacing.gapH(AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  request.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleLarge.rc(AppColors.white),
                ),
                Text(
                  request.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge.rc(AppColors.primary200),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Who it is for, when it was ordered, and how urgently.
class _PatientCard extends StatelessWidget {
  const _PatientCard({required this.request});

  final TestRequest request;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hasShadow: false,
      borderColor: AppColors.transparent,
      padding: EdgeInsets.all(AppSpacing.sm.w),
      child: Row(
        children: [
          PatientPhoto(
            asset: request.patient.photoAsset,
            url: request.patient.photoUrl,
          ),
          AppSpacing.gapH(AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  request.patient.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium.rw(
                    AppColors.gray900,
                    FontWeight.w400,
                  ),
                ),
                AppSpacing.gapV(AppSpacing.xs2),
                Text(
                  '${AppStrings.ordered.tr} ${request.orderedOnLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge.rc(AppColors.gray600),
                ),
              ],
            ),
          ),
          AppSpacing.gapH(AppSpacing.xs),
          if (request.priority != OrderPriority.routine)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm.w,
                vertical: AppSpacing.xs2.h + 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.urgentSurface,
                borderRadius: AppRadius.rLg,
              ),
              child: Text(
                request.priority == OrderPriority.urgent
                    ? AppStrings.priorityUrgent.tr
                    : AppStrings.priorityStat.tr,
                style: AppTextStyles.bodyLarge.rc(AppColors.urgentInk),
              ),
            ),
        ],
      ),
    );
  }
}

/// Where the patient chose to be tested.
class _HospitalPanel extends StatelessWidget {
  const _HospitalPanel({required this.name, required this.address});

  final String name;
  final String address;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.base.w),
      decoration: BoxDecoration(
        color: AppColors.authPanelSoft,
        borderRadius: AppRadius.rXl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppStrings.patientsPreferredHospital.tr,
            style: AppTextStyles.bodyLarge.rc(AppColors.gray600),
          ),
          AppSpacing.gapV(AppSpacing.xs2),
          Text(name, style: AppTextStyles.titleLarge.rc(AppColors.actionFill)),
          AppSpacing.gapV(AppSpacing.xs2),
          Text(address, style: AppTextStyles.bodyLarge.rc(AppColors.link)),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hasShadow: false,
      borderColor: AppColors.transparent,
      padding: EdgeInsets.all(AppSpacing.base.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppStrings.clinicalNotes.tr,
            style: AppTextStyles.bodyLarge.rc(AppColors.gray600),
          ),
          AppSpacing.gapV(AppSpacing.xs2),
          Text(
            notes,
            style: AppTextStyles.titleMedium.rw(
              AppColors.gray900,
              FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

/// The report the patient uploaded: image over its caption.
/// The uploaded report.
///
/// Takes either a bundled asset (the sample data) or a signed URL (a real
/// order), and neither is required: an order can be known to have a report
/// before its link has been signed, and a tile that names the report is
/// honest where a broken image is not.
class _Documents extends StatelessWidget {
  const _Documents({this.asset, this.url});

  final String? asset;
  final String? url;

  static const double _width = 154;
  static const double _imageHeight = 116;

  /// The bundled asset, the signed link, or — when neither has arrived — a
  /// plain document glyph rather than a broken image.
  Widget _preview() {
    final bundled = asset;
    if (bundled != null) return Image.asset(bundled, fit: BoxFit.cover);
    final link = url;
    if (link != null) {
      return Image.network(
        link,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => ColoredBox(
    color: AppColors.cardFieldFill,
    child: Center(
      child: Icon(
        Icons.description_outlined,
        size: AppSizes.xl2.w,
        color: AppColors.gray600,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              Icons.image_outlined,
              size: AppSizes.xl.w,
              color: AppColors.gray900,
            ),
            AppSpacing.gapH(AppSpacing.xs),
            Text(
              AppStrings.uploadedDocuments.tr,
              style: AppTextStyles.titleMedium.rw(
                AppColors.gray900,
                FontWeight.w400,
              ),
            ),
          ],
        ),
        AppSpacing.gapV(AppSpacing.xs),
        SizedBox(
          width: _width.w,
          child: AppCard(
            hasShadow: false,
            borderColor: AppColors.transparent,
            padding: EdgeInsets.zero,
            radius: AppRadius.lg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: _imageHeight.h,
                  child: _preview(),
                ),
                Padding(
                  padding: EdgeInsets.all(AppSpacing.xs.w),
                  child: Text(
                    AppStrings.laboratoryReport.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyLarge.rc(AppColors.gray600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Nothing has come back yet.
class _AwaitingUpload extends StatelessWidget {
  const _AwaitingUpload();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.base.w),
      decoration: BoxDecoration(
        borderRadius: AppRadius.rXl,
        border: Border.all(
          color: AppColors.gray100,
          width: AppSizes.borderWidth,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppStrings.awaitingPatientUpload.tr,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleLarge.rw(
              AppColors.gray900,
              FontWeight.w400,
            ),
          ),
          AppSpacing.gapV(AppSpacing.xs),
          Text(
            AppStrings.awaitingPatientUploadBody.tr,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.rc(AppColors.gray600),
          ),
        ],
      ),
    );
  }
}
