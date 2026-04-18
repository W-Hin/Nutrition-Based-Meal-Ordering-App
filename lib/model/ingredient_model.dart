enum IngredientType {
  base,
  protein,
  veggies,
  sauce
}

class Ingredient {
  final String? id;
  final String name;
  final int calories;
  final double price;
  final String imageUrl;
  final String description;
  final IngredientType type;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final bool isAvailable;
  final String? storeId;

  Ingredient({
    this.id,
    required this.name,
    required this.calories,
    required this.price,
    required this.imageUrl,
    this.description = '',
    required this.type,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.fiber = 0,
    this.isAvailable = true,
    this.storeId,
  });

  Ingredient copyWith({
    String? id,
    String? name,
    int? calories,
    double? price,
    String? imageUrl,
    String? description,
    IngredientType? type,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    bool? isAvailable,
  }) {
    return Ingredient(
      id: id ?? this.id,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      type: type ?? this.type,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      isAvailable: isAvailable ?? this.isAvailable,
      storeId: storeId ?? this.storeId,
    );
  }

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      id: map['ingredient_id'],
      name: map['name'] ?? '',
      calories: map['calories'] ?? 0,
      price: (map['price'] ?? 0.0).toDouble(),
      imageUrl: map['image_url'] ?? '',
      description: map['description'] ?? '',
      type: _parseType(map['category']),
      protein: (map['protein_g'] ?? 0.0).toDouble(),
      carbs: (map['carbs_g'] ?? 0.0).toDouble(),
      fat: (map['fat_g'] ?? 0.0).toDouble(),
      fiber: (map['fiber_g'] ?? 0.0).toDouble(),
      isAvailable: map['is_available'] ?? true,
      storeId: map['store_id']?.toString() ?? '2',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': type.name,
      'price': price,
      'calories': calories,
      'protein_g': protein,
      'carbs_g': carbs,
      'fat_g': fat,
      'fiber_g': fiber,
      'description': description,
      'image_url': imageUrl,
      'is_available': isAvailable,
      'store_id': storeId,
    };
  }

  static IngredientType _parseType(String? type) {
    switch (type) {
      case 'base': return IngredientType.base;
      case 'protein': return IngredientType.protein;
      case 'veggies': return IngredientType.veggies;
      case 'sauce': return IngredientType.sauce;
      default: return IngredientType.veggies;
    }
  }

  // Helper for nutrition display
  Map<String, String> get nutritionData => {
    'Protein': '${protein.toStringAsFixed(1)}g',
    'Carbs': '${carbs.toStringAsFixed(1)}g',
    'Fats': '${fat.toStringAsFixed(1)}g',
    'Fiber': '${fiber.toStringAsFixed(1)}g',
  };
}
