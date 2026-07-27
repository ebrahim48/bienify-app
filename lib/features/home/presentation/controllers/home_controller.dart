import 'package:get/get.dart';
import '../../data/models/meal_model.dart';
import '../../data/static/static_meal_data.dart';

class HomeController extends GetxController {
  // Bottom nav
  final RxInt currentTab = 0.obs;

  // Plan view toggle
  final RxBool showingNextPlan = false.obs;

  // Meals
  final RxList<MealModel> meals = <MealModel>[].obs;

  // Budget
  double get weeklyBudget => StaticMealData.weeklyBudget;
  double get estimatedCost => StaticMealData.estimatedCost;
  bool get isOverBudget => estimatedCost > weeklyBudget;

  // Grouped
  List<MealModel> get breakfastMeals =>
      meals.where((m) => m.mealType == 'Breakfast').toList();
  List<MealModel> get lunchMeals =>
      meals.where((m) => m.mealType == 'Lunch').toList();
  List<MealModel> get dinnerMeals =>
      meals.where((m) => m.mealType == 'Dinner').toList();

  int get totalMeals => meals.length;

  @override
  void onInit() {
    super.onInit();
    meals.value = StaticMealData.getCurrentPlanMeals();
  }

  void switchTab(int index) => currentTab.value = index;
  void togglePlanView() => showingNextPlan.toggle();

  void removeMeal(String id) =>
      meals.removeWhere((m) => m.id == id);

  void moveMeal(String id, String newType) {
    final idx = meals.indexWhere((m) => m.id == id);
    if (idx != -1) {
      final m = meals[idx];
      meals[idx] = MealModel(
        id: m.id, name: m.name, cookMinutes: m.cookMinutes,
        serves: m.serves, kcalPerAdult: m.kcalPerAdult, cost: m.cost,
        mealType: newType, ingredients: m.ingredients,
        methodSteps: m.methodSteps, imagePath: m.imagePath,
      );
    }
  }
}
