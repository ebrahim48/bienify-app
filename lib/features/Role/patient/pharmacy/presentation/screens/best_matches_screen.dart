import '../../../medical_vault/domain/entities/medical_record.dart';
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
import '../../domain/entities/pharmacy.dart';
import '../controllers/prescription_controller.dart';

/// Pharmacies that can fill the uploaded prescription, ranked by how much of
/// it they stock.
class BestMatchesScreen extends GetView<PrescriptionController> {
  const BestMatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.bestMatches.tr),
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSpacing.gapV(AppSpacing.base),
            _PrescriptionBanner(prescription: controller.prescription.value),
            AppSpacing.gapV(AppSpacing.base),
            _SearchArea(area: controller.searchArea.value),
            AppSpacing.gapV(AppSpacing.base),
            Text(
              AppStrings.pharmaciesFound.trParams({
                'count': '${controller.matches.length}',
              }),
              style: AppTextStyles.bodyLarge.rc(AppColors.gray500),
            ),
            AppSpacing.gapV(AppSpacing.xs),
            for (final store in controller.matches) ...[
              PharmacyMatchCard(
                store: store,
                isSelected: store.id == controller.selectedStoreId.value,
                onTap: () => controller.selectStore(store),
              ),
              AppSpacing.gapV(AppSpacing.sm),
            ],
            AppSpacing.gapV(AppSpacing.xs),
            AppButton(
              label: AppStrings.customizeMyOrder.tr,
              trailingIcon: Icon(
                Icons.chevron_right_rounded,
                size: AppSizes.xl2.w,
                color: AppColors.actionLabel,
              ),
              onPressed: controller.customizeOrder,
            ),
            AppSpacing.gapV(AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _PrescriptionBanner extends StatelessWidget {
  const _PrescriptionBanner({required this.prescription});

  /// Null when the patient reached this screen by photographing a paper
  /// script: that is a vault document, not a prescription the server issued,
  /// so there is no doctor or medicine count to name.
  final DigitalPrescription? prescription;

  static const double _badge = 48;

  @override
  Widget build(BuildContext context) {
    final script = prescription;
    if (script == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(AppSpacing.base.w),
      decoration: BoxDecoration(
        color: AppColors.actionFill,
        borderRadius: AppRadius.rXl,
      ),
      child: Row(
        children: [
          Container(
            width: _badge.w,
            height: _badge.w,
            decoration: BoxDecoration(
              color: AppColors.primary600,
              borderRadius: AppRadius.rXl,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.description_outlined,
              size: AppSizes.xl2.w,
              color: AppColors.white,
            ),
          ),
          AppSpacing.gapH(AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.prescriptionOf.trParams({
                    'doctor': script.doctorName,
                  }),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSmall.rc(AppColors.white),
                ),
                AppSpacing.gapV(AppSpacing.xxs),
                Text(
                  AppStrings.medicinesIdentified.trParams({
                    'count': '${script.medications.length}',
                    'status': script.reference,
                  }),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.rc(AppColors.primary200),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchArea extends StatelessWidget {
  const _SearchArea({required this.area});

  final String area;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.location_on_outlined,
          size: AppSizes.xl.w,
          color: AppColors.primary600,
        ),
        AppSpacing.gapH(AppSpacing.xs),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${AppStrings.searchingNear.tr} ',
                  style: AppTextStyles.bodyLarge.rc(AppColors.gray500),
                ),
                TextSpan(
                  text: area,
                  style: AppTextStyles.titleSmall.rc(AppColors.authInk),
                ),
              ],
            ),
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}

/// A candidate pharmacy: logo, name, distance/rating/ETA, price, and how
/// much of the prescription it can fill.
class PharmacyMatchCard extends StatelessWidget {
  const PharmacyMatchCard({
    super.key,
    required this.store,
    required this.isSelected,
    required this.onTap,
  });

  final PharmacyStore store;
  final bool isSelected;
  final VoidCallback onTap;

  static const double _logo = 56;
  static const double _radio = 28;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      hasShadow: false,
      borderColor: isSelected ? AppColors.primary600 : AppColors.surfaceBorder,
      padding: EdgeInsets.all(AppSpacing.sm.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: _logo.w,
                height: _logo.w,
                decoration: BoxDecoration(
                  color: AppColors.chatFieldFill,
                  borderRadius: AppRadius.rXl,
                ),
                alignment: Alignment.center,
                child: Text(
                  store.initial,
                  style: AppTextStyles.titleLarge.rc(AppColors.gray900),
                ),
              ),
              AppSpacing.gapH(AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      store.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleMedium.rc(AppColors.authInk),
                    ),
                    AppSpacing.gapV(AppSpacing.xs2),
                    _MetaRow(store: store),
                    AppSpacing.gapV(AppSpacing.xs2),
                    Text(
                      store.priceLabel,
                      style: AppTextStyles.titleLarge.rc(AppColors.authInk),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapH(AppSpacing.xs),
              Container(
                width: _radio.w,
                height: _radio.w,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary600
                      : AppColors.chatFieldFill,
                  shape: BoxShape.circle,
                ),
                child: isSelected
                    ? Icon(
                        Icons.check_rounded,
                        size: AppSizes.xl.w,
                        color: AppColors.white,
                      )
                    : null,
              ),
            ],
          ),
          AppSpacing.gapV(AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: AppRadius.rFull,
                  child: LinearProgressIndicator(
                    value: store.availabilityFraction,
                    minHeight: AppSizes.sm.h,
                    backgroundColor: AppColors.gray100,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary500,
                    ),
                  ),
                ),
              ),
              AppSpacing.gapH(AppSpacing.sm),
              Text(
                AppStrings.availableCount.trParams({
                  'available': '${store.availableCount}',
                  'total': '${store.totalCount}',
                }),
                style: AppTextStyles.titleSmall.rc(AppColors.gray900),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.store});

  final PharmacyStore store;

  @override
  Widget build(BuildContext context) {
    final muted = AppTextStyles.bodyMedium.rc(AppColors.gray400);

    return Wrap(
      spacing: AppSpacing.xs.w,
      runSpacing: AppSpacing.xxs.h,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _Meta(icon: Icons.location_on_outlined, label: store.distanceLabel),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_rounded,
              size: AppSizes.lg.w,
              color: AppColors.star,
            ),
            AppSpacing.gapH(AppSpacing.xxs),
            Text('${store.ratingLabel} (${store.reviewCount})', style: muted),
          ],
        ),
        _Meta(icon: Icons.schedule_outlined, label: store.etaLabel),
      ],
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSizes.lg.w, color: AppColors.gray400),
        AppSpacing.gapH(AppSpacing.xxs),
        Text(label, style: AppTextStyles.bodyMedium.rc(AppColors.gray400)),
      ],
    );
  }
}
