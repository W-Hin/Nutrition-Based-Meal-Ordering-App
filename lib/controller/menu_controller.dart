import 'package:flutter/material.dart';
import '../model/meal_model.dart';
import '../service/meal_service.dart';

class FoodMenuController extends ChangeNotifier {
  List<Meal> _allMeals = [];
  bool _isLoading = false;

  FoodMenuController() {
    fetchMeals(); // background fetch
  }

  bool get isLoading => _isLoading;
  List<Meal> get meals => _allMeals;

  Future<void> fetchMeals() async {
    _isLoading = true;
    try {
      _allMeals = await MealService.fetchMeals();
    } catch (e) {
      debugPrint('Error fetching meals: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _selectedCategory = 'All';
  String _selectedDietaryPreference = 'All';

  String get selectedCategory => _selectedCategory;
  String get selectedDietaryPreference => _selectedDietaryPreference;

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
