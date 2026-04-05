import 'package:flutter/material.dart';
import '../model/address_model.dart';

enum CheckoutTab { delivery, selfCollect }
enum DeliveryOption { standard, orderLater }
enum PaymentMethod { creditDebit }

class CheckoutController extends ChangeNotifier {
  // ── Tab ──────────────────────────────────────────────────
  CheckoutTab activeTab = CheckoutTab.delivery;

  void setTab(CheckoutTab tab) {
    activeTab = tab;
    notifyListeners();
  }

  // ── Address ───────────────────────────────────────────────
  AddressModel deliveryAddress = AddressModel();

  void updateAddress(AddressModel updated) {
    deliveryAddress = updated;
    notifyListeners();
  }

  // ── Delivery option ───────────────────────────────────────
  DeliveryOption deliveryOption = DeliveryOption.standard;
  DeliveryOption selfCollectOption = DeliveryOption.standard;

  void setDeliveryOption(DeliveryOption option) {
    deliveryOption = option;
    notifyListeners();
  }

  void setSelfCollectOption(DeliveryOption option) {
    selfCollectOption = option;
    notifyListeners();
  }

  // ── Payment ───────────────────────────────────────────────
  PaymentMethod paymentMethod = PaymentMethod.creditDebit;

  // ── Remarks ───────────────────────────────────────────────
  String remarks = '';

  void setRemarks(String value) {
    remarks = value;
    // No notifyListeners needed — TextField manages its own display
  }
}