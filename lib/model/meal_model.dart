class Meal {
  final String name;
  final double price;
  final String description;
  final String imageUrl;
  final List<String> categories;
  final List<String> dietaryPreferences;
  final String servingSize;
  final Map<String, String> nutritionData;

  Meal({
    required this.name,
    required this.price,
    required this.description,
    required this.imageUrl,
    required this.categories,
    required this.dietaryPreferences,
    required this.servingSize,
    required this.nutritionData,
  });

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
}
