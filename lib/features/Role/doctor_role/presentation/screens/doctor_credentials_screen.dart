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
import '../../../../../core/widgets/app_top_bar.dart';
import '../../domain/entities/doctor_practice.dart';
import '../controllers/doctor_credentials_controller.dart';

/// The practitioner's licences and certificates, and their verification state.
///
/// `POST /doctors/me/credentials` has existed since the doctor module was
/// written and nothing in the app called it — there was no screen at all — so
/// a doctor could not submit a licence, and the admin approval queue had
/// nothing to look at but a licence *number* typed on a form.
class DoctorCredentialsScreen extends GetView<DoctorCredentialsController> {
  const DoctorCredentialsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.credentials.tr),
      child: Obx(() {
        final credentials = controller.credentials;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSpacing.gapV(AppSpacing.base),
            _StatusBanner(
              status: controller.verificationStatus.value,
              note: controller.verificationNote.value,
            ),
            AppSpacing.gapV(AppSpacing.base),
            Text(
              AppStrings.submittedDocuments.tr,
              style: AppTextStyles.titleSmall.rc(AppColors.gray900),
            ),
            AppSpacing.gapV(AppSpacing.xs),
            if (credentials.isEmpty)
              Text(
                AppStrings.noCredentialsYet.tr,
                style: AppTextStyles.bodyLarge.rc(AppColors.gray400),
              )
            else
              for (final credential in credentials) ...[
                _CredentialRow(credential: credential),
                AppSpacing.gapV(AppSpacing.xs2),
              ],
            AppSpacing.gapV(AppSpacing.base),
            Text(
              AppStrings.addCredentialHint.tr,
              style: AppTextStyles.bodyMedium.rc(AppColors.gray500),
            ),
            AppSpacing.gapV(AppSpacing.sm),
            _KindPicker(controller: controller),
            AppSpacing.gapV(AppSpacing.base),
            AppButton(
              label: AppStrings.addCredential.tr,
              isLoading: controller.isUploading.value,
              onPressed: () => controller.addCredential(context),
            ),
            AppSpacing.gapV(AppSpacing.md),
          ],
        );
      }),
    );
  }
}

/// Where the profile stands with the admin reviewing it.
class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status, required this.note});

  final String status;
  final String note;

  @override
  Widget build(BuildContext context) {
    final approved = status == 'approved';
    final rejected = status == 'rejected';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.base.w),
      decoration: BoxDecoration(
        color: approved
            ? AppColors.tagSuccessSurface
            : rejected
            ? AppColors.error50
            : AppColors.tagPendingSurface,
        borderRadius: AppRadius.rLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            approved
                ? AppStrings.verificationApproved.tr
                : rejected
                ? AppStrings.verificationRejected.tr
                : AppStrings.verificationPending.tr,
            style: AppTextStyles.titleSmall.rc(
              approved
                  ? AppColors.tagSuccessInk
                  : rejected
                  ? AppColors.error700
                  : AppColors.tagPendingInk,
            ),
          ),
          // Only on a rejection. A note is written when a profile is pushed
          // back — "Reset to pending: details were changed" — and an approval
          // that clears the status without clearing the note left it showing
          // under "Your profile is verified", which reads as a contradiction.
          // Approved or pending, the status line says everything the doctor
          // can act on.
          if (rejected && note.isNotEmpty) ...[
            AppSpacing.gapV(AppSpacing.xs2),
            Text(
              note,
              style: AppTextStyles.bodyMedium.rc(AppColors.gray600),
            ),
          ],
        ],
      ),
    );
  }
}

class _CredentialRow extends StatelessWidget {
  const _CredentialRow({required this.credential});

  final PractitionerCredential credential;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hasShadow: false,
      padding: EdgeInsets.all(AppSpacing.sm.w),
      child: Row(
        children: [
          Icon(
            Icons.description_outlined,
            size: AppSizes.xl2.w,
            color: AppColors.link,
          ),
          AppSpacing.gapH(AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DoctorCredentialsController.kindLabel(credential.kind),
                  style: AppTextStyles.titleSmall.rc(AppColors.gray900),
                ),
                Text(
                  DoctorCredentialsController.uploadedLabel(
                    credential.uploadedAt,
                  ),
                  style: AppTextStyles.bodySmall.rc(AppColors.gray400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// What the next document is being filed as.
class _KindPicker extends StatelessWidget {
  const _KindPicker({required this.controller});

  final DoctorCredentialsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Wrap(
        spacing: AppSpacing.xs.w,
        runSpacing: AppSpacing.xs.h,
        children: [
          for (final kind in DoctorCredentialsController.kinds)
            GestureDetector(
              onTap: () => controller.selectKind(kind),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm.w,
                  vertical: AppSpacing.xs.h,
                ),
                decoration: BoxDecoration(
                  color: controller.kind.value == kind
                      ? AppColors.actionFill
                      : AppColors.surface,
                  border: Border.all(color: AppColors.surfaceBorder),
                  borderRadius: AppRadius.rFull,
                ),
                child: Text(
                  DoctorCredentialsController.kindLabel(kind),
                  style: AppTextStyles.bodyMedium.rc(
                    controller.kind.value == kind
                        ? AppColors.actionLabel
                        : AppColors.gray900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
