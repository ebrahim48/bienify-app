import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../data/static/doctor_practice_data.dart';
import '../../domain/entities/doctor_practice.dart';

/// The weekly appointments bar chart.
///
/// Drawn with widgets rather than a charting package: it is seven bars against
/// a fixed axis, and a dependency for that would be heavier than the layout it
/// replaces. Each bar takes its colour from [AppColors.chartBars] by position,
/// which is how the design cycles them.
class AppointmentsChart extends StatelessWidget {
  const AppointmentsChart({
    super.key,
    required this.load,
    this.maxValue = DoctorPracticeData.chartMax,
    this.divisions = DoctorPracticeData.chartDivisions,
  });

  final List<DayLoad> load;

  /// Top of the y-axis. The gridlines divide 0..[maxValue] evenly.
  final int maxValue;
  final int divisions;

  static const double _plotHeight = 180;
  static const double _axisWidth = 26;
  static const double _barWidth = 26;

  @override
  Widget build(BuildContext context) {
    // Descending so the labels read top-down, 60 … 0.
    final ticks = [
      for (var i = divisions; i >= 0; i--) maxValue * i ~/ divisions,
    ];

    return Column(
      children: [
        SizedBox(
          height: _plotHeight.h,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: _axisWidth.w,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final tick in ticks)
                      Text(
                        '$tick',
                        style: AppTextStyles.bodySmall.rc(AppColors.gray400),
                      ),
                  ],
                ),
              ),
              AppSpacing.gapH(AppSpacing.xs),
              Expanded(
                child: Stack(
                  children: [
                    // Gridlines sit behind the bars, aligned with the ticks by
                    // sharing the same `spaceBetween` distribution.
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (var i = 0; i < ticks.length; i++)
                          Container(
                            height: AppSizes.borderWidth,
                            color: AppColors.surfaceBorder,
                          ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        for (var i = 0; i < load.length; i++)
                          _Bar(
                            fraction: (load[i].count / maxValue).clamp(0, 1),
                            color: AppColors
                                .chartBars[i % AppColors.chartBars.length],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        AppSpacing.gapV(AppSpacing.xs),
        Row(
          children: [
            SizedBox(width: (_axisWidth + AppSpacing.xs).w),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (final day in load)
                    SizedBox(
                      width: _barWidth.w,
                      child: Text(
                        day.dayLabel,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.rc(AppColors.gray600),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.fraction, required this.color});

  /// 0..1 of the plot height.
  final num fraction;

  final Color color;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: fraction.toDouble(),
      alignment: Alignment.bottomCenter,
      child: Container(
        width: AppointmentsChart._barWidth.w,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.vertical(top: AppRadius.rSm.topLeft),
        ),
      ),
    );
  }
}
