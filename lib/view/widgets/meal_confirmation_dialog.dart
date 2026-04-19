import 'package:flutter/material.dart';
import '../../model/meal_model.dart';

class MealConfirmationDialog extends StatelessWidget {
  final Meal meal;

  const MealConfirmationDialog({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image Section ──
            SizedBox(
              width: double.infinity,
              height: 220,
              child: meal.imageUrl.startsWith('http')
                  ? Image.network(
                      meal.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
                    )
                  : Image.asset(
                      meal.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
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
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E4620),
                          ),
                        ),
                      ),
                      Text(
                        'RM ${meal.price % 1 == 0 ? meal.price.toInt().toString() : meal.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E4620),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ── Category ──
                  Text(
                    meal.categories.isNotEmpty ? meal.categories.first : '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E2E2E),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Description ──
                  Text(
                    meal.description,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF555555),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Serving Size ──
                  Text(
                    meal.servingSize,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF555555),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Nutrition Facts ──
                  // ── Nutrition Facts ──
                  ...meal.nutritionData.entries.map((entry) {
                    return _buildNutritionRow(entry.key, entry.value);
                  }),

                  const SizedBox(height: 16),

                  // ── Dietary Tags ──
                  if (meal.dietaryPreferences.isNotEmpty)
                    Wrap(
                      spacing: 16,
                      children: meal.dietaryPreferences.map((pref) {
                        return Text(
                          pref,
                          style: const TextStyle(
                            color: Color(0xFF9C4DB1), // Purple color from mockup
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 24),

                  // ── Buttons ──
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD25432), // Orange-red
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFABC270), // Lime green
                            foregroundColor: const Color(0xFF1E4620),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'Save',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
      ),
    );
  }

  Widget _buildNutritionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF555555),
              ),
            ),
          ),
          const Text(
            ':',
            style: TextStyle(fontSize: 16, color: Color(0xFF555555)),
          ),
          const SizedBox(width: 24),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF555555),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorImage() {
    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
    );
  }
}
