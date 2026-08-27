import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_radius.dart';
import '../../../../../../core/theme/app_sizes.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/responsive.dart';
import '../../../../../../core/widgets/app_button.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../../../../core/widgets/app_top_bar.dart';
import '../../domain/entities/medical_record.dart';
import '../controllers/test_results_controller.dart';

/// The signed order sheet the doctor issued.
///
/// The footer changes once a testing centre has been chosen: before, it offers
/// to pick one; after, it confirms the choice and offers to mark the test
/// done. Two designs, one screen.
class TestOrderScreen extends GetView<TestResultsController> {
  const TestOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.laboratoryResults.tr),
      child: Obx(() {
        final document = controller.orderDocument.value;
        if (document == null) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSpacing.gapV(AppSpacing.base),
            _Sheet(document: document),
            AppSpacing.gapV(AppSpacing.base),
            AppButton(
              label: AppStrings.downloadPdf.tr,
              variant: AppButtonVariant.outlined,
              onPressed: controller.downloadDocument,
            ),
            AppSpacing.gapV(AppSpacing.sm),
            // Three footers, not two. A patient who has not answered yet is
            // asked to; one who has agreed picks a centre; one who has a centre
            // marks the test done. Declining had no control at all before —
            // `POST /lab-orders/:id/respond` has always accepted a refusal and
            // no screen ever offered one, so an unwanted test sat in
            // `requested` for ever.
            if (!controller.hasFacility) ...[
              if (controller.canRespond)
                _RespondFooter(controller: controller)
              else
                AppButton(
                  label: AppStrings.chooseTestingLocation.tr,
                  icon: Icon(
                    Icons.check_circle_outline_rounded,
                    size: AppSizes.buttonIcon.w,
                    color: AppColors.actionLabel,
                  ),
                  onPressed: controller.openTestingCentres,
                ),
            ] else ...[
              _SelectedCentre(name: controller.facilityName),
              AppSpacing.gapV(AppSpacing.base),
              AppButton(
                label: AppStrings.completedMyTest.tr,
                onPressed: controller.completedTest,
              ),
            ],
            AppSpacing.gapV(AppSpacing.md),
          ],
        );
      }),
    );
  }
}

/// Accept or decline a test the doctor raised.
class _RespondFooter extends StatelessWidget {
  const _RespondFooter({required this.controller});

