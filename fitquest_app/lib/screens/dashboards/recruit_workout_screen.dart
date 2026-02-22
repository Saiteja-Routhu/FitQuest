import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../main.dart';
import '../../services/workout_service.dart';
import '../../services/analytics_service.dart';

// ══════════════════════════════════════════════════════════════════════════════
// RECRUIT WORKOUT SCREEN — List of assigned training plans
// ══════════════════════════════════════════════════════════════════════════════
class RecruitWorkoutScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String password;

  const RecruitWorkoutScreen(
      {super.key, required this.userData, required this.password});

  @override
  State<RecruitWorkoutScreen> createState() => _RecruitWorkoutScreenState();
}

class _RecruitWorkoutScreenState extends State<RecruitWorkoutScreen> {
  List<dynamic> _plans = [];
  bool _loading = true;
  Timer? _heartbeatTimer;

  static const _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];
  // Today's weekday name (Monday–Sunday)
  String get _todayWeekday => _weekdays[DateTime.now().weekday - 1];

  // First plan that has exercises for today
  Map<String, dynamic>? get _todayPlan {
    for (final plan in _plans) {
      final exercises = plan['workout_exercises'] as List? ?? [];
      final hasToday = exercises
          .any((e) => e['day_label']?.toString() == _todayWeekday);
      if (hasToday) return plan as Map<String, dynamic>;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _load();
    _startHeartbeat();
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    super.dispose();
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      AnalyticsService.sendHeartbeat(
        widget.userData['username'] ?? '',
        widget.password,
        'working_out',
        0,
      );
    });
  }

  void _load() async {
    setState(() => _loading = true);
    try {
      final p = await WorkoutService.fetchAssignedPlans(
          widget.userData['username'], widget.password);
      if (mounted) setState(() { _plans = p; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FQColors.bg,
      appBar: AppBar(
        title: const Text('MY WORKOUTS'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: FQColors.cyan))
          : _plans.isEmpty
              ? _emptyState()
              : CustomScrollView(
                  slivers: [
                    // TODAY'S WORKOUT hero
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: _todayHeroCard(),
                      ),
                    ),
                    // ALL PROGRAMS label
                    if (_plans.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text('ALL PROGRAMS',
                              style: GoogleFonts.rajdhani(
                                  color: FQColors.muted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2)),
                        ),
                      ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _planCard(_plans[i]),
                        ),
                        childCount: _plans.length,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ],
                ),
    );
  }

  Widget _emptyState() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.fitness_center,
              size: 56, color: FQColors.muted.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text('No training plans assigned yet',
              style: GoogleFonts.rajdhani(
                  color: FQColors.muted, fontSize: 16)),
        ]),
      );

  Widget _todayHeroCard() {
    final plan = _todayPlan;

    if (plan == null) {
      // REST DAY card
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: FQColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: FQColors.border),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: FQColors.muted.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.bedtime_outlined,
                color: FQColors.muted, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text('REST DAY',
                  style: GoogleFonts.rajdhani(
                      color: FQColors.muted,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 2)),
              const SizedBox(height: 4),
              const Text('Recovery is part of the journey',
                  style: TextStyle(color: FQColors.muted, fontSize: 12)),
            ]),
          ),
        ]),
      );
    }

    // TODAY'S WORKOUT card
    final exercises  = plan['workout_exercises'] as List? ?? [];
    final todayExs   = exercises
        .where((e) => e['day_label']?.toString() == _todayWeekday)
        .toList();
    final dayNames   = plan['day_names'] as Map<String, dynamic>? ?? {};
    final focus      = dayNames[_todayWeekday]?.toString();

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecruitPlanDetailScreen(
            plan: plan,
            userData: widget.userData,
            password: widget.password,
            initialDay: _todayWeekday,
          ),
        ),
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: FQColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: FQColors.gold.withOpacity(0.5), width: 1.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  FQColors.gold.withOpacity(0.15),
                  FQColors.cyan.withOpacity(0.08),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(children: [
              const Icon(Icons.flash_on, color: FQColors.gold, size: 20),
              const SizedBox(width: 8),
              Text("TODAY'S WORKOUT",
                  style: GoogleFonts.rajdhani(
                      color: FQColors.gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 2)),
              if (focus != null) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: FQColors.cyan.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(focus.toUpperCase(),
                      style: const TextStyle(
                          color: FQColors.cyan, fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ],
              const Spacer(),
              Text(_todayWeekday,
                  style: const TextStyle(color: FQColors.muted, fontSize: 11)),
            ]),
          ),
          // Exercise list preview
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: todayExs.take(4).map((ex) {
                final exData = ex['exercise'] as Map<String, dynamic>? ?? {};
                final name   = exData['name']?.toString() ?? 'Exercise';
                final sets   = ex['sets'] ?? 3;
                final reps   = ex['reps']?.toString() ?? '10-12';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    const Icon(Icons.circle, color: FQColors.cyan, size: 6),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(name,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13)),
                    ),
                    Text('${sets}×${reps}',
                        style: const TextStyle(
                            color: FQColors.muted, fontSize: 11)),
                  ]),
                );
              }).toList(),
            ),
          ),
          if (todayExs.length > 4)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Text('+${todayExs.length - 4} more exercises →',
                  style: const TextStyle(
                      color: FQColors.cyan, fontSize: 11)),
            ),
        ]),
      ),
    );
  }

  Widget _planCard(Map<String, dynamic> plan) {
    final exercises = plan['workout_exercises'] as List? ?? [];
    final dayNames = plan['day_names'] as Map<String, dynamic>? ?? {};

    const dayOrder = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    final daysWithEx = <String>{};
    for (final ex in exercises) {
      final d = ex['day_label']?.toString() ?? 'Any';
      if (d != 'Any') daysWithEx.add(d);
    }
    final sortedDays =
        dayOrder.where((d) => daysWithEx.contains(d)).toList();

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecruitPlanDetailScreen(
            plan: plan,
            userData: widget.userData,
            password: widget.password,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: FQColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: FQColors.border),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: FQColors.cyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.fitness_center,
                  color: FQColors.cyan, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(plan['name'] ?? 'Plan',
                    style: GoogleFonts.rajdhani(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const SizedBox(height: 4),
                _chip('${exercises.length} exercises', FQColors.cyan),
              ]),
            ),
            const Icon(Icons.chevron_right,
                color: FQColors.muted, size: 20),
          ]),
          if (sortedDays.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: sortedDays.map((d) {
                final focus = dayNames[d]?.toString();
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: FQColors.gold.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: FQColors.gold.withOpacity(0.25)),
                  ),
                  child: Text(
                    focus != null
                        ? '${d.substring(0, 3)}: $focus'
                        : d.substring(0, 3),
                    style: const TextStyle(
                        color: FQColors.gold, fontSize: 10),
                  ),
                );
              }).toList(),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: TextStyle(color: color, fontSize: 11)),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// RECRUIT PLAN DETAIL — Mon–Sun tabs with LOG SET button per exercise
