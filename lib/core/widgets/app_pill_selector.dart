import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';

/// A row of pills, exactly one of which is filled.
///
/// The designs use this shape in two sizes: a large two-option segmented
/// control ("Lab Reports | Radiology Reports", "Your Prescriptions | Your
/// Medical vault") and a smaller filter row ("all · Active Orders · …",
/// "All · Delivered · Pending · Cancelled").
///
/// Wraps by default. The designs keep every option on one line and on a wide
/// phone this still does — but the widest sets do not fit at 320pt, and a
/// wrapped row is readable at every width.
///
/// Pass [isScrollable] where the design calls for one line whatever the width:
/// the pills then sit in a single horizontally scrolling row. The trade is the
/// one wrapping avoids — an option past the right edge with nothing to say it
/// is there — so this is opt-in rather than the default.
///
/// Pass [fillsWidth] for a short fixed set that must stay on one line with
/// every option visible: when the row would overrun, every label is scaled
/// down by the same factor, rather than one being clipped or scrolled away.
///
/// ```dart
/// Obx(() => AppPillSelector(
///   labels: [for (final t in Tab.values) t.label],
///   selectedIndex: Tab.values.indexOf(controller.tab.value),
///   onSelected: (i) => controller.select(Tab.values[i]),
///   isLarge: true,
/// ))
/// ```
class AppPillSelector extends StatelessWidget {
  const AppPillSelector({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.isLarge = false,
    this.isScrollable = false,
    this.isCompact = false,
    this.fillsWidth = false,
    this.horizontalPadding = AppSpacing.base,
    this.unselectedFill = AppColors.surface,
    this.unselectedInk = AppColors.gray900,
    this.unselectedBorder = AppColors.surfaceBorder,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Segmented controls sit a size up from filter chips.
  final bool isLarge;

  /// Keeps every pill on one line, scrolling sideways instead of wrapping.
  final bool isScrollable;

  /// 14pt labels instead of 16 — the Orders tab's six states, which the
  /// design draws a size down so more of the row shows before it scrolls.
  final bool isCompact;

  /// One line, every option on screen, at the smaller filter size. Takes
  /// precedence over [isScrollable].
  final bool fillsWidth;

  /// Inset each side of a label. Results to Review's three segments only fit
  /// a 390pt frame at the design's tighter 12pt; everywhere else keeps 16.
  final double horizontalPadding;

  /// How an unselected pill is drawn. The default is the outlined white one
  /// every screen uses; Results to Review's second row fills them slate
  /// instead, which is the only place the design departs.
  final Color unselectedFill;
  final Color unselectedInk;
  final Color unselectedBorder;

  @override
  Widget build(BuildContext context) {
    if (fillsWidth) return _fittedRow(context);

    final pills = [
      for (var index = 0; index < labels.length; index++)
        _Pill(
          label: labels[index],
          isSelected: index == selectedIndex,
          isLarge: isLarge,
          isCompact: isCompact,
          horizontalPadding: horizontalPadding,
          fill: unselectedFill,
          ink: unselectedInk,
          border: unselectedBorder,
          onTap: () => onSelected(index),
        ),
    ];

    if (!isScrollable) {
      return Wrap(
        spacing: AppSpacing.xs.w,
        runSpacing: AppSpacing.xs.h,
        children: pills,
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < pills.length; index++) ...[
            if (index > 0) AppSpacing.gapH(AppSpacing.xs),
            pills[index],
          ],
        ],
      ),
    );
  }
}

extension on AppPillSelector {
  /// Measures every label, then shrinks them all by one factor if the row
  /// would overrun — so "New Request" is not left full size beside two
  /// squeezed neighbours.
  Widget _fittedRow(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        // Resolved as the pill resolves it, `.sp` included; colour does not
        // change the width.
        final style = _Pill.styleFor(
          isLarge: isLarge,
          isCompact: true,
        ).rc(unselectedInk);
        final widths = [
          for (final label in labels)
            (TextPainter(
              text: TextSpan(text: label, style: style),
              textScaler: textScaler,
              textDirection: direction,
              maxLines: 1,
            )..layout()).width,
        ];
        final textWidth = widths.fold<double>(0, (sum, w) => sum + w);
        final chrome =
            labels.length * (horizontalPadding.w + AppSizes.borderWidth) * 2 +
            (labels.length - 1) * AppSpacing.xs.w;
        final room = constraints.maxWidth - chrome;
        // Floored so sub-pixel rounding cannot tip the row over.
        final scale = textWidth <= room ? 1.0 : (room - 1) / textWidth;

        return Row(
          children: [
            for (var index = 0; index < labels.length; index++) ...[
              if (index > 0) AppSpacing.gapH(AppSpacing.xs),
              _Pill(
                label: labels[index],
                isSelected: index == selectedIndex,
                isLarge: isLarge,
                isCompact: true,
                horizontalPadding: horizontalPadding,
                fill: unselectedFill,
                ink: unselectedInk,
                border: unselectedBorder,
                fittedWidth: widths[index] * scale,
                onTap: () => onSelected(index),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.isSelected,
    required this.isLarge,
    required this.isCompact,
    required this.horizontalPadding,
    required this.fill,
    required this.ink,
    required this.border,
    required this.onTap,
    this.fittedWidth,
  });

  final String label;
  final bool isSelected;
  final bool isLarge;
  final bool isCompact;
  final double horizontalPadding;
  final Color fill;
  final Color ink;
  final Color border;
  final VoidCallback onTap;

  /// Set in a [AppPillSelector.fillsWidth] row: the label is fitted into this
  /// width. Scaling the painted label rather than its font size keeps
  /// the shrink exactly proportional — glyph advances do not shrink linearly
  /// with the size, which let the row overrun.
  final double? fittedWidth;

  static TextStyle styleFor({required bool isLarge, required bool isCompact}) =>
      isLarge
      ? AppTextStyles.titleSmall
      : isCompact
      ? AppTextStyles.bodyMedium
      : AppTextStyles.bodyLarge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.actionFill : fill,
      borderRadius: AppRadius.rFull,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding.w,
            vertical: isLarge ? AppSpacing.sm.h : AppSpacing.xs.h,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.rFull,
            border: Border.all(
              color: isSelected ? AppColors.transparent : border,
              width: AppSizes.borderWidth,
            ),
          ),
          // Both sizes set 16pt type in the designs; the segmented control is
          // taller and bolder, not wider-set.
          child: _label(),
        ),
      ),
    );
  }

  Widget _label() {
    final text = Text(
      label,
      maxLines: 1,
      softWrap: false,
      style: styleFor(
        isLarge: isLarge,
        isCompact: isCompact,
      ).rc(isSelected ? AppColors.white : ink),
    );
    if (fittedWidth == null) return text;
    return SizedBox(
      width: fittedWidth,
      child: FittedBox(fit: BoxFit.scaleDown, child: text),
    );
  }
}
