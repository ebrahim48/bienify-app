import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_radius.dart';
import '../../../../../../core/theme/app_spacing.dart';

/// The three dots the other party's bubble shows while they are writing.
///
/// The header already says `typing…` under their name, and that is easy to
/// miss: it sits where `Online` normally is, in the same weight and colour, so
/// nothing about the screen changes where the reader is actually looking. This
/// puts it at the end of the conversation, shaped like one of their messages,
/// which is where every chat app people already use puts it.
class TypingBubble extends StatefulWidget {
  const TypingBubble({super.key});

  @override
  State<TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<TypingBubble>
    with SingleTickerProviderStateMixin {
  /// One cycle for all three dots; each reads its own slice of it, so they
  /// rise in turn off a single ticker rather than three.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.base.w,
          vertical: AppSpacing.base.h,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl.r),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) => _Dot(_controller, index)),
        ),
      ),
    );
  }
}

/// One dot, lifting and fading a third of a cycle after the one before it.
class _Dot extends StatelessWidget {
  const _Dot(this.controller, this.index);

  final AnimationController controller;
  final int index;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // `1 - |2t - 1|` is a triangle: up for the first half of this dot's
        // turn, down for the second, so the three read as a wave.
        final t = (controller.value + index / 3) % 1.0;
        final rise = 1 - (2 * t - 1).abs();
        return Padding(
          padding: EdgeInsets.only(right: index == 2 ? 0 : 3.w),
          child: Transform.translate(
            offset: Offset(0, -3.h * rise),
            child: Opacity(opacity: 0.4 + 0.6 * rise, child: child),
          ),
        );
      },
      child: Container(
        width: 7.w,
        height: 7.w,
        decoration: const BoxDecoration(
          color: AppColors.gray500,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
