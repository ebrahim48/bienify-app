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
import '../../../../../core/widgets/app_empty_state.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../../../../../core/widgets/app_top_bar.dart';
import '../../../patient/notifications/domain/entities/app_notification.dart';
import '../controllers/doctor_notifications_controller.dart';

/// The practitioner's notification feed, behind the dashboard's bell.
class DoctorNotificationsScreen extends GetView<DoctorNotificationsController> {
  const DoctorNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.notifications.tr),
      child: Obx(() {
        if (controller.isLoading.value) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (controller.error.value != null) return _Failure();
        if (controller.notifications.isEmpty) {
          return AppEmptyState(
            icon: Icons.notifications_none_rounded,
            title: AppStrings.noNotificationsYet.tr,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSpacing.gapV(AppSpacing.xs),
            if (controller.hasUnread) _MarkAllRow(),
            for (final notification in controller.notifications) ...[
              _NotificationRow(
                notification: notification,
                onTap: () => controller.open(notification),
              ),
              AppSpacing.gapV(AppSpacing.xs),
            ],
            AppSpacing.gapV(AppSpacing.md),
          ],
        );
      }),
    );
  }
}

class _MarkAllRow extends GetView<DoctorNotificationsController> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              AppStrings.unreadCount.trParams({
                'count': '${controller.unreadCount}',
              }),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.rc(AppColors.gray500),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: controller.markAllRead,
            child: Text(
              AppStrings.markAllRead.tr,
              style: AppTextStyles.bodyMedium.rc(AppColors.primary600),
            ),
          ),
        ],
      ),
    );
  }
}

class _Failure extends GetView<DoctorNotificationsController> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl4.h),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 48.w, color: AppColors.gray300),
          AppSpacing.gapV(AppSpacing.base),
          Text(
            controller.error.value ?? AppStrings.somethingWentWrong.tr,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.rc(AppColors.textSecondary),
          ),
          AppSpacing.gapV(AppSpacing.md),
          AppButton(
            label: AppStrings.retry.tr,
            expanded: false,
            onPressed: controller.load,
          ),
        ],
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  static const double _icon = 40;
  static const double _dot = 8;

  IconData get _glyph => switch (notification.kind) {
    NotificationKind.appointmentBooked ||
    NotificationKind.appointmentConfirmed => Icons.event_available_rounded,
    NotificationKind.appointmentCancelled => Icons.event_busy_rounded,
    NotificationKind.appointmentReminder => Icons.alarm_rounded,
    NotificationKind.prescriptionIssued => Icons.description_rounded,
    NotificationKind.orderStatus => Icons.shopping_bag_rounded,
    NotificationKind.deliveryStatus => Icons.local_shipping_rounded,
    NotificationKind.labResultReady => Icons.science_rounded,
    NotificationKind.verificationUpdate => Icons.verified_user_rounded,
    NotificationKind.payment => Icons.payments_rounded,
    NotificationKind.system || NotificationKind.other =>
      Icons.notifications_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final isRead = notification.isRead;

    return AppCard(
      hasShadow: false,
      onTap: onTap,
      color: isRead ? AppColors.chatFieldFill : AppColors.surface,
      padding: EdgeInsets.all(AppSpacing.sm.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: _icon.w,
            height: _icon.w,
            decoration: BoxDecoration(
              color: isRead ? AppColors.gray200 : AppColors.doctorHeader,
              borderRadius: AppRadius.rMd,
            ),
            alignment: Alignment.center,
            child: Icon(
              _glyph,
              size: AppSizes.xl.w,
              color: isRead ? AppColors.gray500 : AppColors.white,
            ),
          ),
          AppSpacing.gapH(AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleSmall.rc(
                          isRead ? AppColors.gray500 : AppColors.gray900,
                        ),
                      ),
                    ),
                    if (!isRead) ...[
                      AppSpacing.gapH(AppSpacing.xs),
                      Container(
                        width: _dot.w,
                        height: _dot.w,
                        margin: EdgeInsets.only(top: AppSpacing.xs2.h),
                        decoration: const BoxDecoration(
                          color: AppColors.doctorHeader,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                AppSpacing.gapV(AppSpacing.xxs),
                Text(
                  notification.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.rc(AppColors.gray500),
                ),
                AppSpacing.gapV(AppSpacing.xs2),
                Text(
                  notification.ageLabel,
                  style: AppTextStyles.labelSmall.rc(AppColors.gray400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
