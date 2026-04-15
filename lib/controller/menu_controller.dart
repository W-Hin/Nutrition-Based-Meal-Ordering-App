import 'package:flutter/material.dart';
import '../model/meal_model.dart';

class FoodMenuController extends ChangeNotifier {
  final List<Meal> _allMeals = [
    Meal(
      name: 'Avocado Toast',
      price: 20.0,
      description: 'Fresh avocado on sourdough with poached eggs',
      imageUrl: 'assets/images/avocado_toast.png',
      categories: ['Breakfast'],
      dietaryPreferences: ['Vegetarian'],
      servingSize: '1 Set (340g)',
      nutritionData: {
        'Calories': '520 cal',
        'Protein': '22 g',
        'Carbs': '36 g',
        'Fat': '34 g',
        'Fiber': '12 g',
        'Sodium': '550 mg',
      },
    ),
    Meal(
      name: 'Power Smoothie Bowl',
      price: 10.0,
      description: 'A vibrant bowl of blended fruits topped with fresh berries and bananas',
      imageUrl: 'assets/images/smoothie_bowl.png',
      categories: ['Breakfast', 'Snacks'],
      dietaryPreferences: ['Vegetarian', 'Vegan'],
      servingSize: '1 Bowl (400g)',
      nutritionData: {
        'Calories': '250 cal',
        'Protein': '5 g',
        'Carbs': '45 g',
        'Fat': '4 g',
        'Fiber': '8 g',
      },
    ),
    Meal(
      name: 'Grilled Chicken Salad',
      price: 25.0,
      description: 'Lean grilled chicken with mixed greens and balsamic vinaigrette',
      imageUrl: 'assets/images/smoothie_bowl.png', // Placeholder
      categories: ['Lunch', 'Post-workout'],
      dietaryPreferences: ['Halal', 'Non-vegetarian'],
      servingSize: '1 Serving (450g)',
      nutritionData: {
        'Calories': '400 cal',
        'Protein': '35 g',
        'Carbs': '10 g',
        'Fat': '15 g',
        'Fiber': '6 g',
      },
    ),
  ];

  String _selectedCategory = 'All';
  String _selectedDietaryPreference = 'All';

  String get selectedCategory => _selectedCategory;
  String get selectedDietaryPreference => _selectedDietaryPreference;

  List<Meal> get meals => _allMeals;

  List<Meal> get filteredMeals {
    return _allMeals.where((meal) {
      final categoryMatch = meal.hasCategory(_selectedCategory);
      final dietaryMatch = meal.hasDietaryPreference(_selectedDietaryPreference);
      return categoryMatch && dietaryMatch;
    }).toList();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setDietaryPreference(String preference) {
    _selectedDietaryPreference = preference;
    notifyListeners();
  }

  void clearFilters() {
    _selectedCategory = 'All';
    _selectedDietaryPreference = 'All';
    notifyListeners();
  }
}
