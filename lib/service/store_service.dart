import 'supabase_conn.dart';
import '../model/store_model.dart';
import '../service/review_service.dart';

class StoreService {
  static const String _tableName = 'stores';

  /// Fetch all stores from Supabase and attach dynamic rating stats
  static Future<List<Store>> fetchStores() async {
    try {
      final response = await supabase
          .from(_tableName)
          .select()
          .order('id', ascending: true);
      
      final baseStores = (response as List).map((data) => Store.fromMap(data)).toList();
      
      final reviewSvc = ReviewService();
      
      // Concurrently fetch dynamic stats for all stores
      final updatedStores = await Future.wait(baseStores.map((store) async {
        try {
          final stats = await reviewSvc.fetchStoreRatingStats(store.id);
          return store.copyWith(
            rating: stats['average'] as double,
            reviewCount: stats['count'] as int,
          );
        } catch (_) {
          return store; // Fallback to DB base if stats fail
        }
      }));
      
      return updatedStores;
    } catch (e) {
      print('Error fetching stores: $e');
      rethrow;
    }
  }

  /// Update store operating hours
  static Future<void> updateHours(String storeId, String open, String close) async {
    try {
      await supabase
          .from(_tableName)
          .update({
            'open_time': open,
            'close_time': close,
          })
          .eq('id', storeId);
    } catch (e) {
      print('Error updating store hours: $e');
      rethrow;
    }
  }
}
