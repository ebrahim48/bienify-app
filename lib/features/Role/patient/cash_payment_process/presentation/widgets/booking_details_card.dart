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
import '../../../../../../core/widgets/app_card.dart';
import '../../domain/entities/cash_payment.dart';

/// The receipt: booking rows, the dispensed medicines, and the total.
class BookingDetailsCard extends StatelessWidget {
  const BookingDetailsCard({super.key, required this.confirmation});

  final PaymentConfirmation confirmation;

  static const double _badge = 36;

  static IconData _iconFor(BookingDetailKind kind) => switch (kind) {
    BookingDetailKind.orderId => Icons.receipt_long_outlined,
    BookingDetailKind.date => Icons.calendar_today_outlined,
    BookingDetailKind.delivery => Icons.schedule_outlined,
    BookingDetailKind.pharmacy => Icons.inventory_2_outlined,
    BookingDetailKind.prescription => Icons.medical_information_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final details = confirmation.details;

    return AppCard(
      radius: AppRadius.xl2,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.base.w,
        vertical: AppSpacing.md.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionLabel(AppStrings.bookingDetails.tr),
          AppSpacing.gapV(AppSpacing.sm),
          for (var index = 0; index < details.length; index++) ...[
            _DetailRow(
              icon: _iconFor(details[index].kind),
              label: details[index].label.tr,
              value: details[index].value,
            ),
            if (index != details.length - 1) const _Rule(),
          ],
          AppSpacing.gapV(AppSpacing.md),
          const _Rule(),
          AppSpacing.gapV(AppSpacing.md),
          _SectionLabel(
            AppStrings.medicinesCount.trParams({
              'count': '${confirmation.medicines.length}',
            }),
          ),
          AppSpacing.gapV(AppSpacing.sm),
          for (final medicine in confirmation.medicines) ...[
            _MedicineRow(medicine: medicine),
            AppSpacing.gapV(AppSpacing.sm),
          ],
          const _Rule(),
          AppSpacing.gapV(AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.totalPaid.tr,
                style: AppTextStyles.titleMedium.rc(AppColors.black),
              ),
              Text(
                confirmation.totalLabel,
                style: AppTextStyles.headlineSmall.rc(AppColors.black),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.labelLarge
          .rc(AppColors.gray400)
          .copyWith(letterSpacing: 1.2),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) => Divider(
    height: AppSizes.borderWidth,
    thickness: AppSizes.borderWidth,
    color: AppColors.surfaceBorder,
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs.h),
      child: Row(
        children: [
          Container(
            width: BookingDetailsCard._badge.w,
            height: BookingDetailsCard._badge.w,
            decoration: BoxDecoration(
              color: AppColors.accentSurface,
              borderRadius: AppRadius.rXl,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: AppSizes.xl.w, color: AppColors.primary700),
          ),
          AppSpacing.gapH(AppSpacing.xs),
          // The value gets the larger share: a clipped value would hide the
          // very information the receipt exists to show, whereas a clipped
          // label is still guessable from its icon.
          Expanded(
            flex: 4,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.rc(AppColors.gray400),
            ),
          ),
          AppSpacing.gapH(AppSpacing.xs),
          Expanded(
            flex: 6,
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: AppTextStyles.labelLarge.rc(AppColors.black),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicineRow extends StatelessWidget {
  const _MedicineRow({required this.medicine});

  final MedicineLine medicine;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: medicine.name,
                  style: AppTextStyles.bodyLarge.rc(AppColors.gray900),
                ),
                TextSpan(
                  text: ' ${medicine.dosage}',
                  style: AppTextStyles.bodyLarge.rc(AppColors.gray300),
                ),
                TextSpan(
                  text: ' ×${medicine.quantity}',
                  style: AppTextStyles.bodyLarge.rc(AppColors.gray900),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        AppSpacing.gapH(AppSpacing.xs),
        Text(
          medicine.priceLabel,
          style: AppTextStyles.titleSmall.rc(AppColors.black),
        ),
      ],
    );
  }
}