// ══════════════════════════════════════════════════════════════════════════════
class RecruitPlanDetailScreen extends StatefulWidget {
  final Map<String, dynamic> plan;
  final Map<String, dynamic> userData;
  final String password;
  final String? initialDay; // default tab when opening from today's hero

  const RecruitPlanDetailScreen({
    super.key,
    required this.plan,
    required this.userData,
    required this.password,
    this.initialDay,
  });

  @override
  State<RecruitPlanDetailScreen> createState() =>
      _RecruitPlanDetailScreenState();
}

class _RecruitPlanDetailScreenState extends State<RecruitPlanDetailScreen>
    with SingleTickerProviderStateMixin {
  static const _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];
  static const _abbr = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  late TabController _tabCtrl;
  // exerciseName → today's set count
  final Map<String, int> _setCountMap = {};

  int _resolveInitialTab() {
    final exercises = widget.plan['workout_exercises'] as List? ?? [];
    // Prefer the requested day
    if (widget.initialDay != null) {
      final idx = _days.indexOf(widget.initialDay!);
      if (idx >= 0) {
        final hasEx = exercises.any((e) => e['day_label']?.toString() == _days[idx]);
        if (hasEx) return idx;
      }
    }
    // Default: today's weekday
    final todayIdx = DateTime.now().weekday - 1; // 0=Mon
    final hasTodayEx = exercises.any((e) => e['day_label']?.toString() == _days[todayIdx]);
    if (hasTodayEx) return todayIdx;
    // Fallback: first day that has exercises
    for (int i = 0; i < _days.length; i++) {
      if (exercises.any((e) => e['day_label']?.toString() == _days[i])) return i;
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(
        length: 7, vsync: this, initialIndex: _resolveInitialTab());
    _loadSetCounts();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSetCounts() async {
    try {
      final logs = await AnalyticsService.fetchMySetLogs(
          widget.userData['username'], widget.password);
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final Map<String, int> counts = {};
      for (final log in logs) {
        if (log['date'] == todayStr) {
          final name = log['exercise_name'] as String;
          counts[name] = (counts[name] ?? 0) + 1;
        }
      }
      if (mounted) setState(() => _setCountMap.addAll(counts));
    } catch (_) {}
  }

  void _openSetLogger(Map<String, dynamic> ex, String planName) async {
    final exData = ex['exercise'] as Map<String, dynamic>? ?? {};
    final name = exData['name']?.toString() ?? 'Exercise';
    final todayCount = _setCountMap[name] ?? 0;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SetLogSheet(
        exerciseName: name,
        planName: planName,
        nextSetNumber: todayCount + 1,
        userData: widget.userData,
        password: widget.password,
        onLogged: (newCount) {
          setState(() => _setCountMap[name] = newCount);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dayNames = widget.plan['day_names'] as Map<String, dynamic>? ?? {};
    final exercises = widget.plan['workout_exercises'] as List? ?? [];
    final planName = widget.plan['name'] as String? ?? 'Plan';

    return Scaffold(
      backgroundColor: FQColors.bg,
      appBar: AppBar(
        title: Text(planName,
            style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: FQColors.cyan,
          labelColor: FQColors.cyan,
          unselectedLabelColor: FQColors.muted,
          isScrollable: true,
          labelStyle: GoogleFonts.rajdhani(
              fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
          tabs: List.generate(7, (i) => Tab(text: _abbr[i])),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: List.generate(7, (i) {
          final day = _days[i];
          final focus = dayNames[day]?.toString();
          final dayExs = exercises
              .where((e) => e['day_label']?.toString() == day)
              .toList();

          return _DayView(
            day: day,
            focus: focus,
            exercises: dayExs,
            planName: planName,
            setCountMap: _setCountMap,
            onLogSet: _openSetLogger,
          );
        }),
      ),
    );
  }
}

class _DayView extends StatelessWidget {
  final String day;
  final String? focus;
  final List<dynamic> exercises;
  final String planName;
  final Map<String, int> setCountMap;
  final Function(Map<String, dynamic>, String) onLogSet;

  const _DayView({
    required this.day,
    required this.focus,
    required this.exercises,
    required this.planName,
    required this.setCountMap,
    required this.onLogSet,
  });

  @override
  Widget build(BuildContext context) {
    return exercises.isEmpty
        ? _restDay()
        : ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              if (focus != null) _focusBanner(),
              ...exercises.map((e) => _exerciseCard(e)),
            ],
          );
  }

  Widget _restDay() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.bedtime_outlined,
              size: 48, color: FQColors.muted.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text('Rest day',
              style: GoogleFonts.rajdhani(
                  color: FQColors.muted, fontSize: 18)),
        ]),
      );

  Widget _focusBanner() => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: FQColors.gold.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: FQColors.gold.withOpacity(0.3)),
        ),
        child: Row(children: [
          const Icon(Icons.local_fire_department,
              color: FQColors.gold, size: 16),
          const SizedBox(width: 8),
          Text(focus!.toUpperCase(),
              style: GoogleFonts.rajdhani(
                  color: FQColors.gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1)),
        ]),
      );

  Widget _exerciseCard(Map<String, dynamic> ex) {
    final exData = ex['exercise'] as Map<String, dynamic>? ?? {};
    final name = exData['name']?.toString() ?? 'Exercise';
    final muscle = exData['muscle_group']?.toString() ?? '';
    final sets = ex['sets'] ?? 3;
    final reps = ex['reps']?.toString() ?? '10-12';
    final rest = ex['rest_time'] ?? 60;
    final todaySets = setCountMap[name] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: FQColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FQColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: FQColors.cyan.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.fitness_center,
              color: FQColors.cyan, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(name,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Row(children: [
              if (muscle.isNotEmpty) ...[
                _tag(muscle, FQColors.purple),
                const SizedBox(width: 6),
              ],
              Text('${sets}sets × ${reps}reps  ·  ${rest}s rest',
                  style: const TextStyle(
                      color: FQColors.muted, fontSize: 11)),
            ]),
            if (todaySets > 0) ...[
              const SizedBox(height: 4),
              Text('Today: $todaySets set${todaySets != 1 ? 's' : ''} logged',
                  style: const TextStyle(
                      color: FQColors.green, fontSize: 10)),
            ],
          ]),
        ),
        ElevatedButton(
          onPressed: () => onLogSet(ex, planName),
          style: ElevatedButton.styleFrom(
            backgroundColor: FQColors.cyan,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            textStyle: GoogleFonts.rajdhani(
                fontWeight: FontWeight.bold, fontSize: 12),
          ),
          child: const Text('LOG SET'),
        ),
      ]),
    );
  }

  Widget _tag(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label,
            style: TextStyle(color: color, fontSize: 10)),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// SET LOG BOTTOM SHEET
