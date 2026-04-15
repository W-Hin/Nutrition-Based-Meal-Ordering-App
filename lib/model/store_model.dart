class Store {
  final String id;
  final String name;
  final String address;
  final String logoUrl;
  final double rating;
  final double latitude;
  final double longitude;
  final String openingHours;
  final double distanceKm;
  final List<String> soldOutMealNames;

  Store({
    required this.id,
    required this.name,
    required this.address,
    required this.logoUrl,
    required this.rating,
    required this.latitude,
    required this.longitude,
    required this.openingHours,
    required this.distanceKm,
    required this.soldOutMealNames,
  });
}
