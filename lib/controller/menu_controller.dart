import 'package:flutter/material.dart';
import '../model/meal_model.dart';
import '../service/meal_service.dart';

class FoodMenuController extends ChangeNotifier {
  List<Meal> _allMeals = [];
  bool _isLoading = false;
  String? _lastFetchedStoreId;

  FoodMenuController() {
    // Initial fetch handled by ProxyProvider or UI
  }

  bool get isLoading => _isLoading;
  List<Meal> get meals => _allMeals;

  /// Fetch meals for a specific store. 
  /// If storeId is null, it refreshes the last fetched store.
  Future<void> fetchMeals({String? storeId}) async {
    final targetStoreId = storeId ?? _lastFetchedStoreId;

    // Prevent redundant fetches only if we are browsing (storeId != null) and the ID hasn't changed.
    if (storeId != null && storeId == _lastFetchedStoreId && _allMeals.isNotEmpty) return;
    
    _lastFetchedStoreId = targetStoreId;
    _isLoading = true;
    notifyListeners(); 
    
    try {
      _allMeals = await MealService.fetchMeals(storeId: targetStoreId);
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
