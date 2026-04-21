import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../controller/profile_controller.dart';
import '../../controller/cart_controller.dart';
import 'cart.dart';
import 'menu_page.dart';

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
            // ── Custom Pinned Header (replaces SliverAppBar entirely) ──────
            SliverPersistentHeader(
              pinned: true,
              delegate: _DashboardHeaderDelegate(
                greeting: '${_greeting()}, ${ctrl.displayName}',
                bmiLabel: profile?.bmi != null
                    ? 'BMI: ${profile!.bmi!.toStringAsFixed(1)} (${profile.bmiCategory})'
                    : null,
                initials: _initials(ctrl.fullDisplayName),
                tabController: _tab,
                onCartTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartPage()),
                  );
                },
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
//  Header Delegate — bypasses SliverAppBar's ghost toolbar completely
// ─────────────────────────────────────────────────────────────────────────────
class _DashboardHeaderDelegate extends SliverPersistentHeaderDelegate {
  static const _green  = Color(0xFF1E4620);
  static const _orange = Color(0xFFD95B2B);
  static const _dark   = Color(0xFF2D2D2D);

  final String greeting;
  final String? bmiLabel;
  final String initials;
  final TabController tabController;
  final VoidCallback onCartTap;

  const _DashboardHeaderDelegate({
    required this.greeting,
    required this.bmiLabel,
    required this.initials,
    required this.tabController,
    required this.onCartTap,
  });

  static const double _greetingHeight = 56.0;
  static const double _tabBarHeight   = 48.0;

  @override
  double get minExtent => _tabBarHeight;
  @override
  double get maxExtent => _greetingHeight + _tabBarHeight + 20;

  @override
  bool shouldRebuild(covariant _DashboardHeaderDelegate old) =>
      old.greeting != greeting ||
          old.bmiLabel != bmiLabel ||
          old.initials != initials;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Determine opacity: fades out as user scrolls up
    final double opacity = (1.0 - (shrinkOffset / (_greetingHeight / 2))).clamp(0.0, 1.0);

