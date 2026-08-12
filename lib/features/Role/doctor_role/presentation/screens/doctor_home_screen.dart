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
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_avatar.dart';
import '../../domain/entities/doctor_practice.dart';
import '../controllers/doctor_home_controller.dart';
import '../widgets/appointments_chart.dart';
import '../widgets/set_fees_sheet.dart';

/// The practitioner dashboard.
class DoctorHomeScreen extends GetView<DoctorHomeController> {
  const DoctorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Its own scroll view rather than `AppScaffold`'s: the masthead bleeds to
    // the screen edges while everything under it keeps the 16pt gutter.
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(
            () => _Masthead(
              practitioner: controller.practitioner.value,
              onWithdraw: controller.withdraw,
              onNotifications: controller.exitDoctorRole,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.base.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSpacing.gapV(AppSpacing.base),
                Obx(() => _StatGrid(stats: controller.stats.toList())),
                AppSpacing.gapV(AppSpacing.md),
                Text(
                  AppStrings.quickActions.tr,
                  style: AppTextStyles.titleLarge.rw(
                    AppColors.gray900,
                    FontWeight.w400,
                  ),
                ),
                AppSpacing.gapV(AppSpacing.xs),
                _QuickActions(
                  onSchedule: controller.openSchedule,
                  onFees: () => SetFeesSheet.show(context),
                  onResults: controller.openResultsToReview,
                ),
                AppSpacing.gapV(AppSpacing.md),
                _ChartHeader(controller: controller),
                AppSpacing.gapV(AppSpacing.xs),
                AppCard(
                  hasShadow: false,
                  padding: EdgeInsets.all(AppSpacing.sm.w),
                  child: Obx(
                    () => AppointmentsChart(
                      load: controller.chartLoad.toList(),
                      maxValue: controller.chartMax.value,
                      divisions: controller.chartDivisions,
                    ),
                  ),
                ),
                AppSpacing.gapV(AppSpacing.md),
                // `.toList()` inside the closure: handing the child the
                // `RxList` would subscribe nothing, because the child reads it
                // during its own build. `statusLabel` is pure, so passing the
                // function is safe.
                Obx(
                  () => _UpcomingCard(
                    visits: controller.visits.toList(),
                    statusLabelFor: controller.statusLabel,
                  ),
                ),
                AppSpacing.gapV(AppSpacing.md),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Navy header with the greeting, a notification bell, and the balance panel.
class _Masthead extends StatelessWidget {
  const _Masthead({
    required this.practitioner,
    required this.onWithdraw,
    required this.onNotifications,
  });

  final Practitioner practitioner;
  final VoidCallback onWithdraw;
  final VoidCallback onNotifications;

  static const double _avatar = 48;
  static const double _bell = 44;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.doctorHeader,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.base.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  // The practitioner's own picture when the server has one;
                  // their initials on the header's own tint when it does not.
                  if (practitioner.photoUrl != null)
                    AppAvatar(
                      imageUrl: practitioner.photoUrl,
                      name: practitioner.name,
                      size: _avatar,
                      fallbackAsset: null,
                      backgroundColor: AppColors.doctorHeaderPanel,
                      foregroundColor: AppColors.white,
                    )
                  else
                    Container(
                      width: _avatar.w,
                      height: _avatar.w,
                      decoration: BoxDecoration(
                        color: AppColors.doctorHeaderPanel,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        practitioner.initials,
                        style: AppTextStyles.titleSmall.rc(AppColors.white),
                      ),
                    ),
                  AppSpacing.gapH(AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppStrings.goodMorning.tr,
                          style: AppTextStyles.bodyLarge.rc(
                            AppColors.white.withValues(alpha: 0.76),
                          ),
                        ),
                        Text(
                          practitioner.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleLarge.rc(AppColors.white),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapH(AppSpacing.xs),
                  _BellButton(
                    size: _bell,
                    hasUnread: practitioner.hasUnreadNotification,
                    onTap: onNotifications,
                  ),
                ],
              ),
              AppSpacing.gapV(AppSpacing.base),
              _BalancePanel(
                amount: practitioner.balanceLabel,
                onWithdraw: onWithdraw,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton({
    required this.size,
    required this.hasUnread,
    required this.onTap,
  });

  final double size;
  final bool hasUnread;
  final VoidCallback onTap;

  static const double _dot = 10;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size.w,
            height: size.w,
            decoration: BoxDecoration(
              color: AppColors.doctorHeaderPanel,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.notifications_none_rounded,
              size: AppSizes.xl2.w,
              color: AppColors.white,
            ),
          ),
          if (hasUnread)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: _dot.w,
                height: _dot.w,
                decoration: const BoxDecoration(
                  color: AppColors.statWarnInk,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BalancePanel extends StatelessWidget {
  const _BalancePanel({required this.amount, required this.onWithdraw});

  final String amount;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.base.w),
      decoration: BoxDecoration(
        color: AppColors.doctorHeaderPanel,
        borderRadius: AppRadius.rLg,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.availableBalance2.tr,
                  style: AppTextStyles.bodyLarge.rc(
                    AppColors.white.withValues(alpha: 0.76),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    amount,
                    maxLines: 1,
                    style: AppTextStyles.headlineMedium.rc(AppColors.white),
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.gapH(AppSpacing.sm),
          Material(
            color: AppColors.white,
            borderRadius: AppRadius.rFull,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onWithdraw,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.base.w,
                  vertical: AppSpacing.xs.h,
                ),
                child: Text(
                  AppStrings.withdraw.tr,
                  style: AppTextStyles.titleSmall.rc(AppColors.actionFill),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Four statistics in a 2×2 grid, each with a tinted icon disc.
class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stats});

  final List<PracticeStat> stats;

  static const List<IconData> _icons = [
    Icons.error_outline_rounded,
    Icons.monitor_heart_outlined,
    Icons.trending_up_rounded,
    Icons.people_outline_rounded,
  ];

  static const List<(Color, Color)> _tints = [
    (AppColors.statWarnSurface, AppColors.statWarnInk),
    (AppColors.statInfoSurface, AppColors.statInfoInk),
    (AppColors.statUpSurface, AppColors.statUpInk),
    (AppColors.statPeopleSurface, AppColors.statPeopleInk),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var row = 0; row < 2; row++) ...[
          if (row > 0) AppSpacing.gapV(AppSpacing.sm),
          Row(
            children: [
              for (var column = 0; column < 2; column++) ...[
                if (column > 0) AppSpacing.gapH(AppSpacing.sm),
                Expanded(
                  child: _StatCard(
                    stat: stats[row * 2 + column],
                    icon: _icons[row * 2 + column],
                    tint: _tints[row * 2 + column],
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat, required this.icon, required this.tint});

  final PracticeStat stat;
  final IconData icon;
  final (Color, Color) tint;

  static const double _disc = 36;

  /// A floor, not a fixed height: one label wraps to two lines and the other
  /// does not, and a hard height would clip whenever `.sp` and `.h` diverge.
  static const double _minHeight = 116;

  @override
  Widget build(BuildContext context) {
    final (surface, ink) = tint;

    return AppCard(
      hasShadow: false,
      padding: EdgeInsets.all(AppSpacing.sm.w),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: _minHeight.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: _disc.w,
              height: _disc.w,
              decoration: BoxDecoration(color: surface, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(icon, size: AppSizes.xl.w, color: ink),
            ),
            AppSpacing.gapV(AppSpacing.sm),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                stat.value,
                maxLines: 1,
                style: AppTextStyles.headlineSmall.rc(AppColors.gray900),
              ),
            ),
            AppSpacing.gapV(AppSpacing.xxs),
            Text(
              stat.label,
              maxLines: 2,
              style: AppTextStyles.bodyLarge.rc(AppColors.gray500),
            ),
          ],
        ),
      ),
    );
  }
}

/// Three actions: two on the first row, the third alone underneath — which is
/// how the design lays them out rather than stretching one across.
class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onSchedule,
    required this.onFees,
    required this.onResults,
  });

