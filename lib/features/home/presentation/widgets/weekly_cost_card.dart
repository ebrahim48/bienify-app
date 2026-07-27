import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../controllers/home_controller.dart';

class WeeklyCostCard extends StatelessWidget {
  const WeeklyCostCard({super.key, this.isEmpty = false});
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HomeController>();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Builder(builder: (context) {
        final cost = isEmpty ? 0.0 : ctrl.estimatedCost;
        final budget = ctrl.weeklyBudget;
        final diff = cost - budget;
        final isOver = diff > 0;
        final progress = isEmpty ? 0.0 : (cost / budget).clamp(0.0, 1.5);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEmpty ? 'EST. WEEKLY COST' : 'Est. weekly cost',
              style: AppTextStyles.sub4.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: isEmpty ? 1.2 : 0,
              ),
            ),
            const SizedBox(height: 6),
            Row(children: [
              RichText(
                text: TextSpan(
                  style: AppTextStyles.h3,
                  children: [
                    TextSpan(text: '\$${cost.round()}'),
                    TextSpan(
                      text: ' / \$${budget.round()}',
                      style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (!isEmpty)
                Text(
                  isOver
                      ? '\$${diff.round()} over'
                      : '\$${(-diff).round()} under',
                  style: AppTextStyles.body3.copyWith(
                    color: isOver ? AppColors.error : AppColors.brand,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ]),
            const SizedBox(height: 12),

            // Progress bar — w:338 h:4 border-radius:4
            LayoutBuilder(builder: (ctx, c) {
              return Stack(children: [
                Container(
                  width: c.maxWidth, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: (c.maxWidth * progress).clamp(0.0, c.maxWidth),
                  height: 4,
                  decoration: BoxDecoration(
                    color: isOver ? AppColors.error : AppColors.brand,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ]);
            }),
          ],
        );
      }),
    );
  }
}
