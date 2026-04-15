enum IngredientType { base, protein, veggies, sauce }

class Ingredient {
  final String name;
  final int calories;
  final double price;
  final String imageUrl;
  final String description;
  final IngredientType type;
  final Map<String, String> nutritionData;

  Ingredient({
    required this.name,
    required this.calories,
    required this.price,
    required this.imageUrl,
    this.description = '',
    required this.type,
    this.nutritionData = const {},
  });
}
