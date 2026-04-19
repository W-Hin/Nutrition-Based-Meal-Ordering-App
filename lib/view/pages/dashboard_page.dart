import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../controller/profile_controller.dart';
import '../../controller/store_controller.dart';
import '../../service/supabase_conn.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Dashboard Page  (Daily | Weekly | Monthly tabs)
// ─────────────────────────────────────────────────────────────────────────────
class HomeDashboardPage extends StatefulWidget {
  const HomeDashboardPage({super.key});
  @override
  State<HomeDashboardPage> createState() => _HomeDashboardPageState();
}

class _HomeDashboardPageState extends State<HomeDashboardPage>
    with SingleTickerProviderStateMixin {
  static const _cream  = Color(0xFFF5F0E8);
  static const _green  = Color(0xFF1E4620);
  static const _orange = Color(0xFFD95B2B);
  static const _dark   = Color(0xFF2D2D2D);

  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileController>().loadDashboardData();
      context.read<StoreController>().initLocationBasedStore();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _initials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final p = name.trim().split(' ');
    if (p.length == 1) return p[0][0].toUpperCase();
    return '${p[0][0]}${p[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl    = context.watch<ProfileController>();
    final profile = ctrl.profile;

    return Scaffold(
      backgroundColor: _cream,
      body: RefreshIndicator(
        color: _orange,
        onRefresh: () => ctrl.loadDashboardData(),
        child: CustomScrollView(
          slivers: [
            // ── App Bar ────────────────────────────────────────────────────
            SliverAppBar(
              backgroundColor: _green,
              expandedHeight: 110,
              floating: false,
              pinned: true,
              elevation: 0,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: Row(
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: _orange,
                          child: Text(
                            _initials(profile?.fullName),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${_greeting()}, ${ctrl.displayName}',
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                              ),
                              if (profile?.bmi != null)
                                Text(
                                  'BMI: ${profile!.bmi!.toStringAsFixed(1)} (${profile.bmiCategory})',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // ── Tab bar ───────────────────────────────────────────────────
              bottom: TabBar(
                controller: _tab,
                indicatorColor: _orange,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.5),
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                tabs: const [
                  Tab(text: 'Daily'),
                  Tab(text: 'Weekly'),
                  Tab(text: 'Monthly'),
                ],
              ),
            ),

            // ── Tab views ──────────────────────────────────────────────────
            SliverFillRemaining(
              child: ctrl.isLoading
                  ? const Center(child: CircularProgressIndicator(color: _orange))
                  : TabBarView(
                      controller: _tab,
                      children: [
                        _DailyTab(ctrl: ctrl),
                        _WeeklyTab(ctrl: ctrl),
                        _MonthlyTab(ctrl: ctrl),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DAILY TAB
// ─────────────────────────────────────────────────────────────────────────────
class _DailyTab extends StatelessWidget {
  final ProfileController ctrl;
  const _DailyTab({required this.ctrl});

  static const _cream  = Color(0xFFF5F0E8);
  static const _green  = Color(0xFF1E4620);
  static const _orange = Color(0xFFD95B2B);
  static const _dark   = Color(0xFF2D2D2D);

  @override
  Widget build(BuildContext context) {
    final consumed  = ctrl.todayCalories;
    final goal      = ctrl.calorieGoal;
    final progress  = ctrl.calorieProgress;
    final pct       = (progress * 100).toInt();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // ── Calorie Card ──────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Color(0xFFEFF6E8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_pin, color: _green, size: 16),
                  const SizedBox(width: 4),
                  Text('Daily calories', style: TextStyle(fontSize: 13, color: _dark.withValues(alpha: 0.6), fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // big percentage
                  Text('$pct%', style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: _dark)),
                  const Spacer(),
                  // ring chart
                  SizedBox(
                    width: 110, height: 110,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            startDegreeOffset: -90,
                            sectionsSpace: 0,
                            centerSpaceRadius: 36,
                            sections: [
                              PieChartSectionData(
                                value: progress * 100,
                                color: _green,
                                radius: 18,
                                showTitle: false,
                              ),
                              PieChartSectionData(
                                value: (1 - progress) * 100,
                                color: Colors.white.withValues(alpha: 0.4),
                                radius: 16,
                                showTitle: false,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              consumed.toStringAsFixed(0),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _dark),
                            ),
                            Text(
                              goal.toStringAsFixed(0),
                              style: TextStyle(fontSize: 11, color: _dark.withValues(alpha: 0.45)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Nutritions Card ───────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: _dark.withValues(alpha: 0.05), blurRadius: 10)],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Color(0xFF888888)),
                  const SizedBox(width: 8),
                  const Text('Nutritions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _dark)),
                  const Spacer(),
                  const Icon(Icons.chevron_right, size: 18, color: Color(0xFF888888)),
                ],
              ),
              const SizedBox(height: 14),
              _macroBar('Carbs',   ctrl.todayCarbs,   ctrl.carbsGoal,   Colors.red.shade400),
              _macroBar('Fat',     ctrl.todayFat,     ctrl.fatGoal,     Colors.orange.shade400),
              _macroBar('Protein', ctrl.todayProtein, ctrl.proteinGoal, Colors.blue.shade400),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Meal of Today ─────────────────────────────────────────────────
        const Text('Meal Of Today', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _dark)),
        const SizedBox(height: 12),

        // Breakfast
        _mealCard(
          label: 'Breakfast',
          done: consumed > 0,
          icon: '🥑',
          kcal: (consumed * 0.3).toInt(),
          fat: ctrl.todayFat * 0.3,
          carbs: ctrl.todayCarbs * 0.3,
          protein: ctrl.todayProtein * 0.3,
        ),
        _mealCard(
          label: 'Lunch',
          done: consumed > 0,
          icon: '🍚',
          kcal: (consumed * 0.4).toInt(),
          fat: ctrl.todayFat * 0.4,
          carbs: ctrl.todayCarbs * 0.4,
          protein: ctrl.todayProtein * 0.4,
        ),
        _mealCard(
          label: 'Dinner',
          done: false,
          icon: '🥗',
          kcal: (consumed * 0.3).toInt(),
          fat: ctrl.todayFat * 0.3,
          carbs: ctrl.todayCarbs * 0.3,
          protein: ctrl.todayProtein * 0.3,
        ),
      ],
    );
  }

  Widget _macroBar(String label, double current, double goal, Color color) {
    final pct   = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;
    final p     = (pct * 100).toInt();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$p%  $label', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _dark.withValues(alpha: 0.7))),
              Text('${current.toStringAsFixed(1)}/${goal.toStringAsFixed(0)} g',
                  style: TextStyle(fontSize: 11, color: _dark.withValues(alpha: 0.45))),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 7,
              backgroundColor: const Color(0xFFF0ECE4),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mealCard({
    required String label,
    required bool done,
    required String icon,
    required int kcal,
    required double fat,
    required double carbs,
    required double protein,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: _dark.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Row(
        children: [
          // food icon circle
          Container(
            width: 54, height: 54,
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 28))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _dark)),
                    if (done) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 18, height: 18,
                        decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle),
                        child: const Icon(Icons.check, color: Colors.white, size: 12),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                _macroLine(Colors.grey, '$kcal / ${(kcal * 1.2).toInt()} cal'),
                _macroLine(Colors.red.shade300,    '${fat.toStringAsFixed(0)} / ${(fat * 2).toStringAsFixed(0)} g fat'),
                _macroLine(Colors.orange.shade300, '${carbs.toStringAsFixed(0)} / ${(carbs * 2).toStringAsFixed(0)} g carbs'),
                _macroLine(Colors.blue.shade300,   '${protein.toStringAsFixed(0)} / ${(protein * 2).toStringAsFixed(0)} g protein'),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: done ? _green : _orange.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_forward,
              size: 18,
              color: done ? Colors.white : _orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroLine(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Container(width: 8, height: 3, color: color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 11, color: _dark.withValues(alpha: 0.55))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  WEEKLY TAB
// ─────────────────────────────────────────────────────────────────────────────
class _WeeklyTab extends StatelessWidget {
  final ProfileController ctrl;
  const _WeeklyTab({required this.ctrl});

  static const _green  = Color(0xFF1E4620);
  static const _orange = Color(0xFFD95B2B);
  static const _dark   = Color(0xFF2D2D2D);

  @override
  Widget build(BuildContext context) {
    final history = ctrl.weeklyHistory;
    final goal    = ctrl.calorieGoal;
    final today   = DateTime.now();
    final days    = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    final maxY    = (goal * 1.4).ceilToDouble();

    // compute 7-day data
    final cals    = days.map((d) {
      final key = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
      final log = history.firstWhere((h) => h['log_date'] == key, orElse: () => {});
      return log.isNotEmpty ? (log['total_calories'] as num).toDouble() : 0.0;
    }).toList();

    final daysLogged   = cals.where((c) => c > 0).length;
    final totalCal     = cals.fold<double>(0, (a, b) => a + b);
    final avgCal       = daysLogged > 0 ? totalCal / daysLogged : 0.0;
    final goalHit      = cals.where((c) => c >= goal).length;
    final dayLabels    = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // ── Summary strip ─────────────────────────────────────────────────
        Row(children: [
          _statBox('Days Logged',   '$daysLogged / 7', Colors.blue.shade400),
          const SizedBox(width: 10),
          _statBox('Avg Cal/day',   '${avgCal.toStringAsFixed(0)} kcal', _orange),
          const SizedBox(width: 10),
          _statBox('Goal Hit',      '$goalHit days', _green),
        ]),
        const SizedBox(height: 16),

        // ── Bar chart card ────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: _dark.withValues(alpha: 0.06), blurRadius: 16)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('7-Day Calorie History', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _dark)),
              Text('Target: ${goal.toStringAsFixed(0)} kcal / day',
                  style: TextStyle(fontSize: 11, color: _dark.withValues(alpha: 0.45))),
              const SizedBox(height: 16),
              SizedBox(
                height: 190,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY,
                    barGroups: List.generate(7, (i) {
                      final cal = cals[i];
                      final isToday = days[i].day == today.day;
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY:   cal,
                            color: cal >= goal ? _green : (cal > 0 ? _orange : const Color(0xFFE0E0E0)),
                            width: 22,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true, toY: maxY,
                              color: const Color(0xFFF5F2EE),
                            ),
                          ),
                        ],
                      );
                    }),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: goal / 2,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: _dark.withValues(alpha: 0.07), strokeWidth: 1,
                      ),
                    ),
                    extraLinesData: ExtraLinesData(horizontalLines: [
                      HorizontalLine(
                        y: goal,
                        color: _green.withValues(alpha: 0.5),
                        strokeWidth: 1.5,
                        dashArray: [6, 4],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          labelResolver: (_) => 'Goal',
                          style: TextStyle(fontSize: 10, color: _green.withValues(alpha: 0.7), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ]),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles:   AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles:  AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles:    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, m) {
                            final i   = v.toInt();
                            final day = days[i];
                            final isToday = day.day == today.day;
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                dayLabels[day.weekday - 1],
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                                  color: isToday ? _orange : _dark.withValues(alpha: 0.5),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Per-day breakdown list ─────────────────────────────────────────
        const Text('Day Breakdown', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _dark)),
        const SizedBox(height: 10),
        ...List.generate(7, (i) {
          final day = days[i];
          final cal = cals[i];
          final pct = goal > 0 ? (cal / goal).clamp(0.0, 1.0) : 0.0;
          final isToday   = day.day == today.day;
          final hitGoal   = cal >= goal && cal > 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isToday ? _green.withValues(alpha: 0.06) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: isToday ? Border.all(color: _green.withValues(alpha: 0.2)) : null,
              boxShadow: [BoxShadow(color: _dark.withValues(alpha: 0.04), blurRadius: 6)],
            ),
            child: Row(children: [
              SizedBox(
                width: 38,
                child: Text(
                  dayLabels[day.weekday - 1],
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: isToday ? _green : _dark.withValues(alpha: 0.55),
                  ),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFF0ECE4),
                    valueColor: AlwaysStoppedAnimation(hitGoal ? _green : (cal > 0 ? _orange : Colors.grey.shade300)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                cal > 0 ? '${cal.toStringAsFixed(0)} kcal' : '—',
                style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: hitGoal ? _green : _dark.withValues(alpha: 0.6),
                ),
              ),
            ]),
          );
        }),
      ],
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: _dark.withValues(alpha: 0.55))),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  MONTHLY TAB
// ─────────────────────────────────────────────────────────────────────────────
class _MonthlyTab extends StatelessWidget {
  final ProfileController ctrl;
  const _MonthlyTab({required this.ctrl});

  static const _green  = Color(0xFF1E4620);
  static const _orange = Color(0xFFD95B2B);
  static const _dark   = Color(0xFF2D2D2D);

  static const _monthNames = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ];

  @override
  Widget build(BuildContext context) {
    final history = ctrl.monthlyHistory;
    final goal    = ctrl.calorieGoal;
    final now     = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);

    // build per-day map
    final Map<int, double> dayMap = {};
    for (final row in history) {
      final date = DateTime.tryParse(row['log_date'] as String? ?? '');
      if (date != null) {
        dayMap[date.day] = (row['total_calories'] as num).toDouble();
      }
    }

    final daysLogged  = dayMap.length;
    final totalCal    = dayMap.values.fold<double>(0, (a, b) => a + b);
    final avgCal      = daysLogged > 0 ? totalCal / daysLogged : 0.0;
    final goalHit     = dayMap.values.where((c) => c >= goal).length;
    final adherence   = daysLogged > 0 ? (goalHit / daysLogged * 100).toInt() : 0;

    // line chart spots
    final spots = List.generate(daysInMonth, (i) {
      final day = i + 1;
      return FlSpot(day.toDouble(), dayMap[day] ?? 0);
    });

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // ── Month header ─────────────────────────────────────────────────
        Text(
          '${_monthNames[now.month - 1]} ${now.year}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _dark),
        ),
        const SizedBox(height: 14),

        // ── Summary strip ─────────────────────────────────────────────────
        Row(children: [
          _statBox('Days Logged',  '$daysLogged days', Colors.blue.shade400),
          const SizedBox(width: 10),
          _statBox('Total Cals',   '${(totalCal / 1000).toStringAsFixed(1)}k kcal', _orange),
          const SizedBox(width: 10),
          _statBox('Goal Achieved','$adherence%', _green),
        ]),
        const SizedBox(height: 16),

        // ── Line chart ────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: _dark.withValues(alpha: 0.06), blurRadius: 16)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Calorie Trend', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _dark)),
              Text('Daily goal: ${goal.toStringAsFixed(0)} kcal',
                  style: TextStyle(fontSize: 11, color: _dark.withValues(alpha: 0.45))),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: LineChart(
                  LineChartData(
                    minX: 1, maxX: daysInMonth.toDouble(),
                    minY: 0, maxY: (goal * 1.5).ceilToDouble(),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots.where((s) => s.y > 0).toList(),
                        isCurved: true,
                        color: _orange,
                        barWidth: 2.5,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (s, _, __, ___) => FlDotCirclePainter(
                            radius: 3,
                            color: s.y >= goal ? _green : _orange,
                            strokeWidth: 0,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: _orange.withValues(alpha: 0.08),
                        ),
                      ),
                    ],
                    extraLinesData: ExtraLinesData(horizontalLines: [
                      HorizontalLine(
                        y: goal,
                        color: _green.withValues(alpha: 0.5),
                        strokeWidth: 1.5,
                        dashArray: [6, 4],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          labelResolver: (_) => 'Goal',
                          style: TextStyle(fontSize: 10, color: _green.withValues(alpha: 0.7), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ]),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: goal / 2,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: _dark.withValues(alpha: 0.06), strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 7,
                          getTitlesWidget: (v, _) => Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${v.toInt()}',
                              style: TextStyle(fontSize: 10, color: _dark.withValues(alpha: 0.45)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Calendar heatmap grid ─────────────────────────────────────────
        const Text('Calorie Heatmap', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _dark)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: _dark.withValues(alpha: 0.05), blurRadius: 10)],
          ),
          child: Column(
            children: [
              // day-of-week headers
              Row(
                children: ['M','T','W','T','F','S','S'].map((d) => Expanded(
                  child: Center(child: Text(d, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _dark.withValues(alpha: 0.4)))),
                )).toList(),
              ),
              const SizedBox(height: 8),
              // build calendar grid
              _buildCalendarGrid(now, daysInMonth, dayMap, goal),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Legend ───────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legendBox(Colors.grey.shade200, 'No data'),
            const SizedBox(width: 12),
            _legendBox(_orange.withValues(alpha: 0.4), 'Below goal'),
            const SizedBox(width: 12),
            _legendBox(_green, 'Goal met'),
          ],
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(DateTime now, int daysInMonth, Map<int,double> dayMap, double goal) {
    final firstWeekday = DateTime(now.year, now.month, 1).weekday; // 1=Mon
    final totalCells   = firstWeekday - 1 + daysInMonth;
    final rows         = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: List.generate(7, (col) {
              final dayNum = row * 7 + col - (firstWeekday - 1) + 1;
              if (dayNum < 1 || dayNum > daysInMonth) {
                return const Expanded(child: SizedBox(height: 32));
              }
              final cal    = dayMap[dayNum] ?? 0;
              final isToday = dayNum == now.day;
              Color bg = Colors.grey.shade100;
              if (cal > 0) {
                bg = cal >= goal ? _green : _orange.withValues(alpha: 0.35 + (cal / goal * 0.3).clamp(0, 0.5));
              }
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(6),
                      border: isToday ? Border.all(color: _orange, width: 2) : null,
                    ),
                    child: Center(
                      child: Text(
                        '$dayNum',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                          color: cal > 0 ? Colors.white.withValues(alpha: 0.9) : _dark.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: _dark.withValues(alpha: 0.55))),
          ],
        ),
      ),
    );
  }

  Widget _legendBox(Color color, String label) {
    return Row(children: [
      Container(width: 14, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 11, color: _dark.withValues(alpha: 0.55))),
    ]);
  }
}
