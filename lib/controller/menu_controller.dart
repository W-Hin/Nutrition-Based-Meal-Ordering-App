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
      calories: 520,
      protein: 22,
      carbs: 36,
      fat: 34,
      fiber: 12,
      sodium: 550,
    ),
    Meal(
      name: 'Power Smoothie Bowl',
      price: 10.0,
      description: 'A vibrant bowl of blended fruits topped with fresh berries and bananas',
      imageUrl: 'assets/images/smoothie_bowl.png',
      categories: ['Breakfast', 'Snacks'],
      dietaryPreferences: ['Vegetarian', 'Vegan'],
      servingSize: '1 Bowl (400g)',
      calories: 250,
      protein: 5,
      carbs: 45,
      fat: 4,
      fiber: 8,
    ),
    Meal(
      name: 'Grilled Chicken Salad',
      price: 25.0,
      description: 'Lean grilled chicken with mixed greens and balsamic vinaigrette',
      imageUrl: 'assets/images/smoothie_bowl.png', // Placeholder
      categories: ['Lunch', 'Post-workout'],
      dietaryPreferences: ['Halal', 'Non-vegetarian'],
      servingSize: '1 Serving (450g)',
      calories: 400,
      protein: 35,
      carbs: 10,
      fat: 15,
      fiber: 6,
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