    return Container(
      color: const Color(0xFFF0ECE4), // Cream background matching the page body
      child: SafeArea(
        bottom: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Greeting row — fades as user scrolls ─────────────────────
            Positioned(
              top: 10, // top margin
              left: 16,
              right: 16,
              height: _greetingHeight,
              child: Opacity(
                opacity: opacity,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: _orange,
                      child: Text(
                        initials,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Greeting + BMI
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            greeting,
                            style: const TextStyle(color: _dark, fontSize: 16, fontWeight: FontWeight.w800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (bmiLabel != null)
                            Text(
                              bmiLabel!,
                              style: TextStyle(color: _dark.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                        ],
                      ),
                    ),
                    // Cart icon
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        GestureDetector(
                          onTap: onCartTap,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Color(0xFF859A7A), // Greenish color
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 24),
                          ),
                        ),
                        Positioned(
                          top: -2,
                          right: -4,
                          child: Consumer<CartController>(
                            builder: (context, cart, _) {
                              if (cart.totalItemCount == 0) return const SizedBox.shrink();
                              return Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: _orange.withValues(alpha: 0.85),
                                  shape: BoxShape.circle,
                                ),
                                child: Text('${cart.totalItemCount}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Tab Bar — anchored to bottom ──────────────────────────────────
            Positioned(
              bottom: 6,
              left: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: tabController,
                  indicator: BoxDecoration(
                    color: _orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.all(4),
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF4A5568),
                  labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Daily'),
                    Tab(text: 'Weekly'),
                    Tab(text: 'Monthly'),
                  ],
                ),
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
    final consumed = ctrl.todayCalories;
    final goal     = ctrl.calorieGoal;
    final progress = ctrl.calorieProgress;
    final pct      = (progress * 100).toInt();

    return ListView(
      primary: false,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // ── Calorie Card ──────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6E8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_fire_department, color: _green, size: 16),
                  const SizedBox(width: 4),
                  Text('Daily calories',
                      style: TextStyle(fontSize: 13, color: _dark.withValues(alpha: 0.6), fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('$pct%',
                      style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: _dark)),
                  const Spacer(),
                  SizedBox(
                    width: 110, height: 110,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(110, 110),
                          painter: _ArcGaugePainter(
                            progress: progress,
                            activeColor: _green,
                            inactiveColor: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              consumed.toStringAsFixed(0),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _dark),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              width: 30, height: 1,
                              color: _dark.withValues(alpha: 0.2),
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
        _SharedNutritionCard(
          currentCarbs: ctrl.todayCarbs,
          currentFat: ctrl.todayFat,
          currentProtein: ctrl.todayProtein,
          goalCarbs: ctrl.carbsGoal,
          goalFat: ctrl.fatGoal,
          goalProtein: ctrl.proteinGoal,
        ),
        const SizedBox(height: 20),

        // ── Meal of Today ─────────────────────────────────────────────────
        const Text('Meal Of Today',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _dark)),
        const SizedBox(height: 12),

        _mealCard(
          label: 'Breakfast', done: consumed > 0, icon: '🥑',
          kcal: consumed > 0 ? (consumed * 0.3).toInt() : 0, goalKcal: (ctrl.calorieGoal * 0.3).toInt(),
          fat: consumed > 0 ? ctrl.todayFat * 0.3 : 0,       goalFat: ctrl.fatGoal * 0.3,
          carbs: consumed > 0 ? ctrl.todayCarbs * 0.3 : 0,   goalCarbs: ctrl.carbsGoal * 0.3,
          protein: consumed > 0 ? ctrl.todayProtein * 0.3 : 0, goalProtein: ctrl.proteinGoal * 0.3,
          onTapArrow: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MenuPage())),
        ),
        _mealCard(
          label: 'Lunch', done: consumed > 0, icon: '🍚',
          kcal: consumed > 0 ? (consumed * 0.4).toInt() : 0, goalKcal: (ctrl.calorieGoal * 0.4).toInt(),
          fat: consumed > 0 ? ctrl.todayFat * 0.4 : 0,       goalFat: ctrl.fatGoal * 0.4,
          carbs: consumed > 0 ? ctrl.todayCarbs * 0.4 : 0,   goalCarbs: ctrl.carbsGoal * 0.4,
          protein: consumed > 0 ? ctrl.todayProtein * 0.4 : 0, goalProtein: ctrl.proteinGoal * 0.4,
          onTapArrow: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MenuPage())),
        ),
        _mealCard(
          label: 'Dinner', done: false, icon: '🥗',
          kcal: 0, goalKcal: (ctrl.calorieGoal * 0.3).toInt(),
          fat: 0,  goalFat: ctrl.fatGoal * 0.3,
          carbs: 0, goalCarbs: ctrl.carbsGoal * 0.3,
          protein: 0, goalProtein: ctrl.proteinGoal * 0.3,
          onTapArrow: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MenuPage())),
        ),
      ],
    );
  }

  Widget _mealCard({
    required String label,
    required bool done,
    required String icon,
    required int kcal, required int goalKcal,
    required double fat, required double goalFat,
    required double carbs, required double goalCarbs,
    required double protein, required double goalProtein,
    VoidCallback? onTapArrow,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _dark.withValues(alpha: 0.03), blurRadius: 10)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 60, height: 60,
            decoration: const BoxDecoration(color: Color(0xFFEFF6E8), shape: BoxShape.circle),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 32))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(label,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _dark)),
                    if (done) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 18, height: 18,
                        decoration: const BoxDecoration(color: Color(0xFF8BC34A), shape: BoxShape.circle),
                        child: const Icon(Icons.check, color: Colors.white, size: 12),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                _macroLine(const Color(0xFF8BC34A), '$kcal / $goalKcal cal', width: 44, isDone: done),
                _macroLine(Colors.red.shade600,    '${fat.toStringAsFixed(0)} / ${goalFat.toStringAsFixed(0)} g fat', width: 34, isDone: done),
                _macroLine(Colors.orange.shade500, '${carbs.toStringAsFixed(0)} / ${goalCarbs.toStringAsFixed(0)} g carbs', width: 28, isDone: done),
                _macroLine(Colors.indigo.shade600, '${protein.toStringAsFixed(0)} / ${goalProtein.toStringAsFixed(0)} g protein', width: 32, isDone: done),
              ],
            ),
          ),
          if (!done) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onTapArrow,
              child: Container(
                width: 40, height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFABC270),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_forward, size: 22, color: _dark),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _macroLine(Color color, String text, {double width = 24, bool isDone = true}) {
    final effectiveColor = isDone ? color : Colors.grey.withValues(alpha: 0.8);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Container(
            width: width, height: 6,
            decoration: BoxDecoration(color: effectiveColor, borderRadius: BorderRadius.circular(5)),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(text,
              style: TextStyle(fontSize: 11, color: _dark.withValues(alpha: 0.45), fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CUSTOM ARC GAUGE
// ─────────────────────────────────────────────────────────────────────────────
class _ArcGaugePainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  const _ArcGaugePainter({
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double startAngle = 135 * (3.141592653589793 / 180);
    const double sweepAngle = 270 * (3.141592653589793 / 180);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect   = Rect.fromCircle(center: center, radius: radius);

    canvas.drawArc(rect, startAngle, sweepAngle, false,
        Paint()
          ..color = inactiveColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round);

    canvas.drawArc(rect, startAngle, sweepAngle * progress.clamp(0.0, 1.0), false,
        Paint()
          ..color = activeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 18
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _ArcGaugePainter old) => old.progress != progress;
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
    final history   = ctrl.weeklyHistory;
    final goal      = ctrl.calorieGoal;
    final today     = DateTime.now();
    final monday    = today.subtract(Duration(days: today.weekday - 1));
    final days      = List.generate(7, (i) => monday.add(Duration(days: i)));
    final maxY      = (goal * 1.4).ceilToDouble();
    final dayLabels = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];

    double totalCarbs = 0;
    double totalFat = 0;
    double totalProtein = 0;

    final cals = days.map((d) {
      final key = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
      final log = history.firstWhere((h) => h['log_date'] == key, orElse: () => {});
      final cal = log.isNotEmpty ? (log['total_calories'] as num).toDouble() : 0.0;
      if (log.isNotEmpty) {
        totalCarbs += (log['total_carbs_g'] as num?)?.toDouble() ?? 0.0;
        totalFat += (log['total_fat_g'] as num?)?.toDouble() ?? 0.0;
        totalProtein += (log['total_protein_g'] as num?)?.toDouble() ?? 0.0;
      }
      return cal;
    }).toList();

    final daysLogged = cals.where((c) => c > 0).length;
    final totalCal   = cals.fold<double>(0, (a, b) => a + b);
    final avgCal     = daysLogged > 0 ? totalCal / daysLogged : 0.0;
    final goalHit    = cals.where((c) => c >= goal).length;

    return ListView(
      primary: false,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Row(children: [
          _statBox('Days Logged', '$daysLogged / 7', Colors.blue.shade400),
          const SizedBox(width: 10),
          _statBox('Avg Cal/day', '${avgCal.toStringAsFixed(0)} kcal', _orange),
          const SizedBox(width: 10),
          _statBox('Goal Hit',    '$goalHit days', _green),
        ]),
        const SizedBox(height: 16),

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
              const Text('7-Day Calorie History',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _dark)),
              Text('Target: ${goal.toStringAsFixed(0)} kcal / day',
                  style: TextStyle(fontSize: 11, color: _dark.withValues(alpha: 0.45))),
              const SizedBox(height: 16),
              SizedBox(
                height: 190,
                child: BarChart(BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barGroups: List.generate(7, (i) {
                    final cal = cals[i];
                    return BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: cal,
                        color: cal >= goal ? _green : (cal > 0 ? _orange : const Color(0xFFE0E0E0)),
                        width: 22,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        backDrawRodData: BackgroundBarChartRodData(
                            show: true, toY: maxY, color: const Color(0xFFF5F2EE)),
                      ),
                    ]);
                  }),
                  gridData: FlGridData(
                    show: true, drawVerticalLine: false,
                    horizontalInterval: goal / 2,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: _dark.withValues(alpha: 0.07), strokeWidth: 1),
                  ),
                  extraLinesData: ExtraLinesData(horizontalLines: [
                    HorizontalLine(
                      y: goal, color: _green.withValues(alpha: 0.5),
                      strokeWidth: 1.5, dashArray: [6, 4],
                      label: HorizontalLineLabel(
                        show: true, alignment: Alignment.topRight,
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
                    bottomTitles: AxisTitles(sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, m) {
                        final i = v.toInt();
                        final day = days[i];
                        final isToday = day.day == today.day;
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(dayLabels[day.weekday - 1],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                              color: isToday ? _orange : _dark.withValues(alpha: 0.5),
                            ),
                          ),
                        );
                      },
                    )),
                  ),
                )),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _SharedNutritionCard(
          currentCarbs: totalCarbs,
          currentFat: totalFat,
          currentProtein: totalProtein,
          goalCarbs: ctrl.carbsGoal * 7,
          goalFat: ctrl.fatGoal * 7,
          goalProtein: ctrl.proteinGoal * 7,
        ),
        const SizedBox(height: 16),

        const Text('Day Breakdown',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _dark)),
        const SizedBox(height: 10),
        ...List.generate(7, (i) {
          final day     = days[i];
          final cal     = cals[i];
          final pct     = goal > 0 ? (cal / goal).clamp(0.0, 1.0) : 0.0;
          final isToday = day.day == today.day;
          final hitGoal = cal >= goal && cal > 0;
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
                child: Text(dayLabels[day.weekday - 1],
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                      color: isToday ? _green : _dark.withValues(alpha: 0.55)),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct, minHeight: 8,
                    backgroundColor: const Color(0xFFF0ECE4),
                    valueColor: AlwaysStoppedAnimation(
                        hitGoal ? _green : (cal > 0 ? _orange : Colors.grey.shade300)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                cal > 0 ? '${cal.toStringAsFixed(0)} kcal' : '—',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: hitGoal ? _green : _dark.withValues(alpha: 0.6)),
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
    final history     = ctrl.monthlyHistory;
    final goal        = ctrl.calorieGoal;
    final now         = ctrl.selectedMonth;
    final realNow     = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);

    double totalCarbs = 0;
    double totalFat = 0;
    double totalProtein = 0;

    final Map<int, double> dayMap = {};
    for (final row in history) {
      final date = DateTime.tryParse(row['log_date'] as String? ?? '');
      if (date != null) {
        dayMap[date.day] = (row['total_calories'] as num).toDouble();
        totalCarbs += (row['total_carbs_g'] as num?)?.toDouble() ?? 0.0;
        totalFat += (row['total_fat_g'] as num?)?.toDouble() ?? 0.0;
        totalProtein += (row['total_protein_g'] as num?)?.toDouble() ?? 0.0;
      }
    }

    final daysLogged = dayMap.length;
    final totalCal   = dayMap.values.fold<double>(0, (a, b) => a + b);
    final goalHit    = dayMap.values.where((c) => c >= goal).length;
    final adherence  = daysLogged > 0 ? (goalHit / daysLogged * 100).toInt() : 0;

    final spots = List.generate(daysInMonth, (i) {
      final day = i + 1;
      return FlSpot(day.toDouble(), dayMap[day] ?? 0);
    });

    return ListView(
      primary: false,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: _dark),
              onPressed: () {
                final prev = DateTime(now.year, now.month - 1, 1);
                ctrl.changeMonth(prev);
              },
            ),
            Text('${_monthNames[now.month - 1]} ${now.year}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _dark)),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: _dark),
              onPressed: () {
                final next = DateTime(now.year, now.month + 1, 1);
                // Optional: comment out the if block if you want to allow future viewing
                // if (next.isAfter(realNow) && next.month != realNow.month) return;
                ctrl.changeMonth(next);
              },
            ),
          ],
        ),
        const SizedBox(height: 14),

        Row(children: [
          _statBox('Days Logged',   '$daysLogged days', Colors.blue.shade400),
          const SizedBox(width: 10),
          _statBox('Total Cals',    '${(totalCal / 1000).toStringAsFixed(1)}k kcal', _orange),
          const SizedBox(width: 10),
          _statBox('Goal Achieved', '$adherence%', _green),
        ]),
        const SizedBox(height: 16),

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
              const Text('Calorie Trend',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _dark)),
              Text('Daily goal: ${goal.toStringAsFixed(0)} kcal',
                  style: TextStyle(fontSize: 11, color: _dark.withValues(alpha: 0.45))),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: LineChart(LineChartData(
                  minX: 1, maxX: daysInMonth.toDouble(),
                  minY: 0, maxY: (goal * 1.5).ceilToDouble(),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots.where((s) => s.y > 0).toList(),
                      isCurved: true, color: _orange, barWidth: 2.5,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (s, _, __, ___) => FlDotCirclePainter(
                            radius: 3, color: s.y >= goal ? _green : _orange, strokeWidth: 0),
                      ),
                      belowBarData: BarAreaData(show: true, color: _orange.withValues(alpha: 0.08)),
                    ),
                  ],
                  extraLinesData: ExtraLinesData(horizontalLines: [
                    HorizontalLine(
                      y: goal, color: _green.withValues(alpha: 0.5),
                      strokeWidth: 1.5, dashArray: [6, 4],
                      label: HorizontalLineLabel(
                        show: true, alignment: Alignment.topRight,
                        labelResolver: (_) => 'Goal',
                        style: TextStyle(fontSize: 10, color: _green.withValues(alpha: 0.7), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ]),
                  gridData: FlGridData(
                    show: true, drawVerticalLine: false, horizontalInterval: goal / 2,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: _dark.withValues(alpha: 0.06), strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles:   AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:  AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(
                      showTitles: true, interval: 7,
                      getTitlesWidget: (v, _) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('${v.toInt()}',
                            style: TextStyle(fontSize: 10, color: _dark.withValues(alpha: 0.45))),
                      ),
                    )),
                  ),
                )),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        const Text('Calorie Heatmap',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _dark)),
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
              Row(
                children: ['M','T','W','T','F','S','S'].map((d) => Expanded(
                  child: Center(child: Text(d,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                          color: _dark.withValues(alpha: 0.4)))),
                )).toList(),
              ),
              const SizedBox(height: 8),
              _buildCalendarGrid(now, daysInMonth, dayMap, goal),
            ],
          ),
        ),
        const SizedBox(height: 16),

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
        const SizedBox(height: 16),

        _SharedNutritionCard(
          currentCarbs: totalCarbs,
          currentFat: totalFat,
          currentProtein: totalProtein,
          goalCarbs: ctrl.carbsGoal * daysInMonth,
          goalFat: ctrl.fatGoal * daysInMonth,
          goalProtein: ctrl.proteinGoal * daysInMonth,
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(DateTime now, int daysInMonth, Map<int,double> dayMap, double goal) {
    final firstWeekday = DateTime(now.year, now.month, 1).weekday;
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
              final cal     = dayMap[dayNum] ?? 0;
              final realNow = DateTime.now();
              final isToday = dayNum == realNow.day && now.year == realNow.year && now.month == realNow.month;
              Color bg = Colors.grey.shade100;
              if (cal > 0) {
                bg = cal >= goal
                    ? _green
                    : _orange.withValues(alpha: 0.35 + (cal / goal * 0.3).clamp(0, 0.5));
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
                      child: Text('$dayNum',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                          color: cal > 0
                              ? Colors.white.withValues(alpha: 0.9)
                              : _dark.withValues(alpha: 0.4),
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
      Container(
        width: 14, height: 14,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
      ),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 11, color: _dark.withValues(alpha: 0.55))),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Shared Nutritions Card
// ─────────────────────────────────────────────────────────────────────────────
class _SharedNutritionCard extends StatelessWidget {
  final double currentCarbs;
  final double currentFat;
  final double currentProtein;
  final double goalCarbs;
  final double goalFat;
  final double goalProtein;

  const _SharedNutritionCard({
    required this.currentCarbs,
    required this.currentFat,
    required this.currentProtein,
    required this.goalCarbs,
    required this.goalFat,
    required this.goalProtein,
  });

  static const _dark = Color(0xFF2D2D2D);

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F3F3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pie_chart_outline, size: 18, color: _dark),
              ),
              const SizedBox(width: 12),
              const Text('Nutritions',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _dark)),
            ],
          ),
          const SizedBox(height: 14),
          _macroBar('Carbs',   currentCarbs,   goalCarbs,   Colors.red.shade600),
          _macroBar('Fat',     currentFat,     goalFat,     Colors.orange.shade500),
          _macroBar('Protein', currentProtein, goalProtein, Colors.indigo.shade600),
        ],
      ),
    );
  }

  Widget _macroBar(String label, double current, double goal, Color color) {
    final pct = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;
    final p   = (pct * 100).toInt();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: _dark.withValues(alpha: 0.75))),
              Text('${current.toStringAsFixed(1)}/${goal.toStringAsFixed(0)} g',
                  style: TextStyle(fontSize: 11, color: _dark.withValues(alpha: 0.45))),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              SizedBox(
                width: 34,
                child: Text('$p%',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: _dark.withValues(alpha: 0.6))),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: pct, minHeight: 10,
                    backgroundColor: const Color(0xFFF0ECE4),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}