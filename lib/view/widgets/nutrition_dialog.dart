import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/meal_model.dart';
import '../../model/cart_item.dart';
import '../../controller/cart_controller.dart';
import '../../controller/store_controller.dart';
import '../../utils/app_snackbar.dart';

class NutritionDialog extends StatelessWidget {
  final Meal meal;
  final bool showAddToCart;

  const NutritionDialog({
    super.key, 
    required this.meal,
    this.showAddToCart = true,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                    'Meal Details',
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
                child: (meal.imageUrl == null || meal.imageUrl.isEmpty) 
                  ? _buildPlaceholder()
                  : (meal.imageUrl.startsWith('http')
                    ? Image.network(
                        meal.imageUrl,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                      )
                    : Image.asset(
                        meal.imageUrl,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                      )),
              ),

              const SizedBox(height: 16),

              // Name and Price
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                textAlign: TextAlign.justify,
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
              const SizedBox(height: 12),

              // Availability Status
              Row(
                children: [
                  Icon(
                    meal.isAvailable ? Icons.check_circle : Icons.cancel,
                    color: meal.isAvailable ? Colors.green : Colors.red,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    meal.isAvailable ? 'Currently Available' : 'Out of Stock',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: meal.isAvailable ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Divider(),
              const SizedBox(height: 12),

              // Nutritional Information Header
              const Text(
                'Nutritional Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E4620),
                ),
              ),
              const SizedBox(height: 12),

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

              // Dietary Preferences
              if (meal.dietaryPreferences.isNotEmpty)
                Text(
                  meal.dietaryPreferences.join(', '),
                  style: const TextStyle(
                    color: Color(0xFF9C4DB1),
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),

              const SizedBox(height: 24),

              // Add to Cart Button
              if (showAddToCart)
                SizedBox(
                  width: double.infinity,
                  child: Consumer<StoreController>(
                    builder: (context, storeCtrl, _) {
                      final isClosed = !(storeCtrl.selectedStore?.isOpen ?? true);
                      final isSoldOut = !meal.isAvailable;
                      final isDisabled = isSoldOut || isClosed;

                      return ElevatedButton(
                        onPressed: !isDisabled ? () {
                          final cartController = Provider.of<CartController>(context, listen: false);
                          final storeId = storeCtrl.selectedStore?.id;

                          cartController.addItem(CartItem(
                            foodId:   meal.id,
                            storeId:  storeId,
                            itemType: 'preset',
                            name:     meal.name,
                            price:    meal.price,
                            addOns:   const <String>[],
                            imageUrl: meal.imageUrl,
                            quantity: 1,
                          ));

                          Navigator.pop(context); // Close dialog
                          AppSnackBar.show(context, '${meal.name} added to cart!');
                        } : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !isDisabled ? const Color(0xFFABC270) : Colors.grey[300],
                          foregroundColor: !isDisabled ? const Color(0xFF1E4620) : Colors.grey[600],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          isClosed ? 'Store Closed' : (!isSoldOut ? 'Add to Cart' : 'Out of Stock'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Image.network(
      'https://cjsxgpiahswppkyackpk.supabase.co/storage/v1/object/public/meal-images/meals/noPhotoUploaded.png',
      width: double.infinity,
      height: 200,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Container(
        height: 200,
        color: Colors.grey[200],
        child: Icon(Icons.image_not_supported, color: Colors.grey[400], size: 40),
      ),
    );
  }
}
