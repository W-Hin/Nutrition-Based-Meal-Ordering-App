import 'package:flutter/material.dart';
import '../model/ingredient_model.dart';
import '../service/ingredient_service.dart';

class BowlController extends ChangeNotifier {
  
  int _currentStep = 0;
  Ingredient? _selectedBase;
  final Map<Ingredient, int> _selectedProteins = {};
  final Map<Ingredient, int> _selectedVeggies = {};
  Ingredient? _selectedSauce;

  bool _isLoading = false;
  String? _error;

  List<Ingredient> _allIngredients = [];

  int get currentStep => _currentStep;
  Ingredient? get selectedBase => _selectedBase;
  Map<Ingredient, int> get selectedProteins => _selectedProteins;
  Map<Ingredient, int> get selectedVeggies => _selectedVeggies;
  Ingredient? get selectedSauce => _selectedSauce;
  
  bool get isLoading => _isLoading;
  String? get error => _error;

  final List<String> steps = ['Base', 'Protein', 'Veggies', 'Sauce'];
  final List<String> stepTitles = ['Choose Base', 'Choose Proteins', 'Choose Veggies', 'Choose Sauce'];

  // Categorized lists
  // Categorized lists (Includes out-of-stock items, sorted to bottom)
  List<Ingredient> get bases => _getSortedCategory(IngredientType.base);
  List<Ingredient> get proteins => _getSortedCategory(IngredientType.protein);
  List<Ingredient> get veggiesList => _getSortedCategory(IngredientType.veggies);
  List<Ingredient> get sauces => _getSortedCategory(IngredientType.sauce);

  List<Ingredient> _getSortedCategory(IngredientType type) {
    final filtered = _allIngredients.where((i) => i.type == type).toList();
    // Sort: available first, then out of stock
    filtered.sort((a, b) {
      if (a.isAvailable && !b.isAvailable) return -1;
      if (!a.isAvailable && b.isAvailable) return 1;
      return 0;
    });
    return filtered;
  }

  Future<void> loadIngredients(String storeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allIngredients = await IngredientService.fetchIngredients(storeId: storeId);
      _isLoading = false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
    }
    notifyListeners();
  }

  int get totalCalories {
    int calories = 0;
    if (_selectedBase != null) calories += _selectedBase!.calories;
    _selectedProteins.forEach((item, qty) => calories += item.calories * qty);
    _selectedVeggies.forEach((item, qty) => calories += item.calories * qty);
    if (_selectedSauce != null) calories += _selectedSauce!.calories;
    return calories;
  }

  double get totalPrice {
    double price = 0;
    if (_selectedBase != null) price += _selectedBase!.price;
    _selectedProteins.forEach((item, qty) => price += item.price * qty);
    _selectedVeggies.forEach((item, qty) => price += item.price * qty);
    if (_selectedSauce != null) price += _selectedSauce!.price;
    return price;
  }

  Map<String, double> get totalNutrition {
    Map<String, double> totals = {
      'Protein': 0,
      'Carbs': 0,
      'Fats': 0,
      'Fiber': 0,
    };

    void aggregate(Ingredient ingredient, int qty) {
      totals['Protein'] = totals['Protein']! + (ingredient.protein * qty);
      totals['Carbs'] = totals['Carbs']! + (ingredient.carbs * qty);
      totals['Fats'] = totals['Fats']! + (ingredient.fat * qty);
      totals['Fiber'] = totals['Fiber']! + (ingredient.fiber * qty);
    }

    if (_selectedBase != null) aggregate(_selectedBase!, 1);
    _selectedProteins.forEach((item, qty) => aggregate(item, qty));
    _selectedVeggies.forEach((item, qty) => aggregate(item, qty));
    if (_selectedSauce != null) aggregate(_selectedSauce!, 1);

    return totals;
  }

  int getIngredientQuantity(Ingredient ingredient) {
    if (ingredient.type == IngredientType.protein) return _selectedProteins[ingredient] ?? 0;
    if (ingredient.type == IngredientType.veggies) return _selectedVeggies[ingredient] ?? 0;
    return 0;
  }

  void updateQuantity(Ingredient ingredient, int delta) {
    final map = ingredient.type == IngredientType.protein ? _selectedProteins : _selectedVeggies;
    final current = map[ingredient] ?? 0;
    final newValue = current + delta;
    
    if (newValue <= 0) {
      map.remove(ingredient);
    } else {
      map[ingredient] = newValue;
    }
    notifyListeners();
  }

  void selectBase(Ingredient base) {
    _selectedBase = base;
    notifyListeners();
  }

  void selectSauce(Ingredient sauce) {
    if (_selectedSauce == sauce) {
      _selectedSauce = null;
    } else {
      _selectedSauce = sauce;
    }
    notifyListeners();
  }

  void nextStep() {
    if (_currentStep < steps.length - 1) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  void reset() {
    _currentStep = 0;
    _selectedBase = null;
    _selectedProteins.clear();
    _selectedVeggies.clear();
    _selectedSauce = null;
    notifyListeners();
  }

  bool get canGoNext {
    if (_currentStep == 0) return _selectedBase != null;
    if (_currentStep == 1) return _selectedProteins.isNotEmpty;
    if (_currentStep == 2) return _selectedVeggies.isNotEmpty;
    if (_currentStep == 3) return true;
    return true; 
  }
}
