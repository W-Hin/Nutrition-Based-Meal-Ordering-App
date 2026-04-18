import 'supabase_conn.dart';
import '../model/store_model.dart';

class StoreService {
  static const String _tableName = 'stores';

  /// Fetch all stores from Supabase
  static Future<List<Store>> fetchStores() async {
    try {
      final response = await supabase
          .from(_tableName)
          .select()
          .order('id', ascending: true);
      
      return (response as List).map((data) => Store.fromMap(data)).toList();
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
