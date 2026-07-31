import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';

import '../../../../../core/theme/app_sizes.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_empty_state.dart';
import '../../../../../core/widgets/app_pill_selector.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../../domain/entities/rider.dart';
import '../controllers/rider_orders_controller.dart';
import '../widgets/rider_widgets.dart';

/// The board of jobs, one chip at a time.
class RiderOrdersScreen extends GetView<RiderOrdersController> {
  const RiderOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenTopGap(),
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.orderRequests.tr,
                  style: AppTextStyles.headlineSmall.rc(AppColors.authInk),
                ),
              ),
              Obx(
                () => Text(
                  AppStrings.newCount.trParams({
                    'count': '${controller.openCount}',
                  }),
                  style: AppTextStyles.bodyMedium.rc(AppColors.link),
                ),
              ),
            ],
          ),
          AppSpacing.gapV(AppSpacing.sm),
          Obx(
            () => AppPillSelector(
              labels: [
                for (final value in RequestTab.values)
                  controller.tabLabel(value),
              ],
              selectedIndex: RequestTab.values.indexOf(controller.tab.value),
              onSelected: (index) =>
                  controller.selectTab(RequestTab.values[index]),
              isLarge: true,
              horizontalPadding: AppSpacing.sm,
            ),
          ),
          AppSpacing.gapV(AppSpacing.sm),
          Obx(() {
            final rows = controller.visible;
            if (rows.isEmpty) {
              return AppEmptyState(title: AppStrings.noRequestsHere.tr);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final request in rows) ...[
                  _RequestCard(request: request),
                  AppSpacing.gapV(AppSpacing.sm),
                ],
              ],
            );
          }),
          AppSpacing.gapV(AppSpacing.md),
        ],
      ),
    );
  }
}

/// One job: its fee, both ends of the trip, what it involves, and the
/// action the chip allows.
class _RequestCard extends GetView<RiderOrdersController> {
  const _RequestCard({required this.request});

  final DeliveryRequest request;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hasShadow: false,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.all(AppSpacing.sm.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        request.code,
                        style: AppTextStyles.bodyMedium.rc(AppColors.gray500),
                      ),
                    ),
                    FeePill(label: request.feeLabel),
                  ],
                ),
                AppSpacing.gapV(AppSpacing.xs),
                _Endpoint(
                  emoji: '🏪',
                  caption: AppStrings.pickUpFrom.tr,
                  name: request.pickupName,
                ),
                AppSpacing.gapV(AppSpacing.xs),
                _Endpoint(
                  emoji: '📍',
                  caption: AppStrings.deliverTo.tr,
                  name: request.customerName,
                  detail: request.customerAddress,
                ),
                AppSpacing.gapV(AppSpacing.xs),
                Divider(
                  height: AppSizes.borderWidth,
                  thickness: AppSizes.borderWidth,
                  color: AppColors.chipSurface,
                ),
                AppSpacing.gapV(AppSpacing.xs),
                _Meta(request: request),
              ],
            ),
          ),
          Divider(
            height: AppSizes.borderWidth,
            thickness: AppSizes.borderWidth,
            color: AppColors.chipSurface,
          ),
          _Actions(request: request),
        ],
      ),
    );
  }
}

/// Either end of the trip: a glyph, a caption and who or what is there.
class _Endpoint extends StatelessWidget {
  const _Endpoint({
    required this.emoji,
    required this.caption,
    required this.name,
    this.detail,
  });

  final String emoji;
  final String caption;
  final String name;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: AppTextStyles.bodyLarge),
        AppSpacing.gapH(AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                caption,
                style: AppTextStyles.labelMedium.rw(
                  AppColors.gray500,
                  FontWeight.w500,
                ),
              ),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleSmall.rc(AppColors.gray900),
              ),
              if (detail != null)
                Text(
                  detail!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.rc(AppColors.gray500),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Time, distance and contents on one line.
class _Meta extends StatelessWidget {
  const _Meta({required this.request});

  final DeliveryRequest request;

  @override
  Widget build(BuildContext context) {
    // Wraps rather than a Row: the item list is the longest part and would
    // otherwise clip the two figures before it.
    return Wrap(
      spacing: AppSpacing.sm.w,
      runSpacing: AppSpacing.xs2.h,
      children: [
        _MetaItem(emoji: '🕐', label: request.minutesLabel),
        _MetaItem(emoji: '📏', label: request.distanceLabel),
        _MetaItem(emoji: '💊', label: request.items),
      ],
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.emoji, required this.label});

  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: AppTextStyles.bodySmall),
        AppSpacing.gapH(AppSpacing.xs2),
        Text(label, style: AppTextStyles.bodyMedium.rc(AppColors.gray500)),
      ],
    );
  }
}

/// The foot of a card: Decline / Accept while the job is new, Track LIVE once
/// it is taken, and nothing at all once it is cancelled.
class _Actions extends GetView<RiderOrdersController> {
  const _Actions({required this.request});

  final DeliveryRequest request;

  static const double _height = 44;

  @override
  Widget build(BuildContext context) {
    if (request.tab == RequestTab.cancelled) {
      return const SizedBox.shrink();
    }

    if (request.tab == RequestTab.accepted) {
      return Material(
        color: AppColors.authPanelSoft,
        child: InkWell(
          onTap: () => controller.track(request),
          child: SizedBox(
            height: _height.h,
            child: Center(
              child: Text(
                AppStrings.trackLive.tr,
                style: AppTextStyles.titleSmall.rc(AppColors.actionFill),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: _height.h,
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => controller.decline(request),
              child: Center(
                child: Text(
                  AppStrings.decline.tr,
                  style: AppTextStyles.bodyLarge.rc(AppColors.gray600),
                ),
              ),
            ),
          ),
          VerticalDivider(
            width: AppSizes.borderWidth,
            thickness: AppSizes.borderWidth,
            color: AppColors.chipSurface,
          ),
          Expanded(
            child: InkWell(
              onTap: () => controller.accept(request),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppStrings.accept.tr,
                    style: AppTextStyles.titleSmall.rc(AppColors.actionFill),
                  ),
                  AppSpacing.gapH(AppSpacing.xs2),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: AppSizes.lg.w,
                    color: AppColors.actionFill,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
