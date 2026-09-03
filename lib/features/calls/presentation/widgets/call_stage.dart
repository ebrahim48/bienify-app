import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_avatar.dart';

/// The face, the name and the status line every ringing screen shows.
///
/// Shared by the incoming and outgoing screens because they are the same
/// picture from two sides — the only difference is which buttons sit under it,
/// which is why those are the child rather than a flag on this.
class CallStage extends StatelessWidget {
  const CallStage({
    super.key,
    required this.name,
    required this.status,
    required this.actions,
    this.photoUrl,
    this.caption,
  });

  final String name;

  /// `Ringing…`, `Connecting…` — the line under the name.
  final String status;

  /// What this side of the call can do about it.
  final Widget actions;

  final String? photoUrl;

  /// The small line above the name: what kind of call this is.
  final String? caption;

  static const double _avatar = 132;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // A call takes the whole screen and the whole attention. A ring that
      // arrives as a banner over whatever was open is a ring that gets
      // dismissed by the tap the person was already making.
      backgroundColor: AppColors.primary900,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding.w),
          child: Column(
            children: [
              const Spacer(flex: 2),
              if (caption != null) ...[
                Text(
                  caption!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.rc(AppColors.primary100),
                ),
                AppSpacing.gapV(AppSpacing.lg),
              ],
              AppAvatar(
                imageUrl: photoUrl,
                name: name,
                size: _avatar,
                backgroundColor: AppColors.primary700,
                foregroundColor: AppColors.white,
              ),
              AppSpacing.gapV(AppSpacing.lg),
              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleLarge.rc(AppColors.white),
              ),
              AppSpacing.gapV(AppSpacing.xs),
              Text(
                status,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge.rc(AppColors.primary100),
              ),
              const Spacer(flex: 3),
              actions,
              AppSpacing.gapV(AppSpacing.xl2),
            ],
          ),
        ),
      ),
    );
  }
}

/// One round call action — answer, decline, hang up.
class CallActionButton extends StatelessWidget {
  const CallActionButton({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;

  /// Read out by screen readers and used by tests to find the button; a round
  /// icon with no text is otherwise unidentifiable to both.
  final String label;

  final VoidCallback onPressed;

  static const double _size = 72;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: color,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              child: SizedBox(
                width: _size.w,
                height: _size.w,
                child: Icon(icon, color: AppColors.white, size: 32.w),
              ),
            ),
          ),
          AppSpacing.gapV(AppSpacing.xs),
          Text(label, style: AppTextStyles.bodyMedium.rc(AppColors.primary100)),
        ],
      ),
    );
  }
}
