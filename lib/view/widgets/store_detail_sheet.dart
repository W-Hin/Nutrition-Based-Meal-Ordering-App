import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/store_model.dart';
import '../../controller/store_controller.dart';
import '../../controller/menu_controller.dart';

class StoreDetailBottomSheet extends StatelessWidget {
  final Store store;

  const StoreDetailBottomSheet({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                     ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        store.logoUrl,
                        width: 140, 
                        height: 140,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 140,
                          height: 140,
                          color: const Color(0xFFF5F5F0),
                          child: const Icon(Icons.store, color: Color(0xFF1E4620), size: 50),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store.name,
                            style: const TextStyle(
                              fontSize: 20, 
                              fontWeight: FontWeight.bold, 
                              color: Color(0xFF1E4620),
                              height: 1.1,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${store.rating} • ${store.distanceKm} km',
                                style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.circle, color: Colors.green, size: 10),
                              const SizedBox(width: 4),
                              const Text(
                                'Open',
                                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                store.openingHours,
                                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Set Meals',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E4620)),
                ),
              ),
              const SizedBox(height: 12),
              
              // Meals List (Using shrinkWrap to fit inside the SingleChildScrollView)
              Consumer<FoodMenuController>(
                builder: (context, menu, _) {
                  final meals = menu.meals;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: meals.length,
                    itemBuilder: (context, index) {
                      final meal = meals[index];
                      // Item is In Stock only if it's globally available AND not specifically sold out at this store
                      final isInStock = meal.isAvailable && !store.soldOutMealNames.contains(meal.name);
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(meal.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text(meal.description, style: TextStyle(color: Colors.grey[600], fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text('RM ${meal.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isInStock ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isInStock ? Icons.check_circle : Icons.cancel,
                                              size: 14,
                                              color: isInStock ? Colors.green : Colors.red,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              isInStock ? 'In Stock' : 'Sold Out',
                                              style: TextStyle(
                                                color: isInStock ? Colors.green[700] : Colors.red[700],
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: meal.imageUrl.startsWith('http')
                                  ? Image.network(
                                      meal.imageUrl,
                                      width: 100,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
                                    )
                                  : Image.asset(
                                      meal.imageUrl,
                                      width: 100,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
                                    ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              
              // Action Button
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Provider.of<StoreController>(context, listen: false).selectStore(store);
                          Navigator.pop(context); // Close sheet
                          Navigator.pop(context); // Back to menu
                        },
                        icon: const Icon(Icons.shopping_basket),
                        label: const Text('Order from this Store', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFABC270),
                          foregroundColor: const Color(0xFF1E4620),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Estimated time: 25-35 mins',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                  ],
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
      width: 100,
      height: 80,
      color: Colors.grey[100],
      child: const Icon(Icons.lunch_dining, color: Colors.grey),
    );
  }
}
