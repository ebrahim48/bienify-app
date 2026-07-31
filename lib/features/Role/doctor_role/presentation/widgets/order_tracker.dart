import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/utils/responsive.dart';
import '../../domain/entities/test_request.dart';

/// The five numbered steps an order passes through, connected by a rule.
///
/// Every circle up to [stage] is filled; the rest stay slate. The labels sit
/// under their circles and are allowed to wrap rather than be clipped.
class OrderTracker extends StatelessWidget {
  const OrderTracker({super.key, required this.stage});

  final OrderStage stage;

  static const double _circle = 20;

  /// Height the connecting rule sits at — the circle's centre.
  static const double _connector = 2;

  String _label(OrderStage value) => switch (value) {
    OrderStage.ordered => AppStrings.ordered.tr,
    OrderStage.facilitySelected => AppStrings.stepFacilitySelected.tr,
    OrderStage.testCompleted => AppStrings.stepTestCompleted.tr,
    OrderStage.resultsReceived => AppStrings.stepResultsReceived.tr,
    OrderStage.reviewed => AppStrings.reviewed.tr,
  };

  @override
  Widget build(BuildContext context) {
    final reached = OrderStage.values.indexOf(stage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (var index = 0; index < OrderStage.values.length; index++) ...[
              if (index > 0)
                Expanded(
                  child: Container(
                    height: _connector.h,
                    color: AppColors.stepTrack,
                  ),
                ),
              _Circle(number: index + 1, isReached: index <= reached),
            ],
          ],
        ),
        AppSpacing.gapV(AppSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < OrderStage.values.length; index++)
              Expanded(
                child: Text(
                  _label(OrderStage.values[index]),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  // Small enough that "Results Received" still gets its own
                  // line inside a fifth of the gutter, as the design sets it.
                  style: AppTextStyles.labelSmall.rw(
                    index <= reached ? AppColors.gray900 : AppColors.stepInk,
                    FontWeight.w400,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.number, required this.isReached});

  final int number;
  final bool isReached;

  @override
  Widget build(BuildContext context) {
    final side = OrderTracker._circle.w;

    return Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        color: isReached ? AppColors.actionFill : AppColors.stepSurface,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: AppTextStyles.labelMedium.rc(
          isReached ? AppColors.white : AppColors.stepInk,
        ),
      ),
    );
  }
}
