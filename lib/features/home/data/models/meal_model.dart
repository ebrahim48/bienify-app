class MealModel {
  final String id;
  final String name;
  final int cookMinutes;
  final int serves;
  final int kcalPerAdult;
  final double cost;
  final String mealType; // 'Breakfast' | 'Lunch' | 'Dinner'
  final List<IngredientModel> ingredients;
  final List<String> methodSteps;
  final String imagePath;

  const MealModel({
    required this.id,
    required this.name,
    required this.cookMinutes,
    required this.serves,
    required this.kcalPerAdult,
    required this.cost,
    required this.mealType,
    required this.ingredients,
    required this.methodSteps,
    this.imagePath = '',
  });
}

class IngredientModel {
  final String id;
  final String name;
  final String quantity;
  final bool inPantry;

  const IngredientModel({
    required this.id,
    required this.name,
    required this.quantity,
    required this.inPantry,
  });
}
