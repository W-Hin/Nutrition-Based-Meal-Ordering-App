import '../model/profile_model.dart';
import 'supabase_conn.dart';

class ProfileService {
  String get _uid => supabase.auth.currentUser?.id ?? '';
  // Profile CRUD

  Future<void> createProfile(ProfileModel profile) async {
    await supabase.from('profiles').insert(profile.toMap());
  }

  Future<ProfileModel?> fetchProfile() async {
    final row = await supabase
        .from('profiles')
        .select()
        .eq('user_id', _uid)
        .maybeSingle();
    return row != null ? ProfileModel.fromMap(row) : null;
  }

  Future<void> updateProfile(ProfileModel profile) async {
    await supabase
        .from('profiles')
        .update(profile.toMap())
        .eq('user_id', _uid);
  }

  // Calorie log: upsert today's totals
  /// Called after an order is placed. Adds calories to today's log.
  Future<void> upsertCalorieLog({
    required double calories,
    required double proteinG,
    required double carbsG,
    required double fatG,
  }) async {
    final today = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD

    // Try fetch existing log for today
    final existing = await supabase
        .from('calorie_logs')
        .select()
        .eq('user_id', _uid)
        .eq('log_date', today)
        .maybeSingle();

    if (existing == null) {
      await supabase.from('calorie_logs').insert({
        'user_id':         _uid,
        'log_date':        today,
        'total_calories':  calories,
        'total_protein_g': proteinG,
        'total_carbs_g':   carbsG,
        'total_fat_g':     fatG,
      });
    } else {
      await supabase.from('calorie_logs').update({
        'total_calories':  (existing['total_calories'] as num).toDouble() + calories,
        'total_protein_g': (existing['total_protein_g'] as num).toDouble() + proteinG,
        'total_carbs_g':   (existing['total_carbs_g'] as num).toDouble() + carbsG,
        'total_fat_g':     (existing['total_fat_g'] as num).toDouble() + fatG,
      })
          .eq('user_id', _uid)
          .eq('log_date', today);
    }
  }

