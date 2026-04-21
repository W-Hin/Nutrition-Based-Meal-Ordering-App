import 'package:flutter/material.dart';
import '../model/address_model.dart';
import '../service/supabase_conn.dart';

enum CheckoutTab { delivery, selfCollect }
enum DeliveryOption { eco, standard, fast, orderLater, pickUpNow, selfLater }

class CheckoutController extends ChangeNotifier {
  CheckoutTab activeTab = CheckoutTab.delivery;

  bool _addressLoaded = false;

  void setTab(CheckoutTab tab) {
    activeTab = tab;
    notifyListeners();
  }

  // Address
  AddressModel deliveryAddress = AddressModel(
    name:    '',
    phone:   '',
    address: 'Loading address...',
  );

  double deliveryLat = 5.4164;
  double deliveryLng = 100.3327;

  /// Loads the user's default address from Supabase.
  /// Call this once from CheckoutPage initState.
  Future<void> loadDefaultAddress() async {
    if (_addressLoaded) return;
    try {
      final uid = supabase.auth.currentUser?.id;
      if (uid == null) return;

      // Fetch default address first, fall back to most recent
      final rows = await supabase
          .from('addresses')
          .select()
          .eq('user_id', uid)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false)
          .limit(1);

      if (rows == null || (rows as List).isEmpty) {
        deliveryAddress = AddressModel(
          name:    '',
          phone:   '',
          address: 'No address saved. Please add one.',
        );
        notifyListeners();
        return;
      }

      final row = rows.first as Map<String, dynamic>;

      // Build a readable address string from parts
      final street   = (row['street']   as String? ?? '').trim();
      final city     = (row['city']     as String? ?? '').trim();
      final state    = (row['state']    as String? ?? '').trim();
      final postcode = (row['postcode'] as String? ?? '').trim();
      final parts    = [street, city, state, postcode]
          .where((p) => p.isNotEmpty)
          .toList();
      final fullAddress = parts.isNotEmpty ? parts.join(', ') : 'Address on file';

      deliveryAddress = AddressModel(
        name:            (row['name']  as String? ?? '').trim(),
        phone:           (row['phone'] as String? ?? '').trim(),
        address:         fullAddress,
        customLabelName: (row['label'] as String? ?? '').trim(),
      );

      _addressLoaded = true;
    } catch (e) {
      debugPrint('[CheckoutController] loadDefaultAddress error: $e');
    }
    notifyListeners();
  }

  /// Update address AND the matching map coordinates at the same time.
  void updateAddress(AddressModel updated, {double? lat, double? lng}) {
    deliveryAddress = updated;
    if (lat != null) deliveryLat = lat;
    if (lng != null) deliveryLng = lng;
    notifyListeners();
  }

  // Delivery option
  DeliveryOption deliveryOption    = DeliveryOption.standard;
  DeliveryOption selfCollectOption = DeliveryOption.pickUpNow;

  void setDeliveryOption(DeliveryOption option) {
    deliveryOption = option;
    if (option != DeliveryOption.orderLater) selectedLaterTime = null;
    notifyListeners();
  }

  void setSelfCollectOption(DeliveryOption option) {
    selfCollectOption = option;
    if (option != DeliveryOption.selfLater) selectedSelfLaterTime = null;
    notifyListeners();
  }

  // Order For Later time
  String? selectedLaterTime;
  String? selectedSelfLaterTime;

  void setLaterTime(String? time) {
    selectedLaterTime = time;
    notifyListeners();
  }

  void setSelfLaterTime(String? time) {
    selectedSelfLaterTime = time;
    notifyListeners();
  }

  // Delivery fee based on option
  double get deliveryFee {
    if (activeTab == CheckoutTab.selfCollect) return 0;
    switch (deliveryOption) {
      case DeliveryOption.eco:        return 2.0;
      case DeliveryOption.standard:   return 4.0;
      case DeliveryOption.fast:       return 8.0;
      case DeliveryOption.orderLater: return 4.0;
      default:                        return 0;
    }
  }

  // Delivery type label for DB storage
  String? get deliveryTypeLabel {
    if (activeTab == CheckoutTab.selfCollect) return null;
    switch (deliveryOption) {
      case DeliveryOption.eco:        return 'Eco';
      case DeliveryOption.standard:   return 'Standard';
      case DeliveryOption.fast:       return 'Fast';
      case DeliveryOption.orderLater: return 'Order For Later';
      default:                        return null;
    }
  }

  // Scheduled time
  String? get scheduledTime {
    if (activeTab == CheckoutTab.delivery &&
        deliveryOption == DeliveryOption.orderLater) {
      return selectedLaterTime;
    }
    if (activeTab == CheckoutTab.selfCollect &&
        selfCollectOption == DeliveryOption.selfLater) {
      return selectedSelfLaterTime;
    }
    return null;
  }

  // Remarks
  String remarks = '';
  void setRemarks(String value) {
    remarks = value;
  }

  // Generate 30-min time slots from now until 9pm
  List<String> generateTimeSlots() {
    final now    = DateTime.now();
    final cutoff = DateTime(now.year, now.month, now.day, 21, 0);
    final slots  = <String>[];

    var current = DateTime(
      now.year, now.month, now.day,
      now.hour,
      now.minute < 30 ? 30 : 0,
    );
    if (now.minute >= 30) {
      current = current.add(const Duration(hours: 1));
    }
    current = current.add(const Duration(minutes: 30));

    while (!current.isAfter(cutoff)) {
      final h    = current.hour;
      final m    = current.minute == 0 ? '00' : '30';
      final amPm = h >= 12 ? 'PM' : 'AM';
      final h12  = h > 12 ? h - 12 : (h == 0 ? 12 : h);
      slots.add('$h12:$m $amPm');
      current = current.add(const Duration(minutes: 30));
    }

    return slots;
  }
}