  final VoidCallback onSchedule;
  final VoidCallback onFees;
  final VoidCallback onResults;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.calendar_today_outlined,
                ink: AppColors.gray900,
                label: AppStrings.setSchedule.tr,
                onTap: onSchedule,
              ),
            ),
            AppSpacing.gapH(AppSpacing.sm),
            Expanded(
              child: _ActionTile(
                icon: Icons.attach_money_rounded,
                ink: AppColors.statWarnInk,
                label: AppStrings.setFees.tr,
                onTap: onFees,
              ),
            ),
          ],
        ),
        AppSpacing.gapV(AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.colorize_rounded,
                ink: AppColors.gray900,
                label: AppStrings.resultsToReview.tr,
                onTap: onResults,
              ),
            ),
            // The empty half keeps the lone tile the same width as the pair
            // above it.
            AppSpacing.gapH(AppSpacing.sm),
            const Spacer(),
          ],
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.ink,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color ink;
  final String label;
  final VoidCallback onTap;

  static const double _height = 84;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.rLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: _height.h,
          decoration: BoxDecoration(
            borderRadius: AppRadius.rLg,
            border: Border.all(
              color: AppColors.surfaceBorder,
              width: AppSizes.borderWidth,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: AppSizes.xl2.w, color: ink),
              AppSpacing.gapV(AppSpacing.xs),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyLarge.rc(AppColors.gray900),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartHeader extends StatelessWidget {
  const _ChartHeader({required this.controller});

  final DoctorHomeController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            AppStrings.appointmentsOverview.tr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.titleLarge.rw(
              AppColors.gray900,
              FontWeight.w400,
            ),
          ),
        ),
        // The range is read here so the label repaints when it changes.
        Obx(
          () => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => controller.selectRange(
              controller.range.value == ChartRange.weekly
                  ? ChartRange.monthly
                  : ChartRange.weekly,
            ),
            child: Row(
              children: [
                Text(
                  controller.rangeLabel(controller.range.value),
                  style: AppTextStyles.bodyLarge.rc(AppColors.link),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: AppSizes.xl.w,
                  color: AppColors.link,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Today's list, with a hairline between rows inside one card.
class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.visits, required this.statusLabelFor});

  final List<PatientVisit> visits;
  final String Function(VisitStatus) statusLabelFor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hasShadow: false,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.all(AppSpacing.sm.w),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.upcomingAppointments2.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleSmall.rc(AppColors.gray900),
                  ),
                ),
                Text(
                  AppStrings.seeAll.tr,
                  style: AppTextStyles.bodyLarge.rc(AppColors.link),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: AppSizes.xl.w,
                  color: AppColors.link,
                ),
              ],
            ),
          ),
          for (final visit in visits) ...[
            Container(
              height: AppSizes.borderWidth,
              color: AppColors.surfaceBorder,
            ),
            _VisitRow(visit: visit, statusLabel: statusLabelFor(visit.status)),
          ],
        ],
      ),
    );
  }
}

