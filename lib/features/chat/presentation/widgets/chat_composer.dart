import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_svg_icon.dart';

/// The bottom input bar: attach button, rounded text field, send button.
class ChatComposer extends StatelessWidget {
  const ChatComposer({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onAttach,
    this.canSend = false,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final bool canSend;

  static const double _action = 44;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.surfaceBorder,
            width: AppSizes.borderWidth,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.sm.w,
            vertical: AppSpacing.xs.h + 2,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _CircleAction(
                onTap: onAttach,
                background: AppColors.chatFieldFill,
                child: AppSvgIcon(
                  AppIcons.paperclip,
                  size: AppSizes.xl2,
                  color: AppColors.gray500,
                ),
              ),
              AppSpacing.gapH(AppSpacing.xs),
              Expanded(
                child: Container(
                  constraints: BoxConstraints(minHeight: _action.h),
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.base.w),
                  decoration: BoxDecoration(
                    color: AppColors.chatFieldFill,
                    borderRadius: AppRadius.rFull,
                  ),
                  child: TextField(
                    controller: controller,
                    maxLines: 4,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    cursorColor: AppColors.primary800,
                    style: AppTextStyles.bodyLarge.rc(AppColors.gray900),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: AppStrings.typeYourMessage.tr,
                      hintStyle: AppTextStyles.bodyLarge.rc(
                        AppColors.textSecondary,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: AppSpacing.sm.h,
                      ),
                    ),
                  ),
                ),
              ),
              AppSpacing.gapH(AppSpacing.xs),
              // Always drawn filled, as in the design; only the tap is gated
              // on there being something to send.
              _CircleAction(
                onTap: canSend ? onSend : null,
                background: AppColors.actionFill,
                child: AppSvgIcon(
                  AppIcons.send,
                  size: AppSizes.xl2,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.onTap,
    required this.background,
    required this.child,
  });

  final VoidCallback? onTap;
  final Color background;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: ChatComposer._action.w,
          height: ChatComposer._action.w,
          child: Center(child: child),
        ),
      ),
    );
  }
}
