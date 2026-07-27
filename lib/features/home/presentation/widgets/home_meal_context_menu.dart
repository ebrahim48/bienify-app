import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../data/models/meal_model.dart';
import '../controllers/home_controller.dart';

class HomeMealContextMenu extends StatelessWidget {
  const HomeMealContextMenu({super.key, required this.meal});
  final MealModel meal;

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HomeController>();
    final otherTypes = ['Breakfast', 'Lunch', 'Dinner']
        .where((t) => t != meal.mealType)
        .toList();

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        ...otherTypes.map((type) => _MenuItem(
              icon: Icons.arrow_forward_rounded,
              label: 'Move to $type',
              onTap: () {
                Get.back();
                ctrl.moveMeal(meal.id, type);
              },
            )),
        Divider(height: 1, color: AppColors.border,
            indent: 20, endIndent: 20),
        _MenuItem(
          emoji: '📅',
          label: 'Assign a day',
          onTap: () => Get.back(),
        ),
        _MenuItem(
          icon: Icons.refresh_rounded,
          label: 'Swap meal',
          onTap: () => Get.back(),
        ),
        _MenuItem(
          emoji: '🗑',
          label: 'Remove from plan',
          labelColor: AppColors.error,
          onTap: () {
            Get.back();
            Future.microtask(() => _showRemoveDialog(meal, ctrl));
          },
        ),
        const SizedBox(height: 8),
      ]),
    );
  }

  void _showRemoveDialog(MealModel meal, HomeController ctrl) {
    Get.dialog(
      Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🗑', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 16),
            Text('Remove this meal?',
                style: AppTextStyles.h5, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              '${meal.name} will be removed from your plan.',
              style: AppTextStyles.body2
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  ctrl.removeMeal(meal.id);
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text('Remove', style: AppTextStyles.buttonLabel),
              ),
            ),
            TextButton(
              onPressed: () => Get.back(),
              child: Text('Cancel',
                  style: AppTextStyles.sub2
                      .copyWith(color: AppColors.textSecondary)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    this.icon,
    this.emoji,
    required this.label,
    this.labelColor,
    required this.onTap,
  });
  final IconData? icon;
  final String? emoji;
  final String label;
  final Color? labelColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        child: Row(children: [
          SizedBox(
            width: 24,
            child: emoji != null
                ? Text(emoji!, style: const TextStyle(fontSize: 18))
                : Icon(icon, size: 20,
                    color: labelColor ?? AppColors.primary),
          ),
          const SizedBox(width: 16),
          Text(label,
              style: AppTextStyles.sub2.copyWith(
                  color: labelColor ?? AppColors.primary)),
        ]),
      ),
    );
  }
}
