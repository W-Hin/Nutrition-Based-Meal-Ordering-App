import 'package:flutter/material.dart';
import '../../model/meal_model.dart';
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

  // Initial list using the new Meal model
  final List<Meal> _items = [
    Meal(
      name: 'Grilled Salmon Bowl',
      description: 'Fresh grilled salmon with quinoa, roasted vegetables, and lemon herb dressing. High in protein and omega-3.',
      price: 35.00,
      imageUrl: 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?q=80&w=1000&auto=format&fit=crop',
      categories: ['Lunch'],
      dietaryPreferences: ['High Protein', 'Omega-3', 'Gluten-Free'],
      servingSize: '1 bowl (350g)',
    ),
    Meal(
      name: 'Caesar Salad with Chicken Bites',
      description: 'Crispy romaine lettuce with grilled chicken, parmesan, and house caesar dressing.',
      price: 32.80,
      imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=1000&auto=format&fit=crop',
      categories: ['Lunch'],
      dietaryPreferences: ['High Protein', 'Low Carb'],
      servingSize: '1 serving (400g)',
    ),
  ];

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
              onPressed: () {
                setState(() => _items.removeAt(index));
                Navigator.pop(context);
                
                // Show SnackBar with Undo
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${deletedItem.name} has been deleted'),
                    action: SnackBarAction(
                      label: 'Undo',
                      textColor: Colors.white,
                      onPressed: () {
                        setState(() {
                          _items.insert(originalIndex, deletedItem);
                        });
                      },
                    ),
                  ),
                );
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

  void _editItem(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddMenuItemPage(initialMeal: _items[index])),
    );
    
    if (result != null && result is Meal) {
      setState(() {
        _items[index] = result;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${result.name} updated')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${result.name} added successfully')),
      );
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
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: _items.length,
              itemBuilder: (context, index) => _MenuItemCard(
                meal:     _items[index],
                onDelete: () => _deleteItem(index),
                onEdit:   () => _editItem(index),
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

  static const _darkGreen  = Color(0xFF1E4620);
  static const _limeGreen  = Color(0xFFABC270);
  static const _pink       = Color(0xFFFFDDE2); // Delete background
  static const _redAccent  = Color(0xFFD32F2F); // Delete text/icon

  const _MenuItemCard({
    required this.meal,
    required this.onDelete,
    required this.onEdit,
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
                const SizedBox(height: 20),

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

