class Meal {
  final String name;
  final double price;
  final String description;
  final String imageUrl;
  final List<String> categories;
  final List<String> dietaryPreferences;
  final String servingSize;
  
  // Nutrition Data
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final double sodium;
  final double cholesterol;

  // Additional Information
  final List<String> allergens;
  final String remarks;

  Meal({
    required this.name,
    required this.price,
    required this.description,
    required this.imageUrl,
    required this.categories,
    required this.dietaryPreferences,
    required this.servingSize,
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.fiber = 0,
    this.sugar = 0,
    this.sodium = 0,
    this.cholesterol = 0,
    this.allergens = const [],
    this.remarks = '',
  });

  // Getter for backward compatibility if needed, though better to use fields
  Map<String, String> get nutritionData => {
    'Calories': '${calories.toStringAsFixed(0)} cal',
    'Protein': '${protein.toStringAsFixed(1)} g',
    'Carbs': '${carbs.toStringAsFixed(1)} g',
    'Fat': '${fat.toStringAsFixed(1)} g',
    'Fiber': '${fiber.toStringAsFixed(1)} g',
    'Sugar': '${sugar.toStringAsFixed(1)} g',
    'Sodium': '${sodium.toStringAsFixed(0)} mg',
    'Cholesterol': '${cholesterol.toStringAsFixed(0)} mg',
  };

  // Helper to check if meal matches a category
  bool hasCategory(String category) {
    if (category.toLowerCase() == 'all') return true;
    return categories.contains(category);
  }

  // Helper to check if meal matches a dietary preference
  bool hasDietaryPreference(String preference) {
    if (preference.toLowerCase() == 'all') return true;
    return dietaryPreferences.contains(preference);
  }

  Meal copyWith({
    String? name,
    double? price,
    String? description,
    String? imageUrl,
    List<String>? categories,
    List<String>? dietaryPreferences,
    String? servingSize,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    double? sugar,
    double? sodium,
    double? cholesterol,
    List<String>? allergens,
    String? remarks,
  }) {
    return Meal(
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      categories: categories ?? this.categories,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      servingSize: servingSize ?? this.servingSize,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      sugar: sugar ?? this.sugar,
      sodium: sodium ?? this.sodium,
      cholesterol: cholesterol ?? this.cholesterol,
      allergens: allergens ?? this.allergens,
      remarks: remarks ?? this.remarks,
    );
  }
}

