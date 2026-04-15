import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/meal_model.dart';
import '../../model/cart_item.dart';
import '../../controller/cart_controller.dart';

class NutritionDialog extends StatelessWidget {
  final Meal meal;

  const NutritionDialog({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nutrition Details',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E4620),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD25432), // Reddish close button
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: meal.imageUrl.startsWith('http')
                    ? Image.network(
                        meal.imageUrl,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
                      )
                    : Image.asset(
                        meal.imageUrl,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
                      ),
              ),

              const SizedBox(height: 16),

              // Name and Price
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
                    'RM ${meal.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E4620),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Categories
              Text(
                meal.categories.join(', '),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E2E2E),
                ),
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                meal.description,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF555555),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),

              // Serving Size
              Text(
                meal.servingSize,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF555555),
                ),
              ),
              const SizedBox(height: 16),

              // Nutrition Facts
              ...meal.nutritionData.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          entry.key,
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
                        entry.value,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF555555),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 16),

              // Dietary Preferences (e.g., Vegetarian)
              if (meal.dietaryPreferences.isNotEmpty)
                Text(
                  meal.dietaryPreferences.join(', '),
                  style: const TextStyle(
                    color: Color(0xFF9C4DB1), // Purple color from mockup
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),

              const SizedBox(height: 24),

              // Add to Cart Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final cartController = Provider.of<CartController>(context, listen: false);
                    cartController.addItem(CartItem(
                      name: meal.name,
                      price: meal.price,
                      addOns: [],
                      quantity: 1,
                    ));
                    Navigator.pop(context); // Close dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${meal.name} added to cart!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFABC270),
                    foregroundColor: const Color(0xFF1E4620),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    'Add to Cart',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorImage() {
    return Container(
      height: 180,
      color: Colors.grey[200],
      child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
    );
  }
}

