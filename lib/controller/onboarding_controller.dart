import 'package:flutter/material.dart';
import '../model/profile_model.dart';
import '../service/profile_service.dart';
import '../service/address_service.dart';
import '../model/address_model.dart';
import '../service/supabase_conn.dart';

class OnboardingController extends ChangeNotifier {
  final ProfileService _profileService = ProfileService();
  final AddressService _addressService = AddressService();

  // ── Step 1: Personal Details ───────────────────────────────────────────────
  String    fullName   = '';
  String    phone      = '';
  DateTime? dob;
  String    gender     = 'Male';
  double    heightCm   = 165;
  double    weightKg   = 60;

  // ── Calculated values (populated after calculateBmiAndCalories()) ──────────
  double? bmi;
  String  bmiCategory     = '';
  double? dailyCalorieGoal;
  double? proteinGoalG;
  double? carbsGoalG;
  double? fatGoalG;
  String _activityLevel   = 'Sedentary';
  String get activityLevel => _activityLevel;
  set activityLevel(String v) {
    _activityLevel = v;
    notifyListeners();
  }

  // ── Step 3: Address ────────────────────────────────────────────────────────
  bool   isDefaultAddress      = true;
  String deliveryLabel         = 'Home';
  String deliveryInstruction   = '';
  String street                = '';
  String city                  = '';
  String state                 = 'Selangor';
  String postcode              = '';

  bool isSaving = false;

  // ── BMI & Calorie Calculation ─────────────────────────────────────────────
  /// Uses Harris-Benedict equation + activity multiplier.
  void calculateBmiAndCalories() {
    if (heightCm <= 0 || weightKg <= 0) return;

    final h = heightCm / 100;
    bmi = weightKg / (h * h);

    // BMI category
    if (bmi! < 18.5) {
      bmiCategory = 'Underweight';
    } else if (bmi! < 25.0) {
      bmiCategory = 'Normal';
    } else if (bmi! < 30.0) {
      bmiCategory = 'Overweight';
    } else {
      bmiCategory = 'Obese';
    }

    // Age from DOB
    final age = dob != null
        ? (DateTime.now().difference(dob!).inDays / 365).floor()
        : 25;

    // BMR (Harris-Benedict)
    double bmr;
    if (gender == 'Male') {
      bmr = 88.362 + (13.397 * weightKg) + (4.799 * heightCm) - (5.677 * age);
    } else {
      bmr = 447.593 + (9.247 * weightKg) + (3.098 * heightCm) - (4.330 * age);
    }

    // Activity multiplier
    final multiplier = _activityMultiplier(activityLevel);
    dailyCalorieGoal = bmr * multiplier;

    // Macro split: 25% protein / 50% carbs / 25% fat
    proteinGoalG = dailyCalorieGoal! * 0.25 / 4; // 4 kcal/g
    carbsGoalG   = dailyCalorieGoal! * 0.50 / 4;
    fatGoalG     = dailyCalorieGoal! * 0.25 / 9; // 9 kcal/g

    notifyListeners();
  }

  double _activityMultiplier(String level) {
    switch (level) {
      case 'Lightly Active':   return 1.375;
      case 'Moderately Active': return 1.55;
      case 'Very Active':       return 1.725;
      case 'Extra Active':      return 1.9;
      default:                  return 1.2; // Sedentary
    }
  }

  // ── Healthy weight range ──────────────────────────────────────────────────
  String get healthyWeightRange {
    final h = heightCm / 100;
    final low  = (18.5 * h * h).toStringAsFixed(1);
    final high = (24.9 * h * h).toStringAsFixed(1);
    return '$low kg – $high kg';
  }

  // ── Save profile to Supabase ──────────────────────────────────────────────
  Future<bool> saveProfile() async {
    isSaving = true;
    notifyListeners();

    try {
      final uid = supabase.auth.currentUser!.id;

      // Calculate age from DOB
      final age = dob != null
          ? (DateTime.now().difference(dob!).inDays / 365).floor()
          : null;

      final profile = ProfileModel(
        userId:          uid,
        fullName:        fullName,
        phone:           phone,
        heightCm:        heightCm,
        weightKg:        weightKg,
        age:             age,
        gender:          gender,
        activityLevel:   activityLevel,
        bmi:             bmi,
        dailyCalorieGoal: dailyCalorieGoal,
        proteinGoalG:    proteinGoalG,
        carbsGoalG:      carbsGoalG,
        fatGoalG:        fatGoalG,
      );

      await _profileService.createProfile(profile);

      // Also update the full_name and phone in public.users
      await supabase.from('users').update({
        'full_name': fullName,
        'phone':     phone,
      }).eq('id', uid);

      return true;
    } catch (e) {
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  // ── Save address to Supabase ───────────────────────────────────────────────
  Future<bool> saveAddress() async {
    try {
      final address = AddressModel(
        name:    fullName,
        phone:   phone,
        address: '$street, $city, $state $postcode',
        label:   AddressLabel.home,
      );
      await _addressService.saveAddress(address);
      return true;
    } catch (e) {
      return false;
    }
  }

  void setDob(DateTime date) {
    dob = date;
    notifyListeners();
  }

  void setGender(String g) {
    gender = g;
    notifyListeners();
  }
}