  final TestResultsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppButton(
            label: AppStrings.acceptAndChooseCentre.tr,
            isLoading: controller.isResponding.value,
            onPressed: () => controller.respond(accept: true),
          ),
          AppSpacing.gapV(AppSpacing.sm),
          AppButton(
            label: AppStrings.declineTest.tr,
            variant: AppButtonVariant.outlined,
            onPressed: controller.isResponding.value
                ? null
                : () => controller.respond(accept: false),
          ),
        ],
      ),
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.document});

  final TestOrderDocument document;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.rXl,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(
            color: AppColors.surfaceBorder,
            width: AppSizes.borderWidth,
          ),
          borderRadius: AppRadius.rXl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Masthead(document: document),
            _PriorityBand(
              label: document.priorityLabel,
              reference: document.reference,
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.base.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionLabel(AppStrings.orderInformation.tr),
                  _Field(
                    label: AppStrings.orderDate.tr,
                    value: document.orderedOn,
                    isIdentifier: true,
                  ),
                  if (document.facility != null)
                    _Field(
                      label: AppStrings.testingCentreLabel.tr,
                      value: document.facility!,
                    ),
                  AppSpacing.gapV(AppSpacing.base),
                  _SectionLabel(AppStrings.patientInformation.tr),
                  _Field(
                    label: AppStrings.patientNameLabel.tr,
                    value: document.patientName,
                  ),
                  // Omitted rather than invented when the account has no date
                  // of birth. Insurance, member id and medical record number
                  // used to sit here too, all three from a fixture describing
                  // somebody else.
                  if (document.dateOfBirth != null)
                    _Field(
                      label: AppStrings.dateOfBirth.tr,
                      value: document.dateOfBirth!,
                    ),
                  if (document.isImaging) ...[
                    AppSpacing.gapV(AppSpacing.base),
                    _SectionLabel(AppStrings.studyOrdered.tr),
                    _Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (document.modality != null)
                            _Field(
                              label: AppStrings.modality.tr,
                              value: document.modality!,
                            ),
                          if (document.bodyRegion != null)
                            _Field(
                              label: AppStrings.bodyRegion.tr,
                              value: document.bodyRegion!,
                            ),
                        ],
                      ),
                    ),
                  ],
                  AppSpacing.gapV(AppSpacing.base),
                  _SectionLabel(AppStrings.clinicalIndication.tr),
                  _Panel(
                    child: Text(
                      document.clinicalIndication,
                      style: AppTextStyles.bodyLarge.rc(AppColors.gray900),
                    ),
                  ),
                  AppSpacing.gapV(AppSpacing.base),
                  Container(
                    height: AppSizes.borderWidth,
                    color: AppColors.surfaceBorder,
                  ),
                  AppSpacing.gapV(AppSpacing.base),
                  _SectionLabel(AppStrings.orderingPhysician.tr),
                  Text(
                    document.physicianName,
                    style: AppTextStyles.titleSmall.rc(AppColors.gray900),
                  ),
                  if (document.physicianSpecialty != null)
                    Text(
                      document.physicianSpecialty!,
                      style: AppTextStyles.bodyLarge.rc(AppColors.gray500),
                    ),
                  // NPI and DEA are US federal registrations. They were printed
                  // here from a fixture, on a platform that does not operate in
                  // that jurisdiction and holds neither number for anyone.
                  if (document.licence != null) ...[
                    AppSpacing.gapV(AppSpacing.xs),
                    _MonoLine('${AppStrings.licenceLabel.tr}: ${document.licence}'),
                  ],
                  AppSpacing.gapV(AppSpacing.sm),
                  _SignatureBlock(document: document),
                  AppSpacing.gapV(AppSpacing.base),
                  Container(
                    height: AppSizes.borderWidth,
                    color: AppColors.surfaceBorder,
                  ),
                  AppSpacing.gapV(AppSpacing.xs),
                  Text(
                    AppStrings.confidentialNote.tr,
                    style: AppTextStyles.bodySmall.rc(AppColors.gray400),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Masthead extends StatelessWidget {
  const _Masthead({required this.document});

  final TestOrderDocument document;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.authInk,
      padding: EdgeInsets.all(AppSpacing.base.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  // The ordering doctor heads the sheet. There is no practice
                  // entity behind a Bienify order — the previous masthead
                  // printed a clinic name, street address and fax number from
                  // a fixture, none of which existed.
                  document.physicianName,
                  style: AppTextStyles.titleLarge.rc(AppColors.white),
                ),
              ),
              AppSpacing.gapH(AppSpacing.xs),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs.w,
                  vertical: AppSpacing.xs2.h,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.16),
                  borderRadius: AppRadius.rSm,
                ),
                constraints: BoxConstraints(maxWidth: 96.w),
                child: Text(
                  document.kindLabel,
                  style: AppTextStyles.labelSmall.rc(AppColors.white),
                ),
              ),
            ],
          ),
          if (document.physicianSpecialty != null) ...[
            AppSpacing.gapV(AppSpacing.xs2),
            Text(
              document.physicianSpecialty!,
              style: AppTextStyles.bodyMedium.rc(
                AppColors.white.withValues(alpha: 0.86),
              ),
            ),
          ],
          if (document.facility != null) ...[
            AppSpacing.gapV(AppSpacing.xxs),
            Text(
              document.facility!,
              style: AppTextStyles.bodyMedium.rc(
                AppColors.white.withValues(alpha: 0.56),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PriorityBand extends StatelessWidget {
  const _PriorityBand({required this.label, required this.reference});

  final String label;
  final String reference;

  static const double _dot = 8;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.tagPendingSurface,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.base.w,
        vertical: AppSpacing.xs.h,
      ),
      child: Row(
        children: [
          Container(
            width: _dot.w,
            height: _dot.w,
            decoration: const BoxDecoration(
              color: AppColors.tagWarningInk,
              shape: BoxShape.circle,
            ),
          ),
          AppSpacing.gapH(AppSpacing.xs2),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleSmall.rc(AppColors.tagWarningInk),
            ),
          ),
          AppSpacing.gapH(AppSpacing.xs),
          Text(reference, style: _identifierStyle(AppColors.gray600)),
        ],
      ),
    );
  }
}

