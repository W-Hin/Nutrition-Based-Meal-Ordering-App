import 'package:flutter/material.dart';
import '../../model/meal_model.dart';
import '../../service/meal_service.dart';
import 'add_menu_item_page.dart';

class AdminMenuManagementPage extends StatefulWidget {
  const AdminMenuManagementPage({super.key});

  @override
  State<AdminMenuManagementPage> createState() =>
      _AdminMenuManagementPageState();
}

class _AdminMenuManagementPageState extends State<AdminMenuManagementPage> {
  // Brand Colors synced with MenuPage/CustomBowlCard
  static const _darkGreen = Color(0xFF1E4620);
  static const _limeGreen = Color(0xFFABC270);

  List<Meal> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  Future<void> _loadMeals() async {
    setState(() => _isLoading = true);
    try {
      final meals = await MealService.fetchMeals();
      setState(() {
        _items = meals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading meals: $e')),
        );
      }
    }
  }

  void _deleteItem(int index) {
    final deletedItem = _items[index];
    final originalIndex = index;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actionsAlignment: MainAxisAlignment.center,
        title: const Text('Delete Item?',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        content: const Text('Are you sure to delete the item?'),
        actions: [
          SizedBox(
            width: 100,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFD25432),
                side: const BorderSide(color: Color(0xFFD25432)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final mealId = deletedItem.id;
                
                try {
                  if (mealId != null) {
                    await MealService.deleteMeal(mealId);
                  }
                  
                  setState(() => _items.removeAt(index));
                  
                  // Show SnackBar with Undo
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${deletedItem.name} has been deleted'),
                        action: SnackBarAction(
                          label: 'Undo',
                          textColor: Colors.white,
                          onPressed: () async {
                            final restored = await MealService.addMeal(deletedItem);
                            setState(() {
                              _items.insert(originalIndex, restored);
                            });
                          },
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD25432),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleAvailability(int index, bool value) async {
    final mealId = _items[index].id;
    if (mealId != null) {
      try {
        await MealService.updateAvailability(mealId, value);
        setState(() {
          _items[index] = _items[index].copyWith(isAvailable: value);
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating availability: $e')),
          );
        }
      }
    }
  }

  void _editItem(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMenuItemPage(initialMeal: _items[index]),
      ),
    );

    if (result != null && result is Meal) {
      setState(() {
        _items[index] = result;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${result.name} updated')),
        );
      }
    }
  }

  void _addItem() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddMenuItemPage()),
    );

    if (result != null && result is Meal) {
      setState(() {
        _items.insert(0, result);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${result.name} added successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F0), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),

              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Menu Items',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E4620), 
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage your restaurant menu items',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text(
                      'Add New Item',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _limeGreen,
                      foregroundColor: _darkGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Item list ──
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: _darkGreen))
              : _items.isEmpty
                ? Center(child: Text('No menu items found.', style: TextStyle(color: Colors.grey[600])))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: _items.length,
                    itemBuilder: (context, index) => _MenuItemCard(
                      meal:     _items[index],
                      onDelete: () => _deleteItem(index),
                      onEdit:   () => _editItem(index),
                      onToggleAvailability: (val) => _toggleAvailability(index, val),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}


// ── Menu Item Card ─────────────────────────────────────────────────────────────

class _MenuItemCard extends StatelessWidget {
  final Meal meal;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final Function(bool) onToggleAvailability;

  static const _darkGreen  = Color(0xFF1E4620);
  static const _limeGreen  = Color(0xFFABC270);
  static const _pink       = Color(0xFFFFDDE2); // Delete background
  static const _redAccent  = Color(0xFFD32F2F); // Delete text/icon

  const _MenuItemCard({
    required this.meal,
    required this.onDelete,
    required this.onEdit,
    required this.onToggleAvailability,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Image Section ──
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: meal.imageUrl.startsWith('http')
                ? Image.network(
                    meal.imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
                  )
                : Image.asset(
                    meal.imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
                  ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Title and Price ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        meal.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E4620),
                        ),
                      ),
                    ),
                    Text(
                      'RM ${meal.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E4620),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // ── Description ──
                Text(
                  meal.description,
                  style: TextStyle(color: Colors.grey[700], height: 1.4, fontSize: 14),
                ),
                const SizedBox(height: 16),

                // ── Dietary and Category Labels ──
                Row(
                  children: [
                    if (meal.dietaryPreferences.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 28),
                        child: Text(
                          meal.dietaryPreferences.first,
                          style: const TextStyle(
                            color: Color(0xFF4CAF50), 
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    if (meal.categories.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 28),
                        child: Text(
                          meal.categories.first,
                          style: const TextStyle(
                            color: Color(0xFF3F51B5), 
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      meal.isAvailable ? 'In Stock' : 'Out of Stock',
                      style: TextStyle(
                        color: meal.isAvailable ? const Color(0xFF1E4620) : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: meal.isAvailable,
                        activeColor: const Color(0xFF1E4620),
                        onChanged: onToggleAvailability,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Action buttons ──
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete, size: 18, color: _redAccent),
                          label: const Text('Delete',
                              style: TextStyle(color: _redAccent, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _pink,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit, size: 18, color: _darkGreen),
                          label: const Text('Edit',
                              style: TextStyle(color: _darkGreen, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _limeGreen,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorImage() {
    return Container(
      height: 200,
      color: Colors.grey[300],
      child: const Icon(Icons.broken_image, size: 50),
    );
  }
}

