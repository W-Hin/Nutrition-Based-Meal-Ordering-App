class Meal {
  final String? id;
  final String name;
  final double price;
  final String description;
  final String imageUrl;
  final List<String> categories;
  final List<String> dietaryPreferences;
  final String servingSize;
  final bool isAvailable;
  
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
  final String? storeId;

  Meal({
    this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.imageUrl,
    required this.categories,
    required this.dietaryPreferences,
    required this.servingSize,
    this.isAvailable = true,
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
    this.storeId,
  });

  // return only non-zero
  Map<String, String> get nutritionData {
    final data = <String, String>{};
    if (calories > 0)    data['Calories']    = '${calories.toStringAsFixed(0)} cal';
    if (protein > 0)     data['Protein']     = '${protein.toStringAsFixed(1)} g';
    if (carbs > 0)       data['Carbs']       = '${carbs.toStringAsFixed(1)} g';
    if (fat > 0)         data['Fat']         = '${fat.toStringAsFixed(1)} g';
    if (fiber > 0)       data['Fiber']       = '${fiber.toStringAsFixed(1)} g';
    if (sugar > 0)       data['Sugar']       = '${sugar.toStringAsFixed(1)} g';
    if (sodium > 0)      data['Sodium']      = '${sodium.toStringAsFixed(0)} mg';
    if (cholesterol > 0) data['Cholesterol'] = '${cholesterol.toStringAsFixed(0)} mg';
    return data;
  }

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
    String? id,
    String? name,
    double? price,
    String? description,
    String? imageUrl,
    List<String>? categories,
    List<String>? dietaryPreferences,
    String? servingSize,
    bool? isAvailable,
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
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      categories: categories ?? this.categories,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      servingSize: servingSize ?? this.servingSize,
      isAvailable: isAvailable ?? this.isAvailable,
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
      storeId: storeId ?? this.storeId,
    );
  }

  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      id:          map['food_id'], 
      name:        map['name'] ?? '',
      price:       (map['price'] ?? 0).toDouble(),
      description: map['description'] ?? '',
      imageUrl:    map['image_url'] ?? '',
      categories:  List<String>.from(map['categories'] ?? []),
      dietaryPreferences: List<String>.from(map['dietary_preferences'] ?? []),
      servingSize: map['serving_size'] ?? '',
      isAvailable: map['is_available'] ?? true,
      calories:    (map['calories'] ?? 0).toDouble(),
      protein:     (map['protein'] ?? 0).toDouble(),
      carbs:       (map['carbs'] ?? 0).toDouble(),
      fat:         (map['fats'] ?? 0).toDouble(), 
      fiber:       (map['fiber'] ?? 0).toDouble(),
      sugar:       (map['sugar'] ?? 0).toDouble(),
      sodium:      (map['sodium'] ?? 0).toDouble(),
      cholesterol: (map['cholesterol'] ?? 0).toDouble(),
      allergens:   List<String>.from(map['allergen'] ?? []), 
      remarks:     map['remarks'] ?? '',
      storeId:     map['store_id']?.toString() ?? '2', // Default to Gurney Plaza if missing
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name':                name,
      'price':               price,
      'description':         description,
      'image_url':           imageUrl,
      'categories':          categories,
      'dietary_preferences': dietaryPreferences,
      'serving_size':        servingSize,
      'is_available':        isAvailable,
      'calories':            calories,
      'protein':             protein,
      'carbs':               carbs,
      'fats':                fat, 
      'fiber':               fiber,
      'sugar':               sugar,
      'sodium':              sodium,
      'cholesterol':         cholesterol,
      'allergen':            allergens, 
      'remarks':             remarks,
      'store_id':            storeId,
    };
  }
}

