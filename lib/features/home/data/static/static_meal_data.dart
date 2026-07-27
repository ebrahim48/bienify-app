import '../models/meal_model.dart';

class StaticMealData {
  StaticMealData._();

  static const List<IngredientModel> _chickenIngredients = [
    IngredientModel(id: 'i1', name: 'Olive oil',       quantity: '1.6 tbsp', inPantry: true),
    IngredientModel(id: 'i2', name: 'Onion',           quantity: '1.6',       inPantry: false),
    IngredientModel(id: 'i3', name: 'Garlic',          quantity: '3.2 cloves',inPantry: true),
    IngredientModel(id: 'i4', name: 'Main protein',    quantity: '480g',      inPantry: false),
    IngredientModel(id: 'i5', name: 'Mixed vegetables',quantity: '384g',      inPantry: false),
    IngredientModel(id: 'i6', name: 'Stock',           quantity: '320ml',     inPantry: false),
    IngredientModel(id: 'i7', name: 'Seasoning',       quantity: '3.2 pinch', inPantry: false),
  ];

  static const List<String> _chickenMethod = [
    'Prep your ingredients: chop the onion and garlic, and measure everything out.',
    'Heat the olive oil in a large pan over medium heat. Add the onion and cook until soft, about 4–5 minutes.',
    'Add the garlic and your main protein. Cook until the protein is sealed and lightly browned.',
    'Stir in the vegetables and stock, season, then simmer until cooked through and the sauce has reduced.',
    'Taste, adjust seasoning, and serve. Enjoy!',
  ];

  static List<MealModel> getCurrentPlanMeals() => [
    MealModel(id: 'm1', name: 'Chicken Caesar Wraps', cookMinutes: 15, serves: 4,
        kcalPerAdult: 420, cost: 20, mealType: 'Breakfast',
        ingredients: _chickenIngredients, methodSteps: _chickenMethod),
    MealModel(id: 'm2', name: 'Chicken Caesar Wraps', cookMinutes: 15, serves: 4,
        kcalPerAdult: 420, cost: 20, mealType: 'Lunch',
        ingredients: _chickenIngredients, methodSteps: _chickenMethod),
    MealModel(id: 'm3', name: 'Chicken Caesar Wraps', cookMinutes: 15, serves: 4,
        kcalPerAdult: 420, cost: 20, mealType: 'Dinner',
        ingredients: _chickenIngredients, methodSteps: _chickenMethod),
  ];

  static double get weeklyBudget => 115.0;
  static double get estimatedCost => 140.0;
}