class _VisitRow extends StatelessWidget {
  const _VisitRow({required this.visit, required this.statusLabel});

  final PatientVisit visit;
  final String statusLabel;

  static const double _avatar = 40;

  /// Initials discs cycle the chart palette at low opacity, which is what
  /// gives the design its pink / amber / green / mint sequence.
  Color get _avatarTint => AppColors
      .chartBars[visit.patientName.length % AppColors.chartBars.length]
      .withValues(alpha: 0.18);

  Color get _statusInk => visit.status == VisitStatus.confirmed
      ? AppColors.confirmedInk
      : AppColors.pendingOutlineInk;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.sm.w),
      child: Row(
        children: [
          Container(
            width: _avatar.w,
            height: _avatar.w,
            decoration: BoxDecoration(
              color: _avatarTint,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              visit.initials,
              style: AppTextStyles.labelLarge.rc(AppColors.gray900),
            ),
          ),
          AppSpacing.gapH(AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  visit.patientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSmall.rc(AppColors.gray900),
                ),
                Text(
                  visit.reason,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.rc(AppColors.gray500),
                ),
              ],
            ),
          ),
          AppSpacing.gapH(AppSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                visit.timeLabel,
                style: AppTextStyles.titleSmall.rc(AppColors.gray900),
              ),
              AppSpacing.gapV(AppSpacing.xxs),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs.w,
                  vertical: AppSpacing.xxs.h,
                ),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.rFull,
                  border: Border.all(
                    color: _statusInk,
                    width: AppSizes.borderWidth,
                  ),
                ),
                child: Text(
                  statusLabel,
                  style: AppTextStyles.bodyMedium.rc(_statusInk),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
