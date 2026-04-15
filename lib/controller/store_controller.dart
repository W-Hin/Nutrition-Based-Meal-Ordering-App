import 'package:flutter/material.dart';
import '../model/store_model.dart';

class StoreController extends ChangeNotifier {
  Store? _selectedStore;
  
  final List<Store> _stores = [
    Store(
      id: '1',
      name: 'NuBurn - George Town',
      address: 'George Town, Penang',
      logoUrl: 'assets/images/nuBurnWord_logo_noBackground.png',
      rating: 5.0,
      latitude: 5.4206,
      longitude: 100.3429,
      openingHours: 'Closes 10:00 PM',
      distanceKm: 0.2,
      soldOutMealNames: ['Buddha Bowl'],
    ),
    Store(
      id: '2',
      name: 'NuBurn - Gurney Plaza',
      address: 'Gurney Drive, Penang',
      logoUrl: 'assets/images/nuBurnWord_logo_noBackground.png',
      rating: 4.8,
      latitude: 5.4347,
      longitude: 100.3065,
      openingHours: 'Closes 9:30 PM',
      distanceKm: 2.5,
      soldOutMealNames: ['Grilled Salmon Bowl', 'Avocado Toast'],
    ),
    Store(
      id: '3',
      name: 'NuBurn - Queensbay',
      address: 'Bayan Lepas, Penang',
      logoUrl: 'assets/images/nuBurnWord_logo_noBackground.png',
      rating: 4.9,
      latitude: 5.3340,
      longitude: 100.3067,
      openingHours: 'Closes 10:00 PM',
      distanceKm: 8.0,
      soldOutMealNames: [],
    ),
  ];

  StoreController() {
    _selectedStore = _stores[0]; // Default to first store
  }

  Store? get selectedStore => _selectedStore;
  List<Store> get stores => _stores;

  void selectStore(Store store) {
    _selectedStore = store;
    notifyListeners();
  }

  bool isMealAvailable(String mealName) {
    if (_selectedStore == null) return true;
    return !_selectedStore!.soldOutMealNames.contains(mealName);
  }
}
