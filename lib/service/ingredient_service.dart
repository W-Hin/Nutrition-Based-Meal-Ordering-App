import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/ingredient_model.dart';

class IngredientService {
  static final _supabase = Supabase.instance.client;

  /// Fetch available ingredients
  static Future<List<Ingredient>> fetchIngredients({String? storeId}) async {
    try {
      var query = _supabase.from('ingredients').select();
      
      if (storeId != null) {
        query = query.eq('store_id', storeId);
      }

      final response = await query.order('name', ascending: true);
      
      return (response as List).map((m) => Ingredient.fromMap(m)).toList();
    } catch (e) {
      throw Exception('Failed to fetch ingredients: $e');
    }
  }

  /// [Admin] Fetch ingredients for a specific store
  static Future<List<Ingredient>> fetchAllIngredientsAdmin({String? storeId}) async {
    try {
      var query = _supabase.from('ingredients').select();

      if (storeId != null) {
        query = query.eq('store_id', storeId);
      }

      final response = await query.order('created_at', ascending: false);
      
      return (response as List).map((m) => Ingredient.fromMap(m)).toList();
    } catch (e) {
      throw Exception('Failed to fetch admin ingredients: $e');
    }
  }

  /// [Admin] Add a new ingredient
  static Future<Ingredient> addIngredient(Ingredient ingredient) async {
    try {
      final response = await _supabase
          .from('ingredients')
          .insert(ingredient.toMap())
          .select()
          .single();
      
      return Ingredient.fromMap(response);
    } catch (e) {
      throw Exception('Failed to add ingredient: $e');
    }
  }

  /// [Admin] Update an existing ingredient
  static Future<Ingredient> updateIngredient(Ingredient ingredient) async {
    if (ingredient.id == null) throw Exception('Ingredient ID is missing');
    
    try {
      final response = await _supabase
          .from('ingredients')
          .update(ingredient.toMap())
          .eq('ingredient_id', ingredient.id!)
          .select()
          .single();
      
      return Ingredient.fromMap(response);
    } catch (e) {
      throw Exception('Failed to update ingredient: $e');
    }
  }

  /// [Admin] Toggle availability
  static Future<void> updateAvailability(String id, bool isAvailable) async {
    try {
      await _supabase
          .from('ingredients')
          .update({'is_available': isAvailable})
          .eq('ingredient_id', id);
    } catch (e) {
      throw Exception('Failed to update availability: $e');
    }
  }

  /// [Admin] Delete an ingredient
  static Future<void> deleteIngredient(String id) async {
    try {
      await _supabase
          .from('ingredients')
          .delete()
          .eq('ingredient_id', id);
    } catch (e) {
      throw Exception('Failed to delete ingredient: $e');
    }
  }

  /// Upload ingredient icon/photo
  static Future<String> uploadImage(File file) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'ingredients/$fileName';
      
      await _supabase.storage.from('meal-images').upload(path, file);
      
      final publicUrl = _supabase.storage.from('meal-images').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
}
