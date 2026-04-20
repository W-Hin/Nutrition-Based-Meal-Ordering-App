class ProfileModel {
  final String? id;
  final String userId;
  final DateTime? dateOfBirth;   // replaces age
  final String? gender;
  final double? heightCm;
  final double? weightKg;
  final double? bmi;
  final double? dailyCalorieGoal;
  final double? proteinGoalG;
  final double? carbsGoalG;
  final double? fatGoalG;
  final DateTime? updatedAt;

  const ProfileModel({
    this.id,
    required this.userId,
    this.dateOfBirth,
    this.gender,
    this.heightCm,
    this.weightKg,
    this.bmi,
    this.dailyCalorieGoal,
    this.proteinGoalG,
    this.carbsGoalG,
    this.fatGoalG,
    this.updatedAt,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id:               map['id'] as String?,
      userId:           map['user_id'] as String? ?? '',
      dateOfBirth:      map['date_of_birth'] != null
          ? DateTime.tryParse(map['date_of_birth'])
          : null,
      gender:           map['gender'] as String?,
      heightCm:         (map['height_cm'] as num?)?.toDouble(),
      weightKg:         (map['weight_kg'] as num?)?.toDouble(),
      bmi:              (map['bmi'] as num?)?.toDouble(),
      dailyCalorieGoal: (map['daily_calorie_goal'] as num?)?.toDouble(),
      proteinGoalG:     (map['protein_goal_g'] as num?)?.toDouble(),
      carbsGoalG:       (map['carbs_goal_g'] as num?)?.toDouble(),
      fatGoalG:         (map['fat_goal_g'] as num?)?.toDouble(),
      updatedAt:        map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id':            userId,
        if (dateOfBirth != null)
          'date_of_birth':    dateOfBirth!.toIso8601String().substring(0, 10),
        if (gender != null)           'gender':              gender,
        if (heightCm != null)         'height_cm':           heightCm,
        if (weightKg != null)         'weight_kg':           weightKg,
        if (bmi != null)              'bmi':                 bmi,
        if (dailyCalorieGoal != null) 'daily_calorie_goal':  dailyCalorieGoal,
        if (proteinGoalG != null)     'protein_goal_g':      proteinGoalG,
        if (carbsGoalG != null)       'carbs_goal_g':        carbsGoalG,
        if (fatGoalG != null)         'fat_goal_g':          fatGoalG,
        'updated_at': DateTime.now().toIso8601String(),
      };

  // ── Calculated age from DOB ──────────────────────────────────────────────
  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  // ── BMI label ────────────────────────────────────────────────────────────
  String get bmiCategory {
    if (bmi == null) return '';
    if (bmi! < 18.5) return 'Underweight';
    if (bmi! < 25.0) return 'Normal';
    if (bmi! < 30.0) return 'Overweight';
    return 'Obese';
  }

  // ── Healthy weight range string ──────────────────────────────────────────
  String get healthyWeightRange {
    if (heightCm == null) return '';
    final h = heightCm! / 100;
    final low  = (18.5 * h * h).toStringAsFixed(1);
    final high = (24.9 * h * h).toStringAsFixed(1);
    return '$low kg – $high kg';
  }
}
