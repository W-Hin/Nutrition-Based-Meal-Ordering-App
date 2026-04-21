import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controller/menu_controller.dart';
import '../widgets/meal_card.dart';
import '../widgets/custom_bowl_card.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/store_location_header.dart';
import '../../controller/store_controller.dart';

class MenuPage extends StatelessWidget {
  final VoidCallback onBack;
  const MenuPage({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    // Create controller at build level
    final ScrollController _scrollController = ScrollController();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        title: const Text('Menu', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF5F5F0),
        foregroundColor: const Color(0xFF1E4620),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
      ),
      body: Column(
        children: [
          const StoreLocationHeader(),
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
                  child: const Icon(Icons.filter_alt_rounded,
                      color: Color(0xFF1E4620), size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Consumer<FoodMenuController>(
                    builder: (context, menu, _) {
                      final categories = [
                        'All', 'Breakfast', 'Lunch', 'Dinner', 'Snacks'
                      ];
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        // ↓ fix: explicitly not primary
                        primary: false,
                        child: Row(
                          children: categories.map((cat) {
                            final isSelected = menu.selectedCategory == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(cat,
                                    style: const TextStyle(fontSize: 12)),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) menu.setCategory(cat);
                                },
                                selectedColor: const Color(0xFFABC270),
                                backgroundColor: Colors.white,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.grey[700],
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                      color: isSelected
                                          ? Colors.transparent
                                          : Colors.grey[300]!),
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
          Expanded(
            child: Consumer2<FoodMenuController, StoreController>(
              builder: (context, menu, storeController, _) {
                final meals = menu.filteredMeals;
final selectedStore = storeController.selectedStore;
                final isClosed = selectedStore != null && !selectedStore.isOpen;

                if (meals.isEmpty && !isClosed) {
                  return const Center(
                      child: Text(
                          'No meals available matching your filters.'));
                }

                final sortedMeals = List.from(meals)
                  ..sort((a, b) {
                    final aSoldOut = !a.isAvailable;
                    final bSoldOut = !b.isAvailable;
                    if (aSoldOut == bSoldOut) return 0;
                    return aSoldOut ? 1 : -1;
                  });

                return RefreshIndicator(
                  onRefresh: () => menu.fetchMeals(),
                  color: const Color(0xFF1E4620),
                  child: Scrollbar(
                    controller: _scrollController, // ← explicit controller
                    thumbVisibility: true,
                    child: ListView.builder(
                      controller: _scrollController, // ← same controller
                      primary: false,               // ← not primary
                      padding: const EdgeInsets.only(bottom: 24),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: sortedMeals.length + (isClosed ? 2 : 1),
                      itemBuilder: (context, index) {
                        // Closed Banner
                        if (isClosed && index == 0) {
                          return Container(
                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red[100]!),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, color: Colors.red, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Store is currently closed. You can browse the menu, but ordering is unavailable.',
                                    style: TextStyle(
                                      color: Colors.red[900],
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // Adjust index for following items if banner is shown
                        final itemIndex = isClosed ? index - 1 : index;

                        if (itemIndex == 0) return const CustomBowlCard();
                        final meal = sortedMeals[itemIndex - 1];
                        return MealCard(
                          meal: meal,
                          isSoldOut: !meal.isAvailable,
                        );
                      },
                    ),
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
