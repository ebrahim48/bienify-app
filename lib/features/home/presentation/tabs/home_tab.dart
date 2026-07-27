import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../controllers/home_controller.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/weekly_cost_card.dart';
import '../widgets/shopping_list_button.dart';
import 'home_meal_section.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HomeController>();
    return SafeArea(
      child: Column(children: [
        const HomeAppBar(),
        Expanded(
          child: Obx(() => ctrl.showingNextPlan.value
              ? _NextPlanView(ctrl: ctrl)
              : _CurrentPlanView(ctrl: ctrl)),
        ),
      ]),
    );
  }
}

// ── Current Plan ──────────────────────────────────────────────────────────────
class _CurrentPlanView extends StatelessWidget {
  const _CurrentPlanView({required this.ctrl});
  final HomeController ctrl;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning,'
        : hour < 17
            ? 'Good afternoon,'
            : 'Good evening,';

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const SizedBox(height: 20),
        Text('OVERVIEW',
            style: AppTextStyles.sub4.copyWith(
                color: AppColors.textSecondary, letterSpacing: 1.2)),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: AppTextStyles.h3.copyWith(height: 1.2),
            children: [
              TextSpan(
                  text: '$greeting\n',
                  style: AppTextStyles.h3
                      .copyWith(fontWeight: FontWeight.w500)),
              const TextSpan(text: 'Bashar'),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Obx(() => Text(
              'You have ${ctrl.totalMeals} meals upcoming in this plan.',
              style: AppTextStyles.body3
                  .copyWith(color: AppColors.textSecondary),
            )),
        const SizedBox(height: 16),
        const WeeklyCostCard(),
        const SizedBox(height: 12),
        const ShoppingListButton(),
        const SizedBox(height: 20),

        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('CURRENT PLAN',
              style: AppTextStyles.sub4.copyWith(
                  color: AppColors.textSecondary, letterSpacing: 1.2)),
          GestureDetector(
            onTap: ctrl.togglePlanView,
            child: Text('Next plan →',
                style: AppTextStyles.body3
                    .copyWith(color: AppColors.primary)),
          ),
        ]),
        const SizedBox(height: 16),

        Obx(() => Column(children: [
              if (ctrl.breakfastMeals.isNotEmpty)
                HomeMealSection(
                    title: 'Breakfast', meals: ctrl.breakfastMeals),
              if (ctrl.lunchMeals.isNotEmpty)
                HomeMealSection(
                    title: 'Lunch', meals: ctrl.lunchMeals),
              if (ctrl.dinnerMeals.isNotEmpty)
                HomeMealSection(
                    title: 'Dinner', meals: ctrl.dinnerMeals),
            ])),

        const SizedBox(height: 16),
        AppButton(
          label: 'View next plan →',
          variant: AppButtonVariant.secondary,
          onPressed: ctrl.togglePlanView,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Next Plan ─────────────────────────────────────────────────────────────────
class _NextPlanView extends StatelessWidget {
  const _NextPlanView({required this.ctrl});
  final HomeController ctrl;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const SizedBox(height: 20),
        Text('OVERVIEW',
            style: AppTextStyles.sub4.copyWith(
                color: AppColors.textSecondary, letterSpacing: 1.2)),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: AppTextStyles.h3.copyWith(height: 1.2),
            children: [
              TextSpan(
                  text: 'Good morning,\n',
                  style: AppTextStyles.h3
                      .copyWith(fontWeight: FontWeight.w500)),
              const TextSpan(text: 'Bashar'),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text('No meals planned yet.',
            style: AppTextStyles.body3
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        const WeeklyCostCard(isEmpty: true),
        const SizedBox(height: 12),
        const ShoppingListButton(),
        const SizedBox(height: 20),

        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('NEXT PLAN',
              style: AppTextStyles.sub4.copyWith(
                  color: AppColors.textSecondary, letterSpacing: 1.2)),
          GestureDetector(
            onTap: ctrl.togglePlanView,
            child: Text('← Current plan',
                style: AppTextStyles.body3
                    .copyWith(color: AppColors.primary)),
          ),
        ]),
        const SizedBox(height: 40),

        Center(
          child: Column(children: [
            const Text('📅', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text("Your next plan's a blank slate",
                style: AppTextStyles.sub1, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              "Plan a fresh set of meals to your budget —\nthen build your shopping list from it.",
              style: AppTextStyles.body2
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ]),
        ),
        const SizedBox(height: 32),

        AppButton(
          label: 'Plan my next meals →',
          onPressed: () => Get.toNamed(AppRoutes.planNextMeals),
        ),
        const SizedBox(height: 12),
        AppButton(
          label: '← Back to current plan',
          variant: AppButtonVariant.secondary,
          onPressed: ctrl.togglePlanView,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
