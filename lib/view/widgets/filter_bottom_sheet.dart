import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controller/menu_controller.dart';

class FilterBottomSheet extends StatelessWidget {
  const FilterBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Menu',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          const Text('Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 12),
          Consumer<FoodMenuController>(
            builder: (context, menu, _) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'All', 'Breakfast', 'Pre-workout', 'Post-workout', 'Lunch', 'Dinner', 'Snacks'
                ].map((cat) => _FilterChip(
                  label: cat,
                  isSelected: menu.selectedCategory == cat,
                  onSelected: (val) => menu.setCategory(cat),
                )).toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          
          const Text('Dietary Preference', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 12),
          Consumer<FoodMenuController>(
            builder: (context, menu, _) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'All', 'Halal', 'Vegan', 'Vegetarian', 'Non-vegetarian'
                ].map((pref) => _FilterChip(
                  label: pref,
                  isSelected: menu.selectedDietaryPreference == pref,
                  onSelected: (val) => menu.setDietaryPreference(pref),
                )).toList(),
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Function(bool) onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: const Color(0xFFABC270),
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey[300]!),
      ),
    );
  }
}
