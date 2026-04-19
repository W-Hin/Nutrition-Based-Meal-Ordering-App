import 'package:flutter/material.dart';
import '../../model/meal_model.dart';
import '../../model/ingredient_model.dart';
import '../../model/store_model.dart';
import '../../service/meal_service.dart';
import '../../service/ingredient_service.dart';
import '../widgets/premium_segmented_control.dart';
import 'add_menu_item_page.dart';
import 'add_ingredient_page.dart';
import '../../service/store_service.dart';
import '../../controller/store_controller.dart';
import 'package:provider/provider.dart';
import '../widgets/nutrition_dialog.dart';
import '../widgets/ingredient_detail_dialog.dart';

class AdminMenuManagementPage extends StatefulWidget {
  final Store? store;
  const AdminMenuManagementPage({super.key, this.store});

  @override
  State<AdminMenuManagementPage> createState() =>
      _AdminMenuManagementPageState();
}

class _AdminMenuManagementPageState extends State<AdminMenuManagementPage> {
  // Brand Colors synced with MenuPage/CustomBowlCard
  static const _darkGreen = Color(0xFF1E4620);
  static const _limeGreen = Color(0xFFABC270);

  List<Meal> _items = [];
  List<Ingredient> _ingredients = [];
  int _selectedMode = 0; // 0 for Meals, 1 for Ingredients
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(AdminMenuManagementPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store?.id != widget.store?.id) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (widget.store == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_selectedMode == 0) {
        final meals = await MealService.fetchMeals(storeId: widget.store!.id);
        if (!mounted) return;
        setState(() {
          _items = meals;
          _isLoading = false;
        });
      } else {
        final ingredients = await IngredientService.fetchAllIngredientsAdmin(storeId: widget.store!.id);
        if (!mounted) return;
        setState(() {
          _ingredients = ingredients;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  void _deleteItem(int index) {
    final deletedItemName = _selectedMode == 0 ? _items[index].name : _ingredients[index].name;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actionsAlignment: MainAxisAlignment.center,
        title: const Text('Delete Item?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        content: Text('Are you sure you want to delete "$deletedItemName"?'),
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
                try {
                  if (_selectedMode == 0) {
                    final mealId = _items[index].id;
                    if (mealId != null) await MealService.deleteMeal(mealId);
                    if (!mounted) return;
                    setState(() => _items.removeAt(index));
                  } else {
                    final ingId = _ingredients[index].id;
                    if (ingId != null) await IngredientService.deleteIngredient(ingId);
                    if (!mounted) return;
                    setState(() => _ingredients.removeAt(index));
                  }
                  _showSuccess('$deletedItemName has been deleted');
                } catch (e) {
                  _showError(e);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD25432),
                foregroundColor: Colors.white,
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
    if (_selectedMode == 0) {
      final mealId = _items[index].id;
      if (mealId != null) {
        try {
          await MealService.updateAvailability(mealId, value);
          if (!mounted) return;
          setState(() {
            _items[index] = _items[index].copyWith(isAvailable: value);
          });
        } catch (e) {
          _showError(e);
        }
      }
    } else {
      final ingredientId = _ingredients[index].id;
      if (ingredientId != null) {
        try {
          await IngredientService.updateAvailability(ingredientId, value);
          if (!mounted) return;
          setState(() {
            _ingredients[index] = _ingredients[index].copyWith(isAvailable: value);
          });
        } catch (e) {
          _showError(e);
        }
      }
    }
  }

  void _showError(Object e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _editItem(int index) async {
    if (_selectedMode == 0) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddMenuItemPage(initialMeal: _items[index], storeId: widget.store!.id),
        ),
      );

      if (result != null && result is Meal) {
        if (!mounted) return;
        setState(() {
          _items[index] = result;
        });
        _showSuccess('${result.name} updated');
      }
    } else {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddIngredientPage(initialIngredient: _ingredients[index], storeId: widget.store!.id),
        ),
      );

      if (result != null && result is Ingredient) {
        if (!mounted) return;
        setState(() {
          _ingredients[index] = result;
        });
        _showSuccess('${result.name} updated');
      }
    }
  }

  void _viewItem(int index) {
    if (_selectedMode == 0) {
      showDialog(
        context: context,
        builder: (context) => NutritionDialog(
          meal: _items[index],
          showAddToCart: false, // Don't show Add to Cart for Admin view
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => IngredientDetailDialog(
          ingredient: _ingredients[index],
        ),
      );
    }
  }

  void _addItem() async {
    if (_selectedMode == 0) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AddMenuItemPage(storeId: widget.store!.id)),
      );

