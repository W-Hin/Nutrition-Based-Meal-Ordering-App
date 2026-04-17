import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../controller/profile_controller.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const _cream  = Color(0xFFF5F0E8);
  static const _green  = Color(0xFF1E4620);
  static const _orange = Color(0xFFD95B2B);
  static const _dark   = Color(0xFF2D2D2D);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileController>().loadDashboardData();
    });
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ProfileController>();

    if (ctrl.isLoading) {
      return const Scaffold(
        backgroundColor: _cream,
        body: Center(child: CircularProgressIndicator(color: _orange)),
      );
    }

    return Scaffold(
      backgroundColor: _cream,
      body: RefreshIndicator(
        color: _orange,
        onRefresh: () => ctrl.loadDashboardData(),
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──────────────────────────────────────────────────────
            SliverAppBar(
              backgroundColor: _green,
              expandedHeight: 130,
              floating: false,
              pinned: true,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(color: _green),
                  padding: const EdgeInsets.fromLTRB(24, 56, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${_greeting()}, ${ctrl.displayName} 👋',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formattedDate(),
                        style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  // ── Calorie Ring Card ─────────────────────────────────────
                  _sectionTitle("Today's Calories"),
                  const SizedBox(height: 10),
                  _CalorieRingCard(ctrl: ctrl),
                  const SizedBox(height: 20),

                  // ── Macros ────────────────────────────────────────────────
                  _sectionTitle('Macronutrients'),
                  const SizedBox(height: 10),
                  _MacroCard(ctrl: ctrl),
                  const SizedBox(height: 20),

                  // ── Weekly Chart ──────────────────────────────────────────
                  _sectionTitle('Weekly Calorie History'),
                  const SizedBox(height: 10),
                  _WeeklyChart(history: ctrl.weeklyHistory, goal: ctrl.calorieGoal),
                  const SizedBox(height: 20),

                  // ── SDG Badge ─────────────────────────────────────────────
                  _SdgBadge(),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formattedDate() {
    final now = DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _dark),
      );
}

// ── Calorie Ring ──────────────────────────────────────────────────────────────
class _CalorieRingCard extends StatelessWidget {
  final ProfileController ctrl;
  const _CalorieRingCard({required this.ctrl});

  static const _orange = Color(0xFFD95B2B);
  static const _green  = Color(0xFF1E4620);
  static const _dark   = Color(0xFF2D2D2D);

  @override
  Widget build(BuildContext context) {
    final consumed = ctrl.todayCalories;
    final goal     = ctrl.calorieGoal;
    final remaining = (goal - consumed).clamp(0, double.infinity);
    final progress  = ctrl.calorieProgress;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _dark.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          // Ring chart
          SizedBox(
            width: 130, height: 130,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    startDegreeOffset: -90,
                    sectionsSpace: 0,
                    centerSpaceRadius: 44,
                    sections: [
                      PieChartSectionData(
                        value: progress * 100,
                        color: _orange,
                        radius: 20,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: (1 - progress) * 100,
                        color: const Color(0xFFF0ECE4),
                        radius: 18,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _orange),
                    ),
                    Text('of goal', style: TextStyle(fontSize: 10, color: _dark.withOpacity(0.5))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _calorieRow('Consumed',  consumed.toStringAsFixed(0), _orange),
                const Divider(height: 16),
                _calorieRow('Goal',      goal.toStringAsFixed(0),     _green),
                const Divider(height: 16),
                _calorieRow('Remaining', remaining.toStringAsFixed(0), Colors.grey.shade500),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _calorieRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: _dark.withOpacity(0.55))),
        Row(
          children: [
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(width: 2),
            Text('kcal', style: TextStyle(fontSize: 10, color: _dark.withOpacity(0.4))),
          ],
        ),
      ],
    );
  }
}

// ── Macro bars ────────────────────────────────────────────────────────────────
class _MacroCard extends StatelessWidget {
  final ProfileController ctrl;
  const _MacroCard({required this.ctrl});

  static const _dark = Color(0xFF2D2D2D);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _dark.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          _macroRow('Protein', ctrl.todayProtein, ctrl.proteinGoal, Colors.lightBlue.shade400, 'g'),
          const SizedBox(height: 14),
          _macroRow('Carbs',   ctrl.todayCarbs,   ctrl.carbsGoal,   Colors.amber.shade400,      'g'),
          const SizedBox(height: 14),
          _macroRow('Fat',     ctrl.todayFat,     ctrl.fatGoal,     Colors.pink.shade300,       'g'),
        ],
      ),
    );
  }

  Widget _macroRow(String label, double current, double goal, Color color, String unit) {
    final progress = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _dark.withOpacity(0.8))),
              ],
            ),
            Text(
              '${current.toStringAsFixed(0)} / ${goal.toStringAsFixed(0)} $unit',
              style: TextStyle(fontSize: 12, color: _dark.withOpacity(0.5)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: const Color(0xFFF0ECE4),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

// ── Weekly Bar Chart ──────────────────────────────────────────────────────────
class _WeeklyChart extends StatelessWidget {
  final List<Map<String, dynamic>> history;
  final double goal;

  const _WeeklyChart({required this.history, required this.goal});

  static const _orange = Color(0xFFD95B2B);
  static const _green  = Color(0xFF1E4620);
  static const _dark   = Color(0xFF2D2D2D);

  @override
  Widget build(BuildContext context) {
    // Build 7-day scaffold
    final today = DateTime.now();
    final days  = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    final maxY  = (goal * 1.3).ceilToDouble();

    final bars = days.map((day) {
      final key = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final log = history.firstWhere(
        (h) => h['log_date'] == key,
        orElse: () => {},
      );
      final cal = log.isNotEmpty ? (log['total_calories'] as num).toDouble() : 0.0;
      return BarChartGroupData(
        x: days.indexOf(day),
        barRods: [
          BarChartRodData(
            toY:   cal,
            color: cal >= goal ? _green : _orange,
            width: 18,
            borderRadius: BorderRadius.circular(6),
            backDrawRodData: BackgroundBarChartRodData(
              show:  true,
              toY:   maxY,
              color: const Color(0xFFF0ECE4),
            ),
          ),
        ],
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _dark.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _legend(_orange, 'Below goal'),
              const SizedBox(width: 12),
              _legend(_green, 'Goal reached'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barGroups: bars,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: goal / 2,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: _dark.withOpacity(0.06),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles:   AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:  AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx  = value.toInt();
                        final day  = days[idx];
                        const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        final isToday = day.day == DateTime.now().day;
                        return Text(
                          labels[day.weekday - 1],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                            color: isToday ? _orange : _dark.withOpacity(0.5),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Goal line label
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.horizontal_rule, color: _green.withOpacity(0.5), size: 18),
              const SizedBox(width: 4),
              Text(
                'Daily goal: ${goal.toStringAsFixed(0)} kcal',
                style: TextStyle(fontSize: 12, color: _dark.withOpacity(0.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: const Color(0xFF2D2D2D).withOpacity(0.55))),
      ],
    );
  }
}

// ── SDG Badge ─────────────────────────────────────────────────────────────────
class _SdgBadge extends StatelessWidget {
  static const _green = Color(0xFF1E4620);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _green.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _green.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Text('🌍', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Supporting UN SDG #3 & #2',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _green),
                ),
                SizedBox(height: 2),
                Text(
                  'Good Health & Well-Being · Zero Hunger',
                  style: TextStyle(fontSize: 11, color: Color(0xFF5A7A5C)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