  // Fetch today's calorie log
  Future<Map<String, dynamic>?> fetchTodayLog() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return await supabase
        .from('calorie_logs')
        .select()
        .eq('user_id', _uid)
        .eq('log_date', today)
        .maybeSingle();
  }

  // Fetch last 7 days for the weekly chart
  Future<List<Map<String, dynamic>>> fetchWeeklyHistory() async {
    final now = DateTime.now();
    // Monday is weekday=1, so subtract (weekday - 1)
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = monday.toIso8601String().substring(0, 10);

    final rows = await supabase
        .from('calorie_logs')
        .select()
        .eq('user_id', _uid)
        .gte('log_date', startOfWeek)
        .order('log_date', ascending: true);

    return List<Map<String, dynamic>>.from(rows);
  }

  // Fetch specific month for the monthly chart
  Future<List<Map<String, dynamic>>> fetchMonthlyHistory({DateTime? targetMonth}) async {
    final monthObj = targetMonth ?? DateTime.now();
    final firstDay = '${monthObj.year}-${monthObj.month.toString().padLeft(2, '0')}-01';

    // Calculate the start of the exact next month to act as a strict < upper boundary
    final nextMonth = DateTime(monthObj.year, monthObj.month + 1, 1);
    final lastDay = '${nextMonth.year}-${nextMonth.month.toString().padLeft(2, '0')}-01';

    final rows = await supabase
        .from('calorie_logs')
        .select()
        .eq('user_id', _uid)
        .gte('log_date', firstDay)
        .lt('log_date', lastDay)
        .order('log_date', ascending: true);

    return List<Map<String, dynamic>>.from(rows);
  }

  // Fetch today's completed orders (for Meal of Today)
  Future<List<Map<String, dynamic>>> fetchTodayOrders() async {
    final now        = DateTime.now().toLocal();
    final startOfDay = DateTime(now.year, now.month, now.day).toUtc().toIso8601String();
    final endOfDay   = DateTime(now.year, now.month, now.day, 23, 59, 59).toUtc().toIso8601String();

    final rows = await supabase
        .from('orders')
        .select('order_id, order_date, total, status, total_cal, total_pro, total_carb, total_fat, order_items(name, price, image_url, food_id)')
        .eq('user_id', _uid)
        .eq('status', 'completed')
        .gte('order_date', startOfDay)
        .lte('order_date', endOfDay)
        .order('order_date', ascending: true);

    return List<Map<String, dynamic>>.from(rows);
  }

  // Fetch weekly order stats (count + spend)
  Future<Map<String, dynamic>> fetchWeeklyOrderStats() async {
    final now    = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final start  = DateTime(monday.year, monday.month, monday.day).toUtc().toIso8601String();

    final rows = await supabase
        .from('orders')
        .select('total')
        .eq('user_id', _uid)
        .neq('status', 'cancelled')
        .gte('order_date', start);

    final list       = List<Map<String, dynamic>>.from(rows);
    final totalSpend = list.fold<double>(0, (s, r) => s + ((r['total'] as num?)?.toDouble() ?? 0));
    return {'count': list.length, 'spend': totalSpend};
  }

  // Fetch monthly order stats (count + spend)
  Future<Map<String, dynamic>> fetchMonthlyOrderStats({DateTime? targetMonth}) async {
    final m     = targetMonth ?? DateTime.now();
    final start = DateTime(m.year, m.month, 1).toUtc().toIso8601String();
    final end   = DateTime(m.year, m.month + 1, 1).toUtc().toIso8601String();

    final rows = await supabase
        .from('orders')
        .select('total')
        .eq('user_id', _uid)
        .neq('status', 'cancelled')
        .gte('order_date', start)
        .lt('order_date', end);

    final list       = List<Map<String, dynamic>>.from(rows);
    final totalSpend = list.fold<double>(0, (s, r) => s + ((r['total'] as num?)?.toDouble() ?? 0));
    return {'count': list.length, 'spend': totalSpend};
  }

  // Fetch top ordered items for a given date range
  Future<List<Map<String, dynamic>>> fetchTopOrderedItems({
    required String startDate,
    required String endDate,
    int limit = 3,
  }) async {
    final orderRows = await supabase
        .from('orders')
        .select('order_id')
        .eq('user_id', _uid)
        .neq('status', 'cancelled')
        .gte('order_date', startDate)
        .lt('order_date', endDate);

    if ((orderRows as List).isEmpty) return [];
    final orderIds = orderRows.map((r) => r['order_id']).toList();

    final itemRows = await supabase
        .from('order_items')
        .select('name, image_url, food_id')
        .inFilter('order_id', orderIds);

    // Count by name
    final Map<String, Map<String, dynamic>> freq = {};
    for (final row in List<Map<String, dynamic>>.from(itemRows)) {
      final name = row['name'] as String? ?? 'Unknown';
      if (freq.containsKey(name)) {
        freq[name]!['count'] = (freq[name]!['count'] as int) + 1;
      } else {
        freq[name] = {'name': name, 'image_url': row['image_url'], 'food_id': row['food_id'], 'count': 1};
      }
    }

    final sorted = freq.values.toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    return sorted.take(limit).toList();
  }

  // UPSERT Calorie Log For Admin Use
  static Future<void> upsertCalorieLogForUser({
    required String userId,
    required double calories,
    required double proteinG,
    required double carbsG,
    required double fatG,
  }) async {
    final now = DateTime.now();
    final todayStr = now.toIso8601String().substring(0, 10);

    // 1. Try to fetch existing log for today
    final response = await supabase
        .from('calorie_logs')
        .select()
        .eq('user_id', userId)
        .eq('log_date', todayStr)
        .maybeSingle();

    if (response == null) {
      // 2. Insert new log
      await supabase.from('calorie_logs').insert({
        'user_id': userId,
        'log_date': todayStr,
        'total_calories': calories,
        'total_protein_g': proteinG,
        'total_carbs_g': carbsG,
        'total_fat_g': fatG,
      });
    } else {
      // 3. Update existing log
      final currentCal = (response['total_calories'] as num?)?.toDouble() ?? 0;
      final currentPro = (response['total_protein_g'] as num?)?.toDouble() ?? 0;
      final currentCarb = (response['total_carbs_g'] as num?)?.toDouble() ?? 0;
      final currentFat = (response['total_fat_g'] as num?)?.toDouble() ?? 0;

      await supabase.from('calorie_logs').update({
        'total_calories': currentCal + calories,
        'total_protein_g': currentPro + proteinG,
        'total_carbs_g': currentCarb + carbsG,
        'total_fat_g': currentFat + fatG,
      }).eq('id', response['id']);
    }
  }
}