// ══════════════════════════════════════════════════════════════════════════════
class _SetLogSheet extends StatefulWidget {
  final String exerciseName;
  final String planName;
  final int nextSetNumber;
  final Map<String, dynamic> userData;
  final String password;
  final Function(int newCount) onLogged;

  const _SetLogSheet({
    required this.exerciseName,
    required this.planName,
    required this.nextSetNumber,
    required this.userData,
    required this.password,
    required this.onLogged,
  });

  @override
  State<_SetLogSheet> createState() => _SetLogSheetState();
}

class _SetLogSheetState extends State<_SetLogSheet> {
  int _reps = 10;
  double? _weightKg;
  String _effectiveness = 'Just Right';
  bool _saving = false;
  final _weightCtrl = TextEditingController();

  static const _effectivenessOptions = ['Too Easy', 'Just Right', 'Very Hard'];

  @override
  void dispose() {
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _log() async {
    setState(() => _saving = true);
    try {
      final result = await AnalyticsService.logSet(
        widget.userData['username'],
        widget.password,
        {
          'exercise_name': widget.exerciseName,
          'workout_plan_name': widget.planName,
          'reps': _reps,
          'weight_kg': _weightKg,
          'effectiveness': _effectiveness,
        },
      );
      if (!mounted) return;
      final newCount = result['today_set_count'] as int? ?? widget.nextSetNumber;
      widget.onLogged(newCount);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Set ${result['set_number']} logged! $_reps reps'),
          backgroundColor: FQColors.green));
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), backgroundColor: FQColors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: FQColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: FQColors.border)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
                color: FQColors.muted.withOpacity(0.35),
                borderRadius: BorderRadius.circular(2)),
          ),
          Text('LOG SET — ${widget.exerciseName.toUpperCase()}',
              style: GoogleFonts.rajdhani(
                  color: FQColors.cyan,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
          Text('Set #${widget.nextSetNumber} today',
              style: const TextStyle(color: FQColors.muted, fontSize: 12)),
          const SizedBox(height: 20),

          // Reps counter
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('REPS',
                style: GoogleFonts.rajdhani(
                    color: FQColors.muted, fontSize: 12, letterSpacing: 2)),
            const SizedBox(width: 16),
            IconButton(
              onPressed: () => setState(() => _reps = (_reps - 1).clamp(1, 999)),
              icon: const Icon(Icons.remove_circle_outline,
                  color: FQColors.cyan, size: 28),
            ),
            Text('$_reps',
                style: GoogleFonts.rajdhani(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold)),
            IconButton(
              onPressed: () => setState(() => _reps++),
              icon: const Icon(Icons.add_circle_outline,
                  color: FQColors.cyan, size: 28),
            ),
          ]),

          // Weight input
          const SizedBox(height: 12),
          TextField(
            controller: _weightCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            onChanged: (v) => _weightKg = double.tryParse(v),
            decoration: const InputDecoration(
              labelText: 'Weight (kg) — optional',
              labelStyle: TextStyle(color: FQColors.muted),
              prefixIcon: Icon(Icons.fitness_center_outlined,
                  color: FQColors.muted, size: 18),
            ),
          ),

          // Effectiveness
          const SizedBox(height: 16),
          Text('EFFECTIVENESS',
              style: GoogleFonts.rajdhani(
                  color: FQColors.muted, fontSize: 11, letterSpacing: 2)),
          const SizedBox(height: 8),
          Row(children: _effectivenessOptions.map((opt) {
            final selected = _effectiveness == opt;
            final color = opt == 'Too Easy'
                ? FQColors.green
                : opt == 'Very Hard'
                    ? FQColors.red
                    : FQColors.gold;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _effectiveness = opt),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? color.withOpacity(0.15) : FQColors.card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: selected ? color : FQColors.border),
                  ),
                  child: Text(opt,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.rajdhani(
                          color: selected ? color : FQColors.muted,
                          fontWeight: FontWeight.bold,
                          fontSize: 11)),
                ),
              ),
            );
          }).toList()),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _saving ? null : _log,
              style: ElevatedButton.styleFrom(
                backgroundColor: FQColors.cyan,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                textStyle: GoogleFonts.rajdhani(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.black, strokeWidth: 2))
                  : const Text('LOG IT'),
            ),
          ),
        ]),
      ),
    );
  }
}
