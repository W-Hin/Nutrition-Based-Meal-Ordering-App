import 'package:flutter/material.dart';
import '../../model/meal_model.dart';
import '../../model/cart_item.dart';
import '../../controller/cart_controller.dart';
import '../../controller/store_controller.dart';
import 'package:provider/provider.dart';
import 'nutrition_dialog.dart';

class MealCard extends StatelessWidget {
  final Meal meal;
  final bool isSoldOut;

  const MealCard({super.key, required this.meal, this.isSoldOut = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Opacity(
        opacity: isSoldOut ? 0.6 : 1.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Section
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: meal.imageUrl.isEmpty 
                    ? _buildPlaceholder()
                    : (meal.imageUrl.startsWith('http')
                      ? Image.network(
                          meal.imageUrl,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                        )
                      : Image.asset(
                          meal.imageUrl,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                        )),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                        'RM ${meal.price % 1 == 0 ? meal.price.toInt().toString() : meal.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E4620),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    meal.description,
                    textAlign: TextAlign.justify,
                    style: TextStyle(color: Colors.grey[700], height: 1.4, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  
                  // Dietary and Category Tags
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      ...meal.dietaryPreferences.map((pref) => Text(
                        pref,
                        style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w500),
                      )),
                      ...meal.categories.map((cat) => Text(
                        cat,
                        style: const TextStyle(color: Colors.blueAccent, fontSize: 13, fontWeight: FontWeight.w500),
                      )),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // View Nutrition Info Link
                  GestureDetector(
                    onTap: () => showDialog(
                      context: context,
                      builder: (context) => NutritionDialog(meal: meal),
                    ),
                    child: const Text(
                      'View Nutrition Info',
                      style: TextStyle(
                        color: Color(0xFF1E4620),
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Add to Cart Button
                  SizedBox(
                    width: double.infinity,
                    child: Consumer<StoreController>(
                      builder: (context, storeCtrl, _) {
                        final isClosed = !(storeCtrl.selectedStore?.isOpen ?? true);
                        final isDisabled = isSoldOut || isClosed;

                        return ElevatedButton(
                          onPressed: !isDisabled
                              ? () {
                            final cart = Provider.of<CartController>(context, listen: false);
                            final storeId = storeCtrl.selectedStore?.id;

                            cart.addItem(CartItem(
                              foodId:   meal.id,
                              storeId:  storeId,
                              itemType: 'preset',
                              name:     meal.name,
                              price:    meal.price,
                              addOns:   const <String>[],
                              imageUrl: meal.imageUrl,
                              quantity: 1,
                            ));

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${meal.name} added to cart!'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: !isDisabled ? const Color(0xFFABC270) : Colors.grey[300],
                            foregroundColor: const Color(0xFF1E4620),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: Text(
                            isClosed
                                ? 'Store Closed'
                                : (!isSoldOut ? 'Add to Cart' : 'Out of Stock'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Image.asset(
      'assets/images/no_image_placeholder.png',
      height: 200,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }
}