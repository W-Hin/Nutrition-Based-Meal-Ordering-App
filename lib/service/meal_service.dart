import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/meal_model.dart';
import 'supabase_conn.dart';

class MealService {
  static const String _tableName = 'menu_items';

  /// Upload an image to Supabase Storage and return the public URL
  static Future<String> uploadImage(File file) async {
    try {
      // Create a unique file name
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String path = 'meals/$fileName';

      // Upload to the "meal-images" bucket
      await supabase.storage.from('meal-images').upload(path, file);
      
      // Get the public URL for the newly uploaded file
      final String publicUrl = supabase.storage.from('meal-images').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
    }
  }

  /// Fetch all menu items from Supabase
  static Future<List<Meal>> fetchMeals() async {
    try {
      final response = await supabase
          .from(_tableName)
          .select()
          .order('name', ascending: true);
      
      return (response as List).map((data) => Meal.fromMap(data)).toList();
    } catch (e) {
      print('Error fetching meals: $e');
      rethrow;
    }
  }

  /// Add a new meal to Supabase
  static Future<Meal> addMeal(Meal meal) async {
    try {
      final response = await supabase
          .from(_tableName)
          .insert(meal.toMap())
          .select()
          .single();
      
      return Meal.fromMap(response);
    } catch (e) {
      print('Error adding meal: $e');
      rethrow;
    }
  }

  /// Update an existing meal in Supabase
  static Future<Meal> updateMeal(Meal meal) async {
    if (meal.id == null) {
      throw Exception('Meal ID is required for updates.');
    }

    try {
      final response = await supabase
          .from(_tableName)
          .update(meal.toMap())
          .eq('food_id', meal.id!)
          .select()
          .single();
      
      return Meal.fromMap(response);
    } catch (e) {
      print('Error updating meal: $e');
      rethrow;
    }
  }

  /// Delete a meal from Supabase
  static Future<void> deleteMeal(String id) async {
    try {
      await supabase
          .from(_tableName)
          .delete()
          .eq('food_id', id); 
    } catch (e) {
      print('Error deleting meal: $e');
      rethrow;
    }
  }

  /// toggle for availability (Out of Stock feature)
  static Future<void> updateAvailability(String id, bool isAvailable) async {
    try {
      await supabase
          .from(_tableName)
          .update({'is_available': isAvailable})
          .eq('food_id', id);
    } catch (e) {
      print('Error updating availability: $e');
      rethrow;
    }
  }
}
