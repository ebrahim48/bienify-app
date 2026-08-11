import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_sizes.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/responsive.dart';

/// Green confirmation strip shown across the top after copying the code.
///
/// An inline banner rather than a snackbar, because the design keeps it in
/// the layout above the content while the code stays visible.
class CodeCopiedBanner extends StatelessWidget {
  const CodeCopiedBanner({
    super.key,
    required this.code,
    this.isVisible = true,
  });

  final String code;
  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: !isVisible
          ? const SizedBox.shrink()
          : Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.base.w,
                vertical: AppSpacing.sm.h,
              ),
              color: AppColors.openSurface,
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: AppSizes.xl2.w,
                    color: AppColors.openInk,
                  ),
                  AppSpacing.gapH(AppSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppStrings.codeCopied.tr,
                          style: AppTextStyles.titleSmall.rc(AppColors.openInk),
                        ),
                        Text(
                          AppStrings.codeCopiedDetail.trParams({'code': code}),
                          style: AppTextStyles.bodyMedium.rc(AppColors.openInk),
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
