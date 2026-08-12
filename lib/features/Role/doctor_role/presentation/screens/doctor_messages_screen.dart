import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/responsive.dart';
import '../../../../../core/widgets/app_avatar.dart';
import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/app_empty_state.dart';
import '../../../../../core/widgets/app_scaffold.dart';
import '../../../patient/doctors/presentation/widgets/doctor_search_field.dart';
import '../../domain/entities/doctor_practice.dart';
import '../controllers/doctor_messages_controller.dart';

/// The doctor's Message tab: a searchable list of patient threads.
///
/// Tapping one opens the patient app's `ChatScreen` with the patient as its
/// peer — there is one messaging screen, not two.
class DoctorMessagesScreen extends GetView<DoctorMessagesController> {
  const DoctorMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenTopGap(),
          Text(
            AppStrings.messageTitle.tr,
            style: AppTextStyles.titleLarge.rw(
              AppColors.gray900,
              FontWeight.w400,
            ),
          ),
          AppSpacing.gapV(AppSpacing.sm),
          DoctorSearchField(
            initialText: controller.query.value,
            hintKey: AppStrings.searchPatientName,
            onChanged: (value) => controller.query.value = value,
          ),
          AppSpacing.gapV(AppSpacing.sm),
          Obx(() {
            final threads = controller.visible;
            if (threads.isEmpty) {
              return AppEmptyState(
                icon: Icons.forum_outlined,
                title: AppStrings.noTestsYet.tr,
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final thread in threads) ...[
                  _ThreadRow(
                    thread: thread,
                    onTap: () => controller.openThread(thread),
                  ),
                  AppSpacing.gapV(AppSpacing.xs),
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

class _ThreadRow extends StatelessWidget {
  const _ThreadRow({required this.thread, required this.onTap});

  final PatientThread thread;
  final VoidCallback onTap;

  static const double _avatar = 44;
  static const double _badge = 24;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hasShadow: false,
      onTap: onTap,
      padding: EdgeInsets.all(AppSpacing.xs.w),
      child: Row(
        children: [
          AppAvatar(
            imageUrl: thread.photoUrl,
            name: thread.patientName,
            size: _avatar,
            fallbackAsset: thread.photoAsset,
          ),
          AppSpacing.gapH(AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  thread.patientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSmall.rc(AppColors.gray900),
                ),
                Text(
                  thread.preview,
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
                thread.timeLabel,
                style: AppTextStyles.bodyMedium.rc(AppColors.gray500),
              ),
              AppSpacing.gapV(AppSpacing.xs2),
              if (thread.unreadCount > 0)
                Container(
                  width: _badge.w,
                  height: _badge.w,
                  decoration: const BoxDecoration(
                    color: AppColors.actionFill,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: FittedBox(
                    child: Text(
                      '${thread.unreadCount}',
                      style: AppTextStyles.labelLarge.rc(AppColors.white),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
