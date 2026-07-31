import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_icons.dart';
import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_radius.dart';
import '../../../../../../core/theme/app_sizes.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/responsive.dart';
import '../../../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../../../../core/widgets/app_top_bar.dart';
import '../../../../../../core/widgets/destructive_bar.dart';
import '../controllers/documents_controller.dart';

/// My Health Profile — three sections of paired tiles, then Delete Account.
class HealthProfileScreen extends GetView<DocumentsController> {
  const HealthProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.myHealthProfile.tr),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.md),
          _SectionLabel(AppStrings.records.tr),
          _TilePair(
            left: _Tile(
              icon: Icons.description,
              label: AppStrings.allPrescriptions.tr,
              onTap: controller.openPrescriptions,
            ),
            right: _Tile(
              icon: Icons.assignment,
              label: AppStrings.allTestReports.tr,
              onTap: controller.openTestReports,
            ),
          ),
          AppSpacing.gapV(AppSpacing.base),
          _SectionLabel(AppStrings.consultation.tr),
          _TilePair(
            left: _Tile(
              icon: Icons.event_note,
              label: AppStrings.pastAppointmentsTitle.tr,
              onTap: controller.openPastAppointments,
            ),
            right: _Tile(
              icon: Icons.health_and_safety,
              label: AppStrings.orderHistory.tr,
              onTap: controller.openOrderHistory,
            ),
          ),
          AppSpacing.gapV(AppSpacing.base),
          _SectionLabel(AppStrings.bienifyHelp.tr),
          _TilePair(
            left: _Tile(
              icon: Icons.forum,
              label: AppStrings.chatWithUs.tr,
              onTap: controller.openSupportChat,
            ),
            right: _Tile(
              icon: Icons.call,
              label: AppStrings.callWithUs.tr,
              onTap: controller.callSupport,
            ),
          ),
          // Pushes the destructive action clear of the tiles without a
          // `Spacer`, which has no free space to take inside a scroll view.
          AppSpacing.gapV(AppSpacing.xl6),
          AppSpacing.gapV(AppSpacing.xl3),
          DestructiveBar(
            iconAsset: AppIcons.delete,
            label: AppStrings.deleteAccount.tr,
            onTap: () => _confirmDelete(context),
          ),
          AppSpacing.gapV(AppSpacing.md),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      question: AppStrings.deleteAccountQuestion.tr,
      confirmLabel: AppStrings.delete.tr,
      denyLabel: AppStrings.cancel.tr,
      confirmColor: AppColors.logoutFill,
    );
    if (confirmed ?? false) controller.deleteAccount();
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.xs.h),
      child: Text(
        label,
        style: AppTextStyles.titleLarge.rw(AppColors.authInk, FontWeight.w400),
      ),
    );
  }
}

/// Two equal tiles side by side. `Expanded` rather than a `GridView` so the
/// pair sizes itself and the page stays one scrollable column.
class _TilePair extends StatelessWidget {
  const _TilePair({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        AppSpacing.gapH(AppSpacing.base),
        Expanded(child: right),
      ],
    );
  }
}

/// A white card with a centred glyph, and its label *below* the card — which
/// is what the design draws, not inside it.
class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  static const double _cardHeight = 86;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: _cardHeight.h,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.rLg,
              border: Border.all(
                color: AppColors.surfaceBorder,
                width: AppSizes.borderWidth,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: AppSizes.xl2.w, color: AppColors.gray900),
          ),
          AppSpacing.gapV(AppSpacing.xs),
          Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyLarge.rc(AppColors.gray900),
          ),
        ],
      ),
    );
  }
}
