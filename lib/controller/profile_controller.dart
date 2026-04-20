import 'package:flutter/material.dart';
import '../model/profile_model.dart';
import '../service/profile_service.dart';
import '../service/supabase_conn.dart';

class ProfileController extends ChangeNotifier {
  final ProfileService _profileService = ProfileService();

  ProfileModel? profile;
  bool isLoading = false;

  // Dashboard data
  Map<String, dynamic>?    todayLog;
  List<Map<String, dynamic>> weeklyHistory  = [];
  List<Map<String, dynamic>> monthlyHistory = [];
  DateTime selectedMonth = DateTime.now();

  // ── Load Profile ──────────────────────────────────────────────────────────
  Future<void> loadProfile() async {
    isLoading = true;
    notifyListeners();

    try {
      profile = await _profileService.fetchProfile();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Update Profile ────────────────────────────────────────────────────────
  Future<bool> updateProfile(ProfileModel updated) async {
    isLoading = true;
    notifyListeners();

    try {
      await _profileService.updateProfile(updated);
      profile = updated;
      return true;
    } catch (_) {
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Load Dashboard Data ───────────────────────────────────────────────────
  Future<void> loadDashboardData() async {
    isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        _loadProfile(),
        _loadTodayLog(),
        _loadWeeklyHistory(),
        _loadMonthlyHistory(),
        loadUserName(),           // loads first_name/last_name from public.user
      ]);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadProfile() async {
    profile ??= await _profileService.fetchProfile();
  }

  Future<void> _loadTodayLog() async {
    todayLog = await _profileService.fetchTodayLog();
  }

  Future<void> _loadWeeklyHistory() async {
    weeklyHistory = await _profileService.fetchWeeklyHistory();
  }

  Future<void> _loadMonthlyHistory() async {
    monthlyHistory = await _profileService.fetchMonthlyHistory(targetMonth: selectedMonth);
  }

  // ── Month Selection ───────────────────────────────────────────────────────
  Future<void> changeMonth(DateTime newMonth) async {
    selectedMonth = newMonth;
    isLoading = true;
    notifyListeners();
    try {
      await _loadMonthlyHistory();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Computed dashboard helpers ────────────────────────────────────────────
  double get todayCalories  => (todayLog?['total_calories']  as num?)?.toDouble() ?? 0;
  double get todayProtein   => (todayLog?['total_protein_g'] as num?)?.toDouble() ?? 0;
  double get todayCarbs     => (todayLog?['total_carbs_g']   as num?)?.toDouble() ?? 0;
  double get todayFat       => (todayLog?['total_fat_g']     as num?)?.toDouble() ?? 0;

  double get calorieGoal  => profile?.dailyCalorieGoal ?? 2000;
  double get proteinGoal  => profile?.proteinGoalG ?? 50;
  double get carbsGoal    => profile?.carbsGoalG ?? 250;
  double get fatGoal      => profile?.fatGoalG ?? 56;

  double get calorieProgress => calorieGoal > 0 ? (todayCalories / calorieGoal).clamp(0, 1) : 0;
  double get proteinProgress => proteinGoal > 0 ? (todayProtein  / proteinGoal).clamp(0, 1) : 0;
  double get carbsProgress   => carbsGoal   > 0 ? (todayCarbs    / carbsGoal).clamp(0, 1)   : 0;
  double get fatProgress     => fatGoal     > 0 ? (todayFat      / fatGoal).clamp(0, 1)     : 0;

  // ── User display name (from public.user, not profiles) ───────────────────
  // Name lives in public.user, not profiles — loaded separately.
  String? _firstName;
  String? _lastName;
  String? _userPhone;

  /// Call after login to cache the user's name from public.user table.
  Future<void> loadUserName() async {
    try {
      final uid = supabase.auth.currentUser?.id;
      if (uid == null) return;
      final row = await supabase
          .from('user')
          .select('first_name, last_name, phone')
          .eq('user_id', uid)
          .maybeSingle();
      if (row != null) {
        _firstName = row['first_name'] as String?;
        _lastName  = row['last_name']  as String?;
        _userPhone = row['phone']       as String?;
        notifyListeners();
      }
    } catch (_) {}
  }

  // Public getters for UI
  String get firstName => _firstName ?? '';
  String get lastName  => _lastName  ?? '';
  String get userPhone => _userPhone  ?? '';

  String get displayName {
    if (_firstName != null && _firstName!.isNotEmpty) return _firstName!;
    return supabase.auth.currentUser?.email?.split('@').first ?? 'there';
  }

  String get fullDisplayName {
    final parts = [_firstName, _lastName]
        .where((p) => p != null && p.isNotEmpty)
        .toList();
    return parts.isNotEmpty ? parts.join(' ') : displayName;
  }
}
