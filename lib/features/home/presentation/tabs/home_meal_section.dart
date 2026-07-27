import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../data/models/meal_model.dart';
import '../controllers/home_controller.dart';
import '../widgets/home_meal_context_menu.dart';
import '../../../../features/meal/presentation/screens/recipe_detail_screen.dart'
    as meal_detail;
import '../../../../features/meal/presentation/controllers/meal_controller.dart';
import '../../../../features/meal/data/models/cookbook_meal_model.dart';

class HomeMealSection extends StatelessWidget {
  const HomeMealSection(
      {super.key, required this.title, required this.meals});
  final String title;
  final List<MealModel> meals;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 8),
      Text(
        '$title (${meals.length.toString().padLeft(2, '0')})',
        style: AppTextStyles.sub2,
      ),
      const SizedBox(height: 10),
      ...meals.map((meal) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _HomeMealCard(meal: meal),
          )),
    ]);
  }
}

class _HomeMealCard extends StatelessWidget {
  const _HomeMealCard({required this.meal});
  final MealModel meal;

  static const List<CookbookIngredient> _defaultIngredients = [
    CookbookIngredient(id: 'i1', name: 'Olive oil',        quantity: '1.6 tbsp'),
    CookbookIngredient(id: 'i2', name: 'Onion',            quantity: '1.6'),
    CookbookIngredient(id: 'i3', name: 'Garlic',           quantity: '3.2 cloves'),
    CookbookIngredient(id: 'i4', name: 'Main protein',     quantity: '480g'),
    CookbookIngredient(id: 'i5', name: 'Mixed vegetables', quantity: '384g'),
    CookbookIngredient(id: 'i6', name: 'Stock',            quantity: '320ml'),
    CookbookIngredient(id: 'i7', name: 'Seasoning',        quantity: '3.2 pinch'),
  ];

  static const List<String> _defaultMethod = [
    'Prep your ingredients: chop the onion and garlic, and measure everything out.',
    'Heat the olive oil in a large pan over medium heat. Add the onion and cook until soft, about 4–5 minutes.',
    'Add the garlic and your main protein. Cook until the protein is sealed and lightly browned.',
    'Stir in the vegetables and stock, season, then simmer until cooked through and the sauce has reduced.',
    'Taste, adjust seasoning, and serve. Enjoy!',
  ];

  @override
  Widget build(BuildContext context) {
    final homeCtrl = Get.find<HomeController>();
    return GestureDetector(
      onTap: () {
        final mealCtrl = Get.find<MealController>();
        final cbMeal = CookbookMealModel(
          id: meal.id,
          name: meal.name,
          mealType: meal.mealType,
          cookMinutes: meal.cookMinutes,
          cookedCount: 0,
          serves: meal.serves,
          kcalPerAdult: meal.kcalPerAdult,
          ingredients: _defaultIngredients,
          methodSteps: _defaultMethod,
        );
        mealCtrl.selectMeal(cbMeal);
        Get.to(() => const meal_detail.RecipeDetailScreen());
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(meal.name, style: AppTextStyles.sub3),
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.access_time_rounded,
                    size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('${meal.cookMinutes}m · serves ${meal.serves}',
                    style: AppTextStyles.body4.copyWith(
                        color: AppColors.textSecondary)),
              ]),
            ]),
          ),
          Text('\$${meal.cost.round()}', style: AppTextStyles.sub2),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (_) => HomeMealContextMenu(meal: meal),
            ),
            child: const Icon(Icons.more_vert_rounded,
                size: 18, color: AppColors.textSecondary),
          ),
        ]),
      ),
    );
  }
}