/// Style for the document's identifiers — reference numbers, NPI, licence.
///
/// The design sets these in a monospaced face. It is drawn in Satoshi with
/// tabular figures and extra letter spacing instead, because naming a
/// `fontFamily: 'monospace'` relies on a family the app does not bundle:
/// Android resolves it, Apple platforms do not, and the widget tests resolve
/// it to empty boxes. Tabular figures give the same column alignment and
/// character-by-character legibility that the monospace was there for.
TextStyle _identifierStyle(Color color) => AppTextStyles.bodySmall
    .rc(color)
    .copyWith(
      letterSpacing: 0.4,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.xs.h),
      child: Text(
        label,
        style: AppTextStyles.labelSmall
            .rc(AppColors.gray400)
            .copyWith(letterSpacing: 0.6),
      ),
    );
  }
}

/// `Label            value` — the label on the left in grey, the value right
/// in ink. Two thirds / one third, which keeps every value column aligned.
class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.value,
    this.isIdentifier = false,
  });

  final String label;
  final String value;

  /// Reference numbers get the tabular treatment; prose does not.
  final bool isIdentifier;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.xs2.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96.w,
            child: Text(
              label,
              style: AppTextStyles.bodyLarge.rc(AppColors.gray500),
            ),
          ),
          AppSpacing.gapH(AppSpacing.xs),
          Expanded(
            child: Text(
              value,
              style: isIdentifier
                  ? _identifierStyle(AppColors.gray900)
                  : AppTextStyles.titleSmall.rc(AppColors.gray900),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonoLine extends StatelessWidget {
  const _MonoLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: _identifierStyle(AppColors.gray600));
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.sm.w),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: AppRadius.rLg,
      ),
      child: child,
    );
  }
}

/// The green attestation box, with the physician's name set as a signature.
class _SignatureBlock extends StatelessWidget {
  const _SignatureBlock({required this.document});

  final TestOrderDocument document;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.sm.w),
      decoration: BoxDecoration(
        color: AppColors.tagSuccessSurface,
        borderRadius: AppRadius.rLg,
      ),
      child: Column(
        children: [
          // The physician's surname used to be drawn here in italic script, on
          // a signature line, above the words "Electronically Signed" — a
          // rendered font standing in for a signature nobody gave. Bienify
          // holds no signature for any practitioner and does not capture one,
          // so the line is gone. What the platform can attest to is who raised
          // the order and when, which is what remains below.
          Container(
            height: AppSizes.borderWidth,
            color: AppColors.tagSuccessInk.withValues(alpha: 0.3),
          ),
          AppSpacing.gapV(AppSpacing.xs2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_box_rounded,
                size: AppSizes.lg.w,
                color: AppColors.tagSuccessInk,
              ),
              AppSpacing.gapH(AppSpacing.xs2),
              Text(
                AppStrings.electronicallySigned.tr,
                style: AppTextStyles.titleSmall.rc(AppColors.tagSuccessInk),
              ),
            ],
          ),
          Text(
            document.orderedOn,
            style: _identifierStyle(AppColors.tagSuccessInk),
          ),
          // "SHA-256 verified" used to sit here. Nothing hashes a lab order,
          // signs one, or could verify either — it was a cryptographic
          // assurance printed on a medical document that no code backed. What
          // is true is that a verified practitioner raised it, so that is what
          // it says now.
          Text(
            AppStrings.raisedByVerifiedPractitioner.tr,
            style: _identifierStyle(AppColors.tagSuccessInk),
          ),
        ],
      ),
    );
  }
}

/// Confirmation that a centre has been picked, and what to do next.
class _SelectedCentre extends StatelessWidget {
  const _SelectedCentre({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hasShadow: false,
      color: AppColors.tagInfoSurface,
      borderColor: AppColors.transparent,
      padding: EdgeInsets.all(AppSpacing.sm.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: AppSizes.xl.w,
                color: AppColors.gray900,
              ),
              AppSpacing.gapH(AppSpacing.xs2),
              Expanded(
                child: Text(
                  AppStrings.preferredHospitalSelected.tr,
                  style: AppTextStyles.bodyLarge.rc(AppColors.gray900),
                ),
              ),
            ],
          ),
          AppSpacing.gapV(AppSpacing.xs2),
          Text(name, style: AppTextStyles.titleSmall.rc(AppColors.link)),
          Text(
            AppStrings.bookInExternalApp.tr,
            style: AppTextStyles.bodyLarge.rc(AppColors.link),
          ),
        ],
      ),
    );
  }
}
