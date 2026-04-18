class Store {
  final String id;
  final String name;
  final String address;
  final String logoUrl;
  final double rating;
  final double latitude;
  final double longitude;
  final String openTime;  // Format "HH:mm"
  final String closeTime; // Format "HH:mm"
  final double distanceKm;

  Store({
    required this.id,
    required this.name,
    required this.address,
    required this.logoUrl,
    required this.rating,
    required this.latitude,
    required this.longitude,
    required this.openTime,
    required this.closeTime,
    required this.distanceKm,
  });

  factory Store.fromMap(Map<String, dynamic> map) {
    return Store(
      id: map['id'],
      name: map['name'],
      address: map['address'],
      logoUrl: map['logo_url'],
      rating: (map['rating'] ?? 5.0).toDouble(),
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      openTime: map['open_time'] ?? '09:00',
      closeTime: map['close_time'] ?? '22:00',
      distanceKm: (map['distance_km'] ?? 0.0).toDouble(),
    );
  }

  /// Calculates if the store is currently open based on system time
  bool get isOpen {
    final now = DateTime.now();
    
    try {
      final openParts = openTime.split(':');
      final closeParts = closeTime.split(':');
      
      if (openParts.length != 2 || closeParts.length != 2) return true;

      final nowMins = now.hour * 60 + now.minute;
      final openMins = int.parse(openParts[0]) * 60 + int.parse(openParts[1]);
      final closeMins = int.parse(closeParts[0]) * 60 + int.parse(closeParts[1]);

      if (closeMins > openMins) {
        // Normal case (e.g., 09:00 to 22:00)
        return nowMins >= openMins && nowMins < closeMins;
      } else if (closeMins < openMins) {
        // Midnight crossover case (e.g., 22:00 to 02:00)
        // It's open if it's AFTER opening time OR BEFORE closing time (next day)
        return nowMins >= openMins || nowMins < closeMins;
      } else {
        // If open and close are exactly the same, assume open 24h
        return true;
      }
    } catch (e) {
      return true; // Default to open if parsing fails
    }
  }
}
