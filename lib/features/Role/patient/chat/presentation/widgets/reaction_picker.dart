import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/app_strings.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_radius.dart';
import '../../../../../../core/theme/app_sizes.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../../../../core/utils/responsive.dart';
import '../../domain/entities/conversation.dart';

/// The reaction chooser: a quick row, with the full emoji keyboard behind it.
///
/// Both halves live in one sheet rather than two screens. Almost every
/// reaction is one of the handful in the row, and making that case a single
/// tap is the whole point; the "+" is there so the handful is never a ceiling.
class ReactionPicker extends StatefulWidget {
  const ReactionPicker({super.key, this.selected});

  /// What this user has already reacted with, highlighted so a second tap
  /// reads as removing it rather than setting the same thing again.
  final String? selected;

  /// Resolves to the chosen emoji, or to [ReactionPicker.clear] when the
  /// reader taps the reaction they already had. Null if dismissed.
  static Future<String?> show(BuildContext context, {String? selected}) =>
      showModalBottomSheet<String>(
        context: context,
        backgroundColor: AppColors.transparent,
        // The emoji keyboard is tall; without this it opens cramped into the
        // default third of the screen and scrolls a category at a time.
        isScrollControlled: true,
        builder: (_) => ReactionPicker(selected: selected),
      );

  /// Returned when the reader taps their existing reaction. Distinct from
  /// null, which means they dismissed the sheet without choosing.
  static const String clear = '';

  @override
  State<ReactionPicker> createState() => _ReactionPickerState();
}

class _ReactionPickerState extends State<ReactionPicker> {
  bool _showKeyboard = false;

  void _choose(String emoji) => Navigator.of(
    context,
    // Tapping the reaction you already have is how you take it back, which is
    // the gesture Messenger and Telegram both use.
  ).pop(emoji == widget.selected ? ReactionPicker.clear : emoji);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: EdgeInsets.all(AppSpacing.sm.w),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.rLg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _QuickRow(
                selected: widget.selected,
                onPick: _choose,
                isExpanded: _showKeyboard,
                onToggle: () =>
                    setState(() => _showKeyboard = !_showKeyboard),
              ),
              if (_showKeyboard)
                SizedBox(
                  // A fixed fraction rather than a fixed height: the keyboard
                  // needs to stay usable on a small phone without swallowing a
                  // tablet's whole screen.
                  height: MediaQuery.sizeOf(context).height * 0.42,
                  child: EmojiPicker(
                    onEmojiSelected: (_, emoji) => _choose(emoji.emoji),
                    config: Config(
                      emojiViewConfig: EmojiViewConfig(
                        emojiSizeMax: 28.sp,
                        backgroundColor: AppColors.surface,
                      ),
                      categoryViewConfig: CategoryViewConfig(
                        backgroundColor: AppColors.surface,
                        iconColorSelected: AppColors.primary600,
                        indicatorColor: AppColors.primary600,
                      ),
                      bottomActionBarConfig: const BottomActionBarConfig(
                        enabled: false,
                      ),
                      searchViewConfig: SearchViewConfig(
                        backgroundColor: AppColors.surface,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The shortcut row, plus the control that opens the full keyboard.
class _QuickRow extends StatelessWidget {
  const _QuickRow({
    required this.selected,
    required this.onPick,
    required this.isExpanded,
    required this.onToggle,
  });

  final String? selected;
  final ValueChanged<String> onPick;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: AppSpacing.sm.h,
        horizontal: AppSpacing.xs.w,
      ),
      child: Row(
        children: [
          // Scrolls rather than shrinking. Seven 26sp glyphs plus the "+" do
          // not fit a 390pt phone — the row overflowed by 18px — and the two
          // alternatives are worse: shrinking the emoji makes them hard to
          // hit, and wrapping to a second line pushes the keyboard toggle off
          // the row people are looking at. More shortcuts can be added here
          // without re-checking the arithmetic.
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final emoji in QuickReactions.emojis)
                    InkResponse(
                      onTap: () => onPick(emoji),
                      radius: 26.r,
                      child: Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs2.w,
                        ),
                        padding: EdgeInsets.all(AppSpacing.xs2.w),
                        decoration: BoxDecoration(
                          // A ring rather than a fill: the emoji has to stay
                          // the thing you read, and a coloured disc behind it
                          // fights the glyph.
                          shape: BoxShape.circle,
                          border: emoji == selected
                              ? Border.all(
                                  color: AppColors.primary600,
                                  width: AppSizes.borderWidth * 2,
                                )
                              : null,
                        ),
                        child: Text(emoji, style: TextStyle(fontSize: 26.sp)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Outside the scroll view: the way to every other emoji must not be
          // something you have to scroll to find.
          InkResponse(
            onTap: onToggle,
            radius: 26.r,
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xs.w),
              child: Icon(
                isExpanded
                    ? Icons.keyboard_arrow_down_rounded
                    : Icons.add_circle_outline_rounded,
                size: AppSizes.xl2.w,
                color: AppColors.textSecondary,
                semanticLabel: AppStrings.moreEmoji.tr,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The reactions a message has collected, pinned under its bubble.
class ReactionRow extends StatelessWidget {
  const ReactionRow({super.key, required this.reactions, this.myUserId});

  final List<MessageReaction> reactions;

  /// Whose reaction to mark as mine, so the row says whether I am in a count
  /// rather than only how large it is.
  final String? myUserId;

  @override
  Widget build(BuildContext context) {
    // Grouped, so three hearts read as one heart with a count rather than
    // three identical hearts in a row. Insertion-ordered, so the row does not
    // reshuffle itself every time somebody reacts.
    final counts = <String, int>{};
    var mine = false;
    for (final reaction in reactions) {
      final emoji = QuickReactions.resolve(reaction.emoji);
      counts[emoji] = (counts[emoji] ?? 0) + 1;
      if (reaction.userId == myUserId) mine = true;
    }

    return Transform.translate(
      offset: Offset(0, -AppSpacing.xs.h),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xs.w,
          vertical: AppSpacing.xs2.h,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.rFull,
          border: Border.all(
            color: mine ? AppColors.primary600 : AppColors.surfaceBorder,
            width: AppSizes.borderWidth,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in counts.entries) ...[
              Text(entry.key, style: TextStyle(fontSize: 13.sp)),
              if (entry.value > 1)
                Text(
                  ' ${entry.value}',
                  style: AppTextStyles.labelSmall.rc(AppColors.gray600),
                ),
              AppSpacing.gapH(AppSpacing.xs2),
            ],
          ],
        ),
      ),
    );
  }
}
