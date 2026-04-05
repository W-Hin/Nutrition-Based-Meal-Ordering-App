class CartItem {
  final String name;
  final double price;
  final List<String> addOns;
  int quantity;

  CartItem({
    required this.name,
    required this.price,
    required this.addOns,
    this.quantity = 1,
  });

  // Total price for this line item
  double get lineTotal => price * quantity;
}