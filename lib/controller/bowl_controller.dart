import 'package:flutter/material.dart';
import '../model/ingredient_model.dart';

class BowlController extends ChangeNotifier {
  int _currentStep = 0;
  Ingredient? _selectedBase;
  final Map<Ingredient, int> _selectedProteins = {};
  final Map<Ingredient, int> _selectedVeggies = {};
  Ingredient? _selectedSauce;

  int get currentStep => _currentStep;
  Ingredient? get selectedBase => _selectedBase;
  Map<Ingredient, int> get selectedProteins => _selectedProteins;
  Map<Ingredient, int> get selectedVeggies => _selectedVeggies;
  Ingredient? get selectedSauce => _selectedSauce;

  final List<String> steps = ['Rice', 'Protein', 'Veggies', 'Sauce'];
  final List<String> stepTitles = ['Choose Base', 'Choose Protein', 'Choose Veggies', 'Choose Sauce'];

  // Default Nutrition Data for mocking
  static const Map<String, String> _defaultNutrition = {
    'Carbs': '5g',
    'Fats': '2g',
    'Sugar': '1g',
    'Protein': '1g',
    'Fiber': '2g',
    'Sodium': '50mg',
    'Cholesterol': '0mg',
  };

  final List<Ingredient> bases = [
    Ingredient(name: 'Brown Rice', calories: 185, price: 4.50, imageUrl: 'assets/images/brown_rice.png', type: IngredientType.base, nutritionData: _defaultNutrition),
    Ingredient(name: 'White Rice', calories: 195, price: 3.00, imageUrl: 'assets/images/white_rice.png', type: IngredientType.base, nutritionData: _defaultNutrition),
    Ingredient(name: 'Quinoa', calories: 180, price: 7.00, imageUrl: 'assets/images/quinoa.png', type: IngredientType.base, nutritionData: _defaultNutrition),
    Ingredient(name: 'Cauliflower Rice', calories: 35, price: 6.50, imageUrl: 'assets/images/cauliflower_rice.png', type: IngredientType.base, nutritionData: _defaultNutrition),
  ];

  final List<Ingredient> proteins = [
    Ingredient(name: 'Grilled Chicken', calories: 165, price: 8.00, imageUrl: 'assets/images/grilled_chicken.png', description: 'Lean, seasoned breast', type: IngredientType.protein, nutritionData: _defaultNutrition),
    Ingredient(name: 'Teriyaki Beef', calories: 249, price: 11.00, imageUrl: 'assets/images/teriyaki_beef.png', description: 'Glazed beef strips', type: IngredientType.protein, nutritionData: _defaultNutrition),
    Ingredient(name: 'Grilled Salmon', calories: 110, price: 12.00, imageUrl: 'assets/images/grilled_salmon.png', description: 'Omega-3 rich fish', type: IngredientType.protein, nutritionData: _defaultNutrition),
    Ingredient(name: 'Crispy Tofu', calories: 154, price: 4.50, imageUrl: 'assets/images/crispy_tofu.png', description: 'Plant-based protein', type: IngredientType.protein, nutritionData: _defaultNutrition),
    Ingredient(name: 'Garlic Shrimp', calories: 135, price: 10.00, imageUrl: 'assets/images/garlic_shrimp.png', description: 'Sautéed with herbs', type: IngredientType.protein, nutritionData: _defaultNutrition),
    Ingredient(name: 'Soft Boiled Eggs', calories: 140, price: 5.00, imageUrl: 'assets/images/eggs.png', description: 'Farm fresh, 2 pieces', type: IngredientType.protein, nutritionData: _defaultNutrition),
  ];

  final List<Ingredient> veggiesList = [
    Ingredient(name: 'Roasted Broccoli', calories: 28, price: 3.50, imageUrl: 'assets/images/broccoli.png', description: 'Oven-charred tender florets', type: IngredientType.veggies, nutritionData: _defaultNutrition),
    Ingredient(name: 'Cherry Tomatoes', calories: 18, price: 3.00, imageUrl: 'assets/images/tomatoes.png', description: 'Fresh, juicy bursts', type: IngredientType.veggies, nutritionData: _defaultNutrition),
    Ingredient(name: 'Onions', calories: 12, price: 1.00, imageUrl: 'assets/images/onions.png', description: 'Crisp raw purple rings', type: IngredientType.veggies, nutritionData: _defaultNutrition),
    Ingredient(name: 'Cucumber Ribbons', calories: 10, price: 1.50, imageUrl: 'assets/images/cucumber.png', description: 'Refreshing, crisp shaved slices', type: IngredientType.veggies, nutritionData: _defaultNutrition),
    Ingredient(name: 'Baby Spinach', calories: 7, price: 3.50, imageUrl: 'assets/images/spinach.png', description: 'Light, fresh peppery leaves', type: IngredientType.veggies, nutritionData: _defaultNutrition),
    Ingredient(name: 'Fresh Avocado', calories: 65, price: 3.50, imageUrl: 'assets/images/avocado.png', description: 'Three to four creamy slices', type: IngredientType.veggies, nutritionData: _defaultNutrition),
  ];

  final List<Ingredient> sauces = [
    Ingredient(name: 'Balsamic Glaze', calories: 20, price: 2.50, imageUrl: 'assets/images/balsamic.png', description: 'Thick, tangy grape reduction', type: IngredientType.sauce, nutritionData: _defaultNutrition),
    Ingredient(name: 'Basil Pesto', calories: 85, price: 4.50, imageUrl: 'assets/images/pesto.png', description: 'Nutty, fragrant herb oil', type: IngredientType.sauce, nutritionData: _defaultNutrition),
    Ingredient(name: 'Sriracha Honey', calories: 40, price: 2.00, imageUrl: 'assets/images/sriracha.png', description: 'Sweet heat, spicy kick', type: IngredientType.sauce, nutritionData: _defaultNutrition),
    Ingredient(name: 'Miso Ginger', calories: 30, price: 3.00, imageUrl: 'assets/images/miso.png', description: 'Savory, fermented umami glaze', type: IngredientType.sauce, nutritionData: _defaultNutrition),
    Ingredient(name: 'Lemon Tahini', calories: 65, price: 4.00, imageUrl: 'assets/images/tahini.png', description: 'Toasted sesame, zesty drizzle', type: IngredientType.sauce, nutritionData: _defaultNutrition),
    Ingredient(name: 'Greek Yogurt Dip', calories: 35, price: 3.00, imageUrl: 'assets/images/yogurt.png', description: 'Creamy, high-protein cooling', type: IngredientType.sauce, nutritionData: _defaultNutrition),
  ];

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

  Map<String, int> get totalNutrition {
    Map<String, int> totals = {
      'Protein': 0,
      'Carbs': 0,
      'Fats': 0,
      'Fiber': 0,
    };

    void aggregate(Ingredient ingredient, int qty) {
      totals['Protein'] = totals['Protein']! + (_parseNutrient(ingredient.nutritionData['Protein']) * qty);
      totals['Carbs'] = totals['Carbs']! + (_parseNutrient(ingredient.nutritionData['Carbs']) * qty);
      totals['Fats'] = totals['Fats']! + (_parseNutrient(ingredient.nutritionData['Fats']) * qty);
      totals['Fiber'] = totals['Fiber']! + (_parseNutrient(ingredient.nutritionData['Fiber']) * qty);
    }

    if (_selectedBase != null) aggregate(_selectedBase!, 1);
    _selectedProteins.forEach((item, qty) => aggregate(item, qty));
    _selectedVeggies.forEach((item, qty) => aggregate(item, qty));
    if (_selectedSauce != null) aggregate(_selectedSauce!, 1);

    return totals;
  }

  int _parseNutrient(String? value) {
    if (value == null) return 0;
    // Remove "g" or "mg" and parse
    final numeric = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(numeric) ?? 0;
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
