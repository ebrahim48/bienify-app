import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/responsive.dart';
import '../../../../../../core/widgets/app_button.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../../../../../core/widgets/presence_avatar.dart';
import '../../../../../../core/widgets/app_empty_state.dart';
import '../../../../../../core/widgets/app_scaffold.dart';
import '../../../../../../core/widgets/app_top_bar.dart';
import '../../../doctors/presentation/widgets/doctor_search_field.dart';
import '../../domain/entities/conversation.dart';
import '../controllers/messages_controller.dart';

/// The patient's message list: every consultation with a thread.
///
/// Tapping a row opens the same `ChatScreen` the doctor's side uses, with the
/// doctor as its peer — there is one messaging screen, not two.
class MessagesScreen extends GetView<MessagesController> {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      topBar: AppTopBar(title: AppStrings.messageTitle.tr),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapV(AppSpacing.xs),
          Obx(
            () => DoctorSearchField(
              initialText: controller.query.value,
              hintKey: AppStrings.searchMessages,
              onChanged: (value) => controller.query.value = value,
            ),
          ),
          AppSpacing.gapV(AppSpacing.sm),
          Obx(() {
            if (controller.isLoading.value) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (controller.error.value != null) return _Failure();

            final threads = controller.visible;
            if (threads.isEmpty) {
              return AppEmptyState(
                icon: Icons.forum_outlined,
                title: controller.query.value.trim().isEmpty
                    ? AppStrings.noMessagesYet.tr
                    : AppStrings.noMessagesMatch.tr,
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final thread in threads) ...[
                  // Scoped to this row: an `Obx` around the whole list would
                  // rebuild every row each time anybody's presence changed.
                  Obx(
                    () => _ThreadRow(
                      thread: thread,
                      isOnline: controller.isPeerOnline(thread),
                      onTap: () => controller.openThread(thread),
                    ),
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

/// Retryable error state, shown in place of the list.
class _Failure extends GetView<MessagesController> {
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

class _ThreadRow extends StatelessWidget {
  const _ThreadRow({
    required this.thread,
    required this.onTap,
    this.isOnline,
  });

  final ConversationThread thread;
  final VoidCallback onTap;

  /// Null until presence for this peer is known, which draws no dot at all —
  /// an unanswered question should not look like a confident "offline".
  final bool? isOnline;

  static const double _avatar = 44;
  static const double _badge = 24;

  @override
  Widget build(BuildContext context) {
    // The repository leaves the name empty when a thread has no matching
    // appointment to be named from; localising that belongs here, not there.
    final name = thread.peer.name.isEmpty
        ? AppStrings.doctorFallback.tr
        : thread.peer.name;

    return AppCard(
      hasShadow: false,
      onTap: onTap,
      padding: EdgeInsets.all(AppSpacing.xs.w),
      child: Row(
        children: [
          PresenceAvatar(
            isOnline: isOnline,
            imageUrl: thread.peer.photoUrl,
            name: name,
            size: _avatar,
            fallbackAsset: thread.peer.photoAsset,
          ),
          AppSpacing.gapH(AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSmall.rc(AppColors.gray900),
                ),
                Text(
                  thread.preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.rc(
                    thread.hasUnread ? AppColors.gray900 : AppColors.gray500,
                  ),
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
              if (thread.hasUnread)
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
