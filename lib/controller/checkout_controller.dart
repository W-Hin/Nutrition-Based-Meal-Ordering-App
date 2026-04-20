import 'package:flutter/material.dart';
import '../model/address_model.dart';

enum CheckoutTab { delivery, selfCollect }
enum DeliveryOption { eco, standard, fast, orderLater, pickUpNow, selfLater }

class CheckoutController extends ChangeNotifier {
  CheckoutTab activeTab = CheckoutTab.delivery;

  void setTab(CheckoutTab tab) {
    activeTab = tab;
    notifyListeners();
  }

  // ── Address ───────────────────────────────────────────────────
  AddressModel deliveryAddress = AddressModel(
    name:    'Ali',
    phone:   '012-345 6789',
    address: 'A-B-C, Jalan Roti Bakar 6, Taman 7, 11200 Bayan Fah...',
  );

  /// The map coordinates that correspond to [deliveryAddress].
  /// Updated by EditAddressPage when the user pins a location.
  double deliveryLat = 5.4164;
  double deliveryLng = 100.3327;

  /// Update address AND the matching map coordinates at the same time,
  /// so checkout.dart's map always reflects the pinned location.
  void updateAddress(AddressModel updated, {double? lat, double? lng}) {
    deliveryAddress = updated;
    if (lat != null) deliveryLat = lat;
    if (lng != null) deliveryLng = lng;
    notifyListeners();
  }

  // ── Delivery option ───────────────────────────────────────────
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

  // ── Order For Later time ──────────────────────────────────────
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

  // ── Delivery fee based on option ─────────────────────────────
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

  // ── Delivery type label for DB storage ───────────────────────
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

  // ── Scheduled time ────────────────────────────────────────────
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

  // ── Remarks ───────────────────────────────────────────────────
  String remarks = '';
  void setRemarks(String value) {
    remarks = value;
  }

  // ── Generate 30-min time slots from now until 9pm ────────────
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