      if (result != null && result is Meal) {
        if (!mounted) return;
        setState(() {
          _items.insert(0, result);
        });
        _showSuccess('${result.name} added successfully');
      }
    } else {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AddIngredientPage(storeId: widget.store!.id)),
      );

      if (result != null && result is Ingredient) {
        if (!mounted) return;
        setState(() {
          _ingredients.insert(0, result);
        });
        _showSuccess('${result.name} added successfully');
      }
    }
  }

  void _showSuccess(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  void _showStoreSettings() async {
    // Always get the freshest data from the controller
    final storeController = context.read<StoreController>();
    final currentStore = storeController.stores.firstWhere((s) => s.id == widget.store!.id);
    
    String openTime = currentStore.openTime;
    String closeTime = currentStore.closeTime;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.access_time, color: _darkGreen),
              const SizedBox(width: 12),
              const Text('Store Operating Hours', style: TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Manage operating hours for ${currentStore.name}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              const SizedBox(height: 24),
              _buildTimeTile(
                label: 'Opening Time',
                time: openTime,
                onTap: () async {
                  final time = await _pickTime(openTime);
                  if (time != null) setDialogState(() => openTime = time);
                },
              ),
              const SizedBox(height: 16),
              _buildTimeTile(
                label: 'Closing Time',
                time: closeTime,
                onTap: () async {
                  final time = await _pickTime(closeTime);
                  if (time != null) setDialogState(() => closeTime = time);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await StoreService.updateHours(currentStore.id, openTime, closeTime);
                  // Refresh the global controller using the reference we captured at the start
                  // of this method, which is safe even after the dialog pops!
                  storeController.loadStores(); 
                  
                  _showSuccess('Operating hours updated successfully');
                } catch (e) {
                  _showError(e);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _limeGreen,
                foregroundColor: _darkGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeTile({required String label, required String time, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                Text(time, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _darkGreen)),
              ],
            ),
            const Icon(Icons.access_time_filled, color: _limeGreen),
          ],
        ),
      ),
    );
  }

  Future<String?> _pickTime(String current) async {
    final parts = current.split(':');
    final initialTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _darkGreen,
              onPrimary: Colors.white,
              onSurface: _darkGreen,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final hour = picked.hour.toString().padLeft(2, '0');
      final minute = picked.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.store == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Please select a restaurant from the drawer\nto manage its menu.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Consumer<StoreController>(
      builder: (context, storeController, _) {
        // Find the latest version of this store from the controller
        final currentStore = storeController.stores.firstWhere(
          (s) => s.id == widget.store!.id,
          orElse: () => widget.store!,
        );

        return Container(
          color: const Color(0xFFF5F5F0), // Standardized background
          child: Column(
            children: [
              // ── STICKY HEADER: Pill Widget ──
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                color: const Color(0xFFF5F5F0), // Matches background
                child: PremiumSegmentedControl(
                  selectedIndex: _selectedMode,
                  options: const ['Meals', 'Ingredients'],
                  icons: const [Icons.restaurant_menu, Icons.egg_outlined],
                  onValueChanged: (index) {
                    setState(() {
                      _selectedMode = index;
                      _loadData();
                    });
                  },
                ),
              ),

              // ── SCROLLABLE CONTENT ──
              Expanded(
                child: _buildItemListContent(currentStore),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItemListContent(Store currentStore) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _darkGreen));
    }

    final int itemCount = _selectedMode == 0 ? _items.length : _ingredients.length;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      // We add 2 to the itemCount: one for the Title, one for the "Add Card"
      itemCount: itemCount + 2,
      itemBuilder: (context, index) {
        // 1. First Item: Title
        if (index == 0) {
          final String storeName = currentStore.name.split(' - ').last;
          return Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 0, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedMode == 0 ? 'Menu: $storeName' : 'Ingredients: $storeName',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: _darkGreen,
                    letterSpacing: -0.5,
                  ),
                ),
                IconButton(
                  onPressed: _showStoreSettings,
                  icon: const Icon(Icons.access_time, color: _darkGreen),
                  tooltip: 'Store Operating Hours',
                ),
              ],
            ),
          );
        }

        // 2. Second Item: "Add Card" (Styled like CustomBowlCard)
        if (index == 1) {
          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _selectedMode == 0 ? Icons.restaurant : Icons.inventory_2_outlined,
                      color: _darkGreen,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _selectedMode == 0 ? 'New Menu Item' : 'New Ingredient',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _darkGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _selectedMode == 0
                      ? 'Create and publish a new delicious meal to the customer menu.'
                      : 'Add a new raw ingredient or component for the custom bowl builder.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add_rounded),
                    label: Text(
                      _selectedMode == 0 ? 'Create New Meal' : 'Add New Ingredient',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _limeGreen,
                      foregroundColor: _darkGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // 3. The actual items (offset by 2)
        final int listIndex = index - 2;
        if (_selectedMode == 0) {
          if (_items.isEmpty) return _buildEmptyState();
          final meal = _items[listIndex];
          return _ItemCard(
            title: meal.name,
            subtitle: meal.description,
            price: meal.price,
            imageUrl: meal.imageUrl,
            isAvailable: meal.isAvailable,
            dietaryPreferences: meal.dietaryPreferences,
            categories: meal.categories,
            onDelete: () => _deleteItem(listIndex),
            onEdit: () => _editItem(listIndex),
            onTap: () => _viewItem(listIndex),
            onToggleAvailability: (val) => _toggleAvailability(listIndex, val),
          );
        } else {
          if (_ingredients.isEmpty) return _buildEmptyState();
          final ing = _ingredients[listIndex];
          return _ItemCard(
            title: ing.name,
            subtitle: ing.description.isNotEmpty ? ing.description : 'Category: ${ing.type.name.toUpperCase()}',
            price: ing.price,
            imageUrl: ing.imageUrl,
            isAvailable: ing.isAvailable,
            onDelete: () => _deleteItem(listIndex),
            onEdit: () => _editItem(listIndex),
            onTap: () => _viewItem(listIndex),
            onToggleAvailability: (val) => _toggleAvailability(listIndex, val),
          );
        }
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Text(
          _selectedMode == 0 ? 'No menu items found.' : 'No ingredients found.',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ),
    );
  }
}


