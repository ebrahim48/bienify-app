import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_radius.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/responsive.dart';
import '../../../../../../core/widgets/app_button.dart';
import '../../domain/entities/doctor.dart';

/// Result list with its three states: loading, empty and error.
///
/// Kept separate from the screen so the Doctors tab and the Search screen
/// behave identically without duplicating the state handling.
class DoctorResultList extends StatelessWidget {
  const DoctorResultList({
    super.key,
    required this.doctors,
    required this.isLoading,
    required this.itemBuilder,
    this.errorMessage,
    this.onRetry,
  });

  final List<Doctor> doctors;
  final bool isLoading;
  final Widget Function(Doctor) itemBuilder;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const _LoadingList();

    if (errorMessage != null) {
      return _Message(
        icon: Icons.cloud_off_rounded,
        text: errorMessage!,
        onRetry: onRetry,
      );
    }

    if (doctors.isEmpty) {
      return _Message(
        icon: Icons.search_off_rounded,
        text: AppStrings.noDoctorsFound.tr,
      );
    }

    return ListView.separated(
      padding: EdgeInsets.only(bottom: AppSpacing.lg.h),
      physics: const ClampingScrollPhysics(),
      itemCount: doctors.length,
      separatorBuilder: (_, _) => AppSpacing.gapV(AppSpacing.sm),
      itemBuilder: (context, index) => itemBuilder(doctors[index]),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.gray100,
      highlightColor: AppColors.gray50,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        separatorBuilder: (_, _) => AppSpacing.gapV(AppSpacing.sm),
        itemBuilder: (context, index) => Container(
          height: 70.h,
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: AppRadius.rXl,
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.onRetry});

  final IconData icon;
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48.w, color: AppColors.gray300),
          AppSpacing.gapV(AppSpacing.sm),
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.rc(AppColors.textSecondary),
          ),
          if (onRetry != null) ...[
            AppSpacing.gapV(AppSpacing.base),
            AppButton(
              label: AppStrings.retry.tr,
              expanded: false,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}
