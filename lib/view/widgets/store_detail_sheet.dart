import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/store_model.dart';
import '../../controller/store_controller.dart';
import '../../controller/cart_controller.dart';
import '../../model/meal_model.dart';
import '../../service/meal_service.dart';
import '../../service/location_service.dart';
import '../pages/store_reviews_page.dart';

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fixed Top Handle
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

          // Scrollable Content
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                                child: const Icon(Icons.store,
                                    color: Color(0xFF1E4620), size: 50),
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
                                    const Icon(Icons.star,
                                        color: Colors.amber, size: 16),
                                    const SizedBox(width: 4),
                                    Consumer<StoreController>(
                                      builder: (context, storeCtrl, _) {
                                        double? distance;
                                        if (storeCtrl.userPosition != null) {
                                          distance = LocationService.calculateDistance(
                                            storeCtrl.userPosition!.latitude,
                                            storeCtrl.userPosition!.longitude,
                                            store.latitude,
                                            store.longitude,
                                          ) / 1000;
                                        }
                                        return Text(
                                          '${store.rating} • ${distance?.toStringAsFixed(1) ?? store.distanceKm.toStringAsFixed(1)} km',
                                          style: TextStyle(
                                              color: Colors.grey[700],
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.circle,
                                        color: store.isOpen
                                            ? Colors.green
                                            : Colors.red,
                                        size: 10),
                                    const SizedBox(width: 4),
                                    Text(
                                      store.isOpen ? 'Open' : 'Closed',
                                      style: TextStyle(
                                        color: store.isOpen
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${store.openTime} - ${store.closeTime}',
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Reviews tap row ──────────────────────────────────
                    GestureDetector(
                      onTap: () => _openReviewsPage(context),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color:        const Color(0xFFF5F5F0),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEEEBDE)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width:  36,
                              height: 36,
                              decoration: BoxDecoration(
                                color:        const Color(0xFF1E4620).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.star_rounded,
                                  color: Color(0xFF1E4620), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        store.rating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontSize:   20,
                                          fontWeight: FontWeight.w900,
                                          color:      Color(0xFF2D2D2D),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Row(
                                        children: List.generate(5, (i) => Icon(
                                          i < store.rating.round()
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: Colors.amber,
                                          size: 14,
                                        )),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${store.reviewCount} Review${store.reviewCount != 1 ? 's' : ''}',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF8A8A8A)),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                color: Color(0xFF8A8A8A), size: 22),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Set Meals',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E4620)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<List<Meal>>(
                      future: MealService.fetchMeals(storeId: store.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: CircularProgressIndicator(
                                  color: Color(0xFF1E4620)),
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Text('Error loading menu: ${snapshot.error}',
                                  style: const TextStyle(color: Colors.red)),
                            ),
                          );
                        }
                        final meals = snapshot.data ?? [];
                        if (meals.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Text('No meals found for this store.'),
                            ),
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: meals.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 32,
                            thickness: 1,
                            color: Colors.grey.withOpacity(0.3),
                          ),
                          itemBuilder: (context, index) {
                            final meal = meals[index];
                            final isInStock = meal.isAvailable;
                            return Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(meal.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16)),
                                      const SizedBox(height: 4),
                                      Text(meal.description,
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Text(
                                            'RM ${meal.price % 1 == 0 ? meal.price.toInt().toString() : meal.price.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16),
                                          ),
                                          const SizedBox(width: 12),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isInStock
                                                  ? const Color(0xFFE8F5E9)
                                                  : const Color(0xFFFFEBEE),
                                              borderRadius:
                                              BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  isInStock
                                                      ? Icons.check_circle
                                                      : Icons.cancel,
                                                  size: 14,
                                                  color: isInStock
                                                      ? Colors.green
                                                      : Colors.red,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  isInStock
                                                      ? 'In Stock'
                                                      : 'Sold Out',
                                                  style: TextStyle(
                                                    color: isInStock
                                                        ? Colors.green[700]
                                                        : Colors.red[700],
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
                                    errorBuilder: (_, __, ___) =>
                                        _buildErrorImage(),
                                  )
                                      : Image.asset(
                                    meal.imageUrl,
                                    width: 100,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _buildErrorImage(),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),

          // Fixed Bottom Button Section
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final storeCtrl = Provider.of<StoreController>(context, listen: false);
                      final userPos = storeCtrl.userPosition;
                      if (userPos != null) {
                        final distance = LocationService.calculateDistance(
                          userPos.latitude,
                          userPos.longitude,
                          store.latitude,
                          store.longitude,
                        );
                        if (distance > 5000) {
                          _showFarStoreWarning(context, distance / 1000);
                          return;
                        }
                      }
                      _completeStoreSelection(context);
                    },
                    icon: const Icon(Icons.shopping_basket),
                    label: const Text(
                      'Order from this Store',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Complete store selection: update both StoreController & CartController ─
  void _completeStoreSelection(BuildContext context) {
    final storeCtrl = Provider.of<StoreController>(context, listen: false);
    final cartCtrl  = Provider.of<CartController>(context,  listen: false);

    // 1. Update which store is selected
    storeCtrl.selectStore(store);

    // 2. Switch the cart scope to this store — loads the store-specific cart
    cartCtrl.setStore(store.id, store.name);

    Navigator.pop(context);        // Close bottom sheet
    Navigator.pop(context, true);  // Close FindStorePage
  }

  void _openReviewsPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoreReviewsPage(
          storeId:   store.id,
          storeName: store.name,
        ),
      ),
    );
  }

  void _showFarStoreWarning(BuildContext context, double distanceKm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text(
              'Store is a bit far',
              style: TextStyle(
                  color:      Color(0xFF1E4620),
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'This store is approximately ${distanceKm.toStringAsFixed(1)} km away. '
              'There might be a closer branch. Are you sure you want to order from here anyway?',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back',
                style: TextStyle(
                    color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _completeStoreSelection(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E4620),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Proceed Anyway'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorImage() {
    return Container(
      width:  100,
      height: 80,
      color:  Colors.grey[100],
      child:  const Icon(Icons.lunch_dining, color: Colors.grey),
    );
  }
}