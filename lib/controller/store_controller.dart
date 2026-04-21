import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../model/store_model.dart';
import '../service/store_service.dart';
import '../service/location_service.dart';

class StoreController extends ChangeNotifier {
  Store? _selectedStore;
  Position? _userPosition;
  List<Store> _stores = [];
  bool _isLoading = true;
  bool _isLocating = false;
  bool _locationInitialized = false;

  StoreController() {
    loadStores();
  }

  bool get isLoading => _isLoading;
  Store? get selectedStore => _selectedStore;
  Position? get userPosition => _userPosition;
  List<Store> get stores => _stores;
  bool get isLocating => _isLocating;
  bool get locationInitialized => _locationInitialized;

  Future<void> loadStores() async {
    _isLoading = true;
    notifyListeners();
    try {
      _stores = await StoreService.fetchStores();
      if (_stores.isNotEmpty && _selectedStore == null) {
        _selectedStore = _stores[0];
      } else if (_selectedStore != null) {
        // Refresh the selected store data if it was already selected
        _selectedStore = _stores.firstWhere((s) => s.id == _selectedStore!.id);
      }
    } catch (e) {
      print('Error loading stores: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectStore(Store store) {
    _selectedStore = store;
    notifyListeners();
  }

  Future<void> initLocationBasedStore() async {
    if (_isLocating) return;
    
    _isLocating = true;
    notifyListeners();

    try {
      // 1. Fetch current position (triggers permission popup)
      final position = await LocationService.getCurrentLocation();
      _userPosition = position;
      
      // 2. Ensure stores are loaded
      if (_stores.isEmpty) {
        await loadStores();
      }

      if (position != null && _stores.isNotEmpty) {
        Store? nearest;
        double minDistance = double.infinity;

        for (final store in _stores) {
          final distance = LocationService.calculateDistance(
            position.latitude,
            position.longitude,
            store.latitude,
            store.longitude,
          );

          if (distance < minDistance) {
            minDistance = distance;
            nearest = store;
          }
        }

        if (nearest != null) {
          print('Nearest store found: ${nearest.name} at ${minDistance.toStringAsFixed(0)}m');
          _selectedStore = nearest;
          _locationInitialized = true;
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error in initLocationBasedStore: $e');
    } finally {
      _isLocating = false;
      notifyListeners();
    }
  }

}
