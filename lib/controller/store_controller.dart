import 'package:flutter/material.dart';
import '../model/store_model.dart';
import '../service/store_service.dart';

class StoreController extends ChangeNotifier {
  Store? _selectedStore;
  List<Store> _stores = [];
  bool _isLoading = true;

  StoreController() {
    loadStores();
  }

  bool get isLoading => _isLoading;
  Store? get selectedStore => _selectedStore;
  List<Store> get stores => _stores;

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

}