// Menu Item card

class _ItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double price;
  final String imageUrl;
  final bool isAvailable;
  final List<String> dietaryPreferences;
  final List<String> categories;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onTap;
  final Function(bool) onToggleAvailability;

  static const _darkGreen  = Color(0xFF1E4620);
  static const _limeGreen  = Color(0xFFABC270);
  static const _pink       = Color(0xFFFFDDE2); 
  static const _redAccent  = Color(0xFFD32F2F); 

  const _ItemCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.imageUrl,
    required this.isAvailable,
    this.dietaryPreferences = const [],
    this.categories = const [],
    required this.onDelete,
    required this.onEdit,
    required this.onTap,
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
          // ── Clickable Area ──
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Image Section ──
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: imageUrl.isEmpty 
                    ? _buildPlaceholder()
                    : imageUrl.startsWith('http')
                      ? Image.network(
                          imageUrl,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
                        )
                      : Image.asset(
                          imageUrl,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _darkGreen,
                              ),
                            ),
                          ),
                          Text(
                            'RM ${price % 1 == 0 ? price.toInt().toString() : price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _darkGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[700], height: 1.4, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      if (dietaryPreferences.isNotEmpty || categories.isNotEmpty) 
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            ...dietaryPreferences.map((pref) => _Tag(text: pref, color: const Color(0xFF4CAF50))),
                            ...categories.map((cat) => _Tag(text: cat, color: const Color(0xFF3F51B5))),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isAvailable ? 'In Stock' : 'Out of Stock',
                      style: TextStyle(
                        color: isAvailable ? _darkGreen : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: isAvailable,
                        activeThumbColor: _darkGreen,
                        onChanged: onToggleAvailability,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        onPressed: onDelete,
                        icon: Icons.delete,
                        label: 'Delete',
                        color: _redAccent,
                        bgColor: _pink,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        onPressed: onEdit,
                        icon: Icons.edit,
                        label: 'Edit',
                        color: _darkGreen,
                        bgColor: _limeGreen,
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

  Widget _buildPlaceholder() {
    return Container(
      height: 180,
      color: Colors.grey[200],
      child: const Icon(Icons.image_outlined, color: Colors.grey, size: 40),
    );
  }

  Widget _buildErrorImage() {
    return Container(
      height: 180,
      color: Colors.grey[300],
      child: const Icon(Icons.broken_image, size: 40),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;

  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16, color: color),
        label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

