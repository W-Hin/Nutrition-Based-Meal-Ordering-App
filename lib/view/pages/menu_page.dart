import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controller/menu_controller.dart';
import '../widgets/meal_card.dart';
import '../widgets/custom_bowl_card.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/store_location_header.dart';
import '../../controller/store_controller.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0), // Cream background
      appBar: AppBar(
        title: const Text('Menu', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E4620), // Dark green
        foregroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Logic for back or home
          },
        ),
      ),
      body: Column(
        children: [
          const StoreLocationHeader(),
          // Filter Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const FilterBottomSheet(),
                  ),
                  child: const Icon(Icons.filter_alt_rounded, color: Color(0xFF1E4620), size: 28),
                ),
                const SizedBox(width: 12),
                
                // Horizontal Filter Chips
                Expanded(
                  child: Consumer<FoodMenuController>(
                    builder: (context, menu, _) {
                      final categories = ['All', 'Breakfast', 'Lunch', 'Dinner', 'Snacks'];
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: categories.map((cat) {
                            final isSelected = menu.selectedCategory == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(cat, style: const TextStyle(fontSize: 12)),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) menu.setCategory(cat);
                                },
                                selectedColor: const Color(0xFFABC270),
                                backgroundColor: Colors.white,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.black : Colors.grey[700],
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey[300]!),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Meal List
          Expanded(
            child: Consumer2<FoodMenuController, StoreController>(
              builder: (context, menu, storeController, _) {
                // Filter out meals that are sold out at the current store
                final meals = menu.filteredMeals.where((meal) {
                  return storeController.isMealAvailable(meal.name);
                }).toList();
                
                if (meals.isEmpty) {
                  return const Center(child: Text('No meals available at this store matching your filters.'));
                }
                
                return Scrollbar(
                  thumbVisibility: true,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: meals.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) return const CustomBowlCard();
                      return MealCard(meal: meals[index - 1]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onDeleted;

  const _ActiveFilterChip({required this.label, required this.onDeleted});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      deleteIcon: const Icon(Icons.close, size: 14),
      onDeleted: onDeleted,
      backgroundColor: Colors.grey[300],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
