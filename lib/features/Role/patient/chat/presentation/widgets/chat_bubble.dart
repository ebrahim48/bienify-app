import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_radius.dart';
import '../../../../../../core/theme/app_sizes.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/responsive.dart';
import '../../domain/entities/conversation.dart';

/// One message bubble: white on the left for the doctor, `primary600` on the
/// right for the patient, each with a timestamp underneath the text.
class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});

  final ChatMessage message;

  /// Bubbles stop well short of the opposite edge so the thread stays
  /// readable as a conversation.
  static const double _maxWidthFactor = 0.76;

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    final ink = isMine ? AppColors.white : AppColors.gray900;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * _maxWidthFactor,
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.sm.w,
            vertical: AppSpacing.xs.h + 2,
          ),
          decoration: BoxDecoration(
            color: isMine ? AppColors.primary600 : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl.r),
            border: isMine
                ? null
                : Border.all(
                    color: AppColors.surfaceBorder,
                    width: AppSizes.borderWidth,
                  ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.text,
                style: AppTextStyles.bodyLarge.rc(ink),
              ),
              AppSpacing.gapV(AppSpacing.xs2),
              Text(
                message.timeLabel,
                style: AppTextStyles.bodyMedium.rc(
                  isMine ? AppColors.primary100 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
