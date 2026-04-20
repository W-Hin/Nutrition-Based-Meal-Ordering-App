import '../model/profile_model.dart';
import 'supabase_conn.dart';

class ProfileService {
  String get _uid => supabase.auth.currentUser?.id ?? '';
  // ── Profile CRUD ─────────────────────────────────────────────────────────

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

  // ── Calorie log: upsert today's totals ───────────────────────────────────
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

  // ── Fetch today's calorie log ─────────────────────────────────────────────
  Future<Map<String, dynamic>?> fetchTodayLog() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return await supabase
        .from('calorie_logs')
        .select()
        .eq('user_id', _uid)
        .eq('log_date', today)
        .maybeSingle();
  }

  // ── Fetch last 7 days for the weekly chart ────────────────────────────────
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

  // ── Fetch specific month for the monthly chart ─────────────────────────────
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
}

