import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../main.dart';
import '../../services/nutrition_service.dart';
import '../../services/api_service.dart';
import '../../services/analytics_service.dart';

// ══════════════════════════════════════════════════════════════════════════════
// ATHLETE PROFILE SCREEN  (was "Scout Report")
// ══════════════════════════════════════════════════════════════════════════════
class ScoutReportScreen extends StatefulWidget {
  final dynamic             recruit;   // Full athlete map from API
  final Map<String, dynamic> userData; // Coach's data
  final String              password;

  const ScoutReportScreen({
    super.key,
    required this.recruit,
    required this.userData,
    required this.password,
  });

  @override
  State<ScoutReportScreen> createState() => _ScoutReportScreenState();
}

class _ScoutReportScreenState extends State<ScoutReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r        = widget.recruit;
    final username = r['username']?.toString() ?? 'Athlete';

    return Scaffold(
      backgroundColor: FQColors.bg,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, innerBoxScrolled) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: FQColors.bg,
            expandedHeight: 160,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildProfileHeader(r, username),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: FQColors.cyan,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: FQColors.cyan,
              unselectedLabelColor: FQColors.muted,
              labelStyle: GoogleFonts.rajdhani(
                  fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1),
              tabs: const [
                Tab(text: 'OVERVIEW'),
                Tab(text: 'ASSESSMENT'),
                Tab(text: 'NUTRITION'),
                Tab(text: 'ANALYTICS'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _OverviewTab(recruit: r),
            _AssessmentTab(recruit: r),
            NutritionScheduleView(
              recruitId: r['id'],
              userData:  widget.userData,
              password:  widget.password,
            ),
            _AnalyticsTab(
              recruit:  r,
              userData: widget.userData,
              password: widget.password,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(dynamic r, String username) {
    final goal    = r['goal']?.toString()         ?? 'N/A';
    final level   = r['level']                    ?? 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
          colors: [FQColors.surface, FQColors.bg],
        ),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: FQColors.cyan.withOpacity(0.15),
          child: Text(
            username.substring(0, 1).toUpperCase(),
            style: GoogleFonts.rajdhani(
                color: FQColors.cyan, fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(username.toUpperCase(),
                style: GoogleFonts.rajdhani(
                    color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Row(children: [
              goalBadge(goal),
              const SizedBox(width: 8),
              _levelBadge(level),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _levelBadge(int level) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: FQColors.gold.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: FQColors.gold.withOpacity(0.4)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.star, color: FQColors.gold, size: 10),
          const SizedBox(width: 3),
          Text('Level $level',
              style: const TextStyle(
                  color: FQColors.gold, fontSize: 10, fontWeight: FontWeight.w600)),
        ]),
      );
}

// ──────────────────────────────────────────────────────────────────────────────
//  TAB 1 — OVERVIEW
// ──────────────────────────────────────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final dynamic recruit;
  const _OverviewTab({required this.recruit});

  @override
  Widget build(BuildContext context) {
    final r      = recruit;
    final form   = r['assessment'] as Map<String, dynamic>? ?? {};
    final height = r['height'];
    final weight = r['weight'];

    // BMI
    String bmi = '—';
    if (height != null && weight != null) {
      final h = (height is num ? height.toDouble() : double.tryParse(height.toString())) ?? 0;
      final w = (weight is num ? weight.toDouble() : double.tryParse(weight.toString())) ?? 0;
      if (h > 0 && w > 0) {
        bmi = (w / ((h / 100) * (h / 100))).toStringAsFixed(1);
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Key stats grid
        _sectionHeader('KEY STATS'),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.2,
          children: [
            _statCard('Weight',   weight != null ? '${weight}kg'  : '—',  Icons.monitor_weight_outlined, FQColors.cyan),
            _statCard('Height',   height != null ? '${height}cm'  : '—',  Icons.height,                  const Color(0xFF4A9EFF)),
            _statCard('BMI',      bmi,                                      Icons.calculate_outlined,      FQColors.gold),
            _statCard('Activity', r['activity_level']?.toString() ?? '—',  Icons.directions_run_outlined,  FQColors.green),
          ],
        ),

        const SizedBox(height: 20),
        // XP bar
        _sectionHeader('PROGRESS'),
        const SizedBox(height: 10),
        _xpCard(r),

        // Alerts
        if (form.isNotEmpty) ...[
          const SizedBox(height: 20),
          _sectionHeader('HEALTH ALERTS'),
          const SizedBox(height: 10),
          if ((form['injuries']?.toString() ?? '').isNotEmpty)
            _alertCard('⚠ INJURY REPORTED', form['injuries'].toString(), FQColors.red),
          if ((form['food_allergies']?.toString() ?? '').isNotEmpty)
            _alertCard('⚠ ALLERGIES', form['food_allergies'].toString(), FQColors.gold),
          if ((form['medical_history']?.toString() ?? '').isNotEmpty)
            _alertCard('🏥 MEDICAL HISTORY', form['medical_history'].toString(), const Color(0xFF4A9EFF)),
        ],
      ],
    );
  }

  Widget _sectionHeader(String text) => Text(
        text,
        style: GoogleFonts.rajdhani(
            color: FQColors.cyan,
            fontSize: 11,
            letterSpacing: 2.5,
            fontWeight: FontWeight.bold),
      );

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: FQColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FQColors.border),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(color: FQColors.muted, fontSize: 10)),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 15, fontWeight: FontWeight.bold)),
        ]),
      ]),
    );
  }

  Widget _xpCard(dynamic r) {
    final level = (r['level'] ?? 1) as int;
    final xp    = (r['xp']    ?? 0) as int;
    final coins = (r['coins'] ?? 0) as int;
    // Rough XP-to-next-level: 100 * level
    final needed   = 100 * level;
    final progress = (xp % needed) / needed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FQColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FQColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.star, color: FQColors.gold, size: 16),
          const SizedBox(width: 6),
          Text('Level $level',
              style: const TextStyle(
                  color: FQColors.gold, fontWeight: FontWeight.bold)),
          const Spacer(),
          const Icon(Icons.monetization_on_outlined,
              color: FQColors.gold, size: 14),
          const SizedBox(width: 4),
          Text('$coins coins',
              style: const TextStyle(color: FQColors.muted, fontSize: 12)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: FQColors.card,
            valueColor:
                const AlwaysStoppedAnimation<Color>(FQColors.gold),
          ),
        ),
        const SizedBox(height: 6),
        Text('$xp / $needed XP',
            style:
                const TextStyle(color: FQColors.muted, fontSize: 11)),
      ]),
    );
  }

  Widget _alertCard(String title, String body, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 4),
        Text(body, style: const TextStyle(color: Colors.white, fontSize: 13)),
      ]),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  TAB 2 — ASSESSMENT
// ──────────────────────────────────────────────────────────────────────────────
class _AssessmentTab extends StatelessWidget {
  final dynamic recruit;
  const _AssessmentTab({required this.recruit});

  @override
  Widget build(BuildContext context) {
    final form = recruit['assessment'] as Map<String, dynamic>?;

    if (form == null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.assignment_outlined,
              size: 48, color: FQColors.muted.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text('No assessment submitted',
              style: GoogleFonts.rajdhani(color: FQColors.muted, fontSize: 16)),
          const SizedBox(height: 4),
          const Text(
              'The athlete hasn\'t filled in their intake form yet.',
              style: TextStyle(color: FQColors.muted, fontSize: 12)),
        ]),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _section('BODY MEASUREMENTS', [
          _row('Waist',  form['waist_circumference'], suffix: '"'),
          _row('Chest',  form['chest_size'],          suffix: '"'),
          _row('Bicep',  form['bicep_size'],          suffix: '"'),
          _row('Thigh',  form['thigh_size'],          suffix: '"'),
        ]),
        const SizedBox(height: 20),
        _section('MEDICAL NOTES', [
          _row('Injuries',        form['injuries']),
          _row('Medical History', form['medical_history']),
        ]),
        const SizedBox(height: 20),
        _section('NUTRITION & LIFESTYLE', [
          _row('Diet Type',      form['food_preference']),
          _row('Meals per Day',  form['meals_per_day']),
          _row('Tea / Coffee',   form['tea_coffee_cups']),
          _row('Alcohol',        form['alcohol_frequency']),
          _row('Food Allergies', form['food_allergies']),
        ]),
        const SizedBox(height: 20),
        _section('TYPICAL DIET', [
          _row('Breakfast', form['typical_breakfast']),
          _row('Lunch',     form['typical_lunch']),
          _row('Dinner',    form['typical_dinner']),
          _row('Snacks',    form['typical_snacks']),
        ]),
        const SizedBox(height: 20),
        _section('TRAINING BACKGROUND', [
          _row('Experience',    form['exercise_experience']),
          _row('Preference',    form['preferred_exercise']),
          _row('Availability',  form['days_available']),
        ]),
      ],
    );
  }

  Widget _section(String title, List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: FQColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FQColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: FQColors.border)),
          ),
          child: Text(title,
              style: GoogleFonts.rajdhani(
                  color: FQColors.cyan,
                  fontSize: 11,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: rows),
        ),
      ]),
    );
  }

  Widget _row(String label, dynamic value, {String suffix = ''}) {
    final displayValue = value != null && value.toString().isNotEmpty
        ? '${value}$suffix'
        : '—';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(label,
                  style: const TextStyle(
                      color: FQColors.muted, fontSize: 13)),
            ),
            Expanded(
              child: Text(displayValue,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13)),
            ),
          ]),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
//  TAB 4 — ANALYTICS (Enhanced)
// ──────────────────────────────────────────────────────────────────────────────
class _AnalyticsTab extends StatefulWidget {
  final dynamic             recruit;
  final Map<String, dynamic> userData;
  final String              password;

  const _AnalyticsTab({
    required this.recruit,
    required this.userData,
    required this.password,
  });

  @override
  State<_AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<_AnalyticsTab> {
  Map<String, dynamic>? _data;
  Map<String, dynamic>? _summary;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    try {
      final results = await Future.wait<Map<String, dynamic>>([
        ApiService.fetchAthleteAnalytics(
            widget.userData['username'], widget.password, widget.recruit['id']),
        AnalyticsService.fetchAthleteSummary(
            widget.userData['username'], widget.password, widget.recruit['id']),
      ]);
      if (mounted) {
        setState(() {
          _data    = results[0];
          _summary = results[1];
          _loading = false;
        });
      }
    } catch (_) {
      // Try loading just the basic analytics if summary fails
      try {
        final d = await ApiService.fetchAthleteAnalytics(
            widget.userData['username'], widget.password, widget.recruit['id']);
        if (mounted) setState(() { _data = d; _loading = false; });
      } catch (_) {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: FQColors.cyan));
    }
    if (_data == null) {
      return Center(
        child: Text('Failed to load analytics',
            style: TextStyle(color: FQColors.muted)),
      );
    }

    final d          = _data!;
    final xp         = (d['xp']    ?? 0) as int;
    final level      = (d['level'] ?? 1) as int;
    final coins      = (d['coins'] ?? 0) as int;
    final xpProgress = (xp % 500) / 500.0;
    final xpToNext   = 500 - (xp % 500);

    final recentQuests   = d['recent_quests'] as List? ?? [];
    final liveStatus     = _summary?['live_status'] as Map<String, dynamic>?;
    final isLive         = liveStatus != null && liveStatus['is_live'] == true;
    final activityType   = liveStatus?['activity_type'] as String? ?? 'idle';
    final stepsLive      = liveStatus?['steps_live'] ?? 0;
    final weightHistory  = _summary?['weight_history'] as List? ?? [];
    final stepHistory    = _summary?['step_history'] as List? ?? [];
    final recentSetLogs  = _summary?['recent_set_logs'] as List? ?? [];
    final bodyScans      = (_summary?['latest_body_progress'] != null)
        ? [_summary!['latest_body_progress']]
        : <dynamic>[];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Live Status Badge ─────────────────────────────────────────────────
        if (isLive) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: FQColors.green.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: FQColors.green.withOpacity(0.35)),
            ),
            child: Row(children: [
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(
                    color: FQColors.green, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Text('LIVE NOW',
                  style: GoogleFonts.rajdhani(
                      color: FQColors.green,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
              const SizedBox(width: 8),
              Text(
                activityType == 'working_out'
                    ? '💪 Working Out'
                    : activityType == 'walking'
                        ? '🏃 Walking'
                        : 'Idle',
                style: const TextStyle(color: FQColors.green, fontSize: 12),
              ),
              if (stepsLive > 0) ...[
                const Spacer(),
                Text('$stepsLive steps',
                    style: const TextStyle(color: FQColors.muted, fontSize: 12)),
              ],
            ]),
          ),
          const SizedBox(height: 12),
        ],

        // ── Level & XP card ───────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: FQColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: FQColors.gold.withOpacity(0.3)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('$level',
                  style: GoogleFonts.rajdhani(
                      color: FQColors.gold,
                      fontSize: 48,
                      fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('LEVEL',
                    style: GoogleFonts.rajdhani(
                        color: FQColors.gold,
                        fontSize: 13,
                        letterSpacing: 2)),
                Text('$xp XP total',
                    style: const TextStyle(color: FQColors.muted, fontSize: 12)),
              ]),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: FQColors.gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.monetization_on_outlined,
                      color: FQColors.gold, size: 14),
                  const SizedBox(width: 4),
                  Text('$coins',
                      style: const TextStyle(
                          color: FQColors.gold, fontWeight: FontWeight.bold)),
                ]),
              ),
            ]),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: xpProgress.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: FQColors.card,
                valueColor: const AlwaysStoppedAnimation<Color>(FQColors.gold),
              ),
            ),
            const SizedBox(height: 6),
            Text('$xpToNext XP to next level',
                style: const TextStyle(color: FQColors.muted, fontSize: 11)),
          ]),
        ),
        const SizedBox(height: 16),

        // ── Stats grid ────────────────────────────────────────────────────────
        _sectionHeader('STATS'),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.4,
          children: [
            _statCard('Plans Assigned',  '${d['workout_plans'] ?? 0}',     Icons.fitness_center,          FQColors.gold),
            _statCard('Diet Plans',      '${d['diet_plans'] ?? 0}',         Icons.restaurant_outlined,     FQColors.green),
            _statCard('Quests Done',     '${d['quests_completed'] ?? 0}',   Icons.military_tech_outlined,  FQColors.purple),
            _statCard('Coins Earned',    '${d['total_coins_earned'] ?? 0}', Icons.monetization_on_outlined, FQColors.gold),
          ],
        ),
        const SizedBox(height: 16),

        // ── Weight History Chart ───────────────────────────────────────────────
        if (weightHistory.length >= 2) ...[
          _sectionHeader('WEIGHT TREND (30 DAYS)'),
          const SizedBox(height: 10),
          Container(
            height: 160,
            padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
            decoration: BoxDecoration(
              color: FQColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: FQColors.border),
            ),
            child: _buildWeightChart(weightHistory),
          ),
          const SizedBox(height: 16),
        ],

        // ── Step History Chart ────────────────────────────────────────────────
        if (stepHistory.isNotEmpty) ...[
          _sectionHeader('STEPS (LAST 7 DAYS)'),
          const SizedBox(height: 10),
          Container(
            height: 140,
            padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
            decoration: BoxDecoration(
              color: FQColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: FQColors.border),
            ),
            child: _buildStepChart(stepHistory),
          ),
          const SizedBox(height: 16),
        ],

        // ── Recent Set Logs ───────────────────────────────────────────────────
        if (recentSetLogs.isNotEmpty) ...[
          _sectionHeader('RECENT WORKOUT SETS'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: FQColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: FQColors.border),
            ),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: Row(children: [
                  Expanded(child: Text('Exercise',
                      style: const TextStyle(color: FQColors.muted, fontSize: 11))),
                  SizedBox(width: 48, child: Text('Reps',
                      style: const TextStyle(color: FQColors.muted, fontSize: 11),
                      textAlign: TextAlign.center)),
                  SizedBox(width: 48, child: Text('Kg',
                      style: const TextStyle(color: FQColors.muted, fontSize: 11),
                      textAlign: TextAlign.center)),
                  SizedBox(width: 72, child: Text('Feel',
                      style: const TextStyle(color: FQColors.muted, fontSize: 11),
                      textAlign: TextAlign.center)),
                ]),
              ),
              const Divider(height: 1, color: FQColors.border),
              ...recentSetLogs.take(8).map((log) {
                final feel = log['effectiveness'] as String? ?? '';
                final feelColor = feel == 'Too Easy'
                    ? FQColors.cyan
                    : feel == 'Just Right'
                        ? FQColors.green
                        : FQColors.red;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: FQColors.border, width: 0.4))),
                  child: Row(children: [
                    Expanded(
                      child: Text(log['exercise_name'] ?? '',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          overflow: TextOverflow.ellipsis),
                    ),
                    SizedBox(
                      width: 48,
                      child: Text('${log['reps'] ?? '—'}',
                          style: const TextStyle(color: FQColors.gold, fontSize: 12),
                          textAlign: TextAlign.center),
                    ),
                    SizedBox(
                      width: 48,
                      child: Text(log['weight_kg'] != null ? '${log['weight_kg']}' : '—',
                          style: const TextStyle(color: FQColors.cyan, fontSize: 12),
                          textAlign: TextAlign.center),
                    ),
                    SizedBox(
                      width: 72,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: feelColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(feel,
                            style: TextStyle(color: feelColor, fontSize: 9),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ]),
                );
              }),
            ]),
          ),
          const SizedBox(height: 16),
        ],

        // ── Latest Body Scan ──────────────────────────────────────────────────
        if (bodyScans.isNotEmpty) ...[
          _sectionHeader('LATEST BODY SCAN'),
          const SizedBox(height: 10),
          _buildBodyScanCard(bodyScans.first),
          const SizedBox(height: 16),
        ],

        // ── XP & Coins total ──────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: FQColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FQColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(children: [
                Text('${d['total_xp_earned'] ?? 0}',
                    style: GoogleFonts.rajdhani(
                        color: FQColors.cyan,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const Text('Total XP Earned',
                    style: TextStyle(color: FQColors.muted, fontSize: 11)),
              ]),
              Container(width: 1, height: 36, color: FQColors.border),
              Column(children: [
                Text('${d['total_coins_earned'] ?? 0}',
                    style: GoogleFonts.rajdhani(
                        color: FQColors.gold,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const Text('Total Coins Earned',
                    style: TextStyle(color: FQColors.muted, fontSize: 11)),
              ]),
            ],
          ),
        ),

        // ── Recent quests ─────────────────────────────────────────────────────
        if (recentQuests.isNotEmpty) ...[
          const SizedBox(height: 20),
          _sectionHeader('RECENT QUESTS'),
          const SizedBox(height: 10),
          ...recentQuests.map((q) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FQColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: FQColors.border),
            ),
            child: Row(children: [
              const Icon(Icons.check_circle_outline,
                  color: FQColors.green, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(q['name'],
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
              ),
              _badge('+${q['xp']} XP', FQColors.cyan),
              const SizedBox(width: 6),
              _badge('+${q['coins']} 🪙', FQColors.gold),
            ]),
          )),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildWeightChart(List<dynamic> history) {
    // history: [{date, weight}, ...] sorted ascending
    final spots = <FlSpot>[];
    double? minW, maxW;
    for (int i = 0; i < history.length; i++) {
      final w = (history[i]['weight'] as num?)?.toDouble();
      if (w != null) {
        spots.add(FlSpot(i.toDouble(), w));
        minW = minW == null ? w : (w < minW ? w : minW);
        maxW = maxW == null ? w : (w > maxW ? w : maxW);
      }
    }
    if (spots.isEmpty) return const SizedBox.shrink();
    final padding = ((maxW ?? 0) - (minW ?? 0)) * 0.2 + 1;

    return LineChart(LineChartData(
      minY: (minW ?? 0) - padding,
      maxY: (maxW ?? 0) + padding,
      gridData: FlGridData(
        show: true,
        getDrawingHorizontalLine: (_) => FlLine(
            color: FQColors.border, strokeWidth: 0.5),
        getDrawingVerticalLine: (_) => FlLine(
            color: FQColors.border, strokeWidth: 0.3),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            getTitlesWidget: (v, _) => Text(
              '${v.toInt()}',
              style: const TextStyle(color: FQColors.muted, fontSize: 9),
            ),
          ),
        ),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: FQColors.cyan,
          barWidth: 2,
          dotData: FlDotData(
            show: true,
            getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
              radius: 3,
              color: FQColors.cyan,
              strokeWidth: 0,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: FQColors.cyan.withOpacity(0.08),
          ),
        ),
      ],
    ));
  }

  Widget _buildStepChart(List<dynamic> history) {
    // history: [{date, steps}, ...] last 7 days
    final recent = history.length > 7
        ? history.sublist(history.length - 7)
        : history;

    final groups = <BarChartGroupData>[];
    for (int i = 0; i < recent.length; i++) {
      final steps = (recent[i]['steps'] as num?)?.toDouble() ?? 0;
      groups.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: steps,
            color: FQColors.green,
            width: 14,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      ));
    }

    // Label: day of week
    final dayLabels = <int, String>{};
    for (int i = 0; i < recent.length; i++) {
      final dateStr = recent[i]['date'] as String? ?? '';
      if (dateStr.isNotEmpty) {
        try {
          final d = DateTime.parse(dateStr);
          dayLabels[i] = ['M', 'T', 'W', 'T', 'F', 'S', 'S'][d.weekday - 1];
        } catch (_) {
          dayLabels[i] = '';
        }
      }
    }

    return BarChart(BarChartData(
      gridData: FlGridData(
        show: true,
        getDrawingHorizontalLine: (_) => FlLine(
            color: FQColors.border, strokeWidth: 0.5),
        drawVerticalLine: false,
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, _) {
              final label = dayLabels[v.toInt()] ?? '';
              return Text(label,
                  style: const TextStyle(color: FQColors.muted, fontSize: 9));
            },
            reservedSize: 16,
          ),
        ),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      barGroups: groups,
    ));
  }

  Widget _buildBodyScanCard(dynamic scan) {
    final photoUrl = scan['photo_front_url'] as String?;
    final aiAnalysis = scan['ai_analysis'] as String? ?? '';
    final bodyFat = scan['body_fat_estimate'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FQColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FQColors.purple.withOpacity(0.25)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (photoUrl != null && photoUrl.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: photoUrl,
              width: 72,
              height: 90,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                width: 72,
                height: 90,
                color: FQColors.card,
              ),
              errorWidget: (_, __, ___) => Container(
                width: 72,
                height: 90,
                color: FQColors.card,
                child: const Icon(Icons.person_outline,
                    color: FQColors.muted, size: 28),
              ),
            ),
          )
        else
          Container(
            width: 72, height: 90,
            decoration: BoxDecoration(
              color: FQColors.card,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.person_outline,
                color: FQColors.muted, size: 28),
          ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (bodyFat != null)
              Row(children: [
                Text('Body Fat: ',
                    style: const TextStyle(color: FQColors.muted, fontSize: 12)),
                Text('${bodyFat}%',
                    style: const TextStyle(
                        color: FQColors.cyan,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
              ]),
            if (aiAnalysis.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                aiAnalysis.length > 120
                    ? '${aiAnalysis.substring(0, 120)}...'
                    : aiAnalysis,
                style: const TextStyle(color: FQColors.muted, fontSize: 11),
              ),
            ],
            const SizedBox(height: 4),
            Text(scan['date'] ?? '',
                style: const TextStyle(color: FQColors.muted, fontSize: 10)),
          ]),
        ),
      ]),
    );
  }

  Widget _sectionHeader(String text) => Text(
        text,
        style: GoogleFonts.rajdhani(
            color: FQColors.cyan,
            fontSize: 11,
            letterSpacing: 2.5,
            fontWeight: FontWeight.bold),
      );

  Widget _statCard(String label, String value, IconData icon, Color color) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: FQColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FQColors.border),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(color: FQColors.muted, fontSize: 10)),
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 15, fontWeight: FontWeight.bold)),
          ]),
        ]),
      );

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text, style: TextStyle(color: color, fontSize: 11)),
      );
}

// ──────────────────────────────────────────────────────────────────────────────
//  TAB 3 — NUTRITION SCHEDULE  (weekly plan per athlete)
// ──────────────────────────────────────────────────────────────────────────────
class NutritionScheduleView extends StatefulWidget {
  final int                  recruitId;
  final Map<String, dynamic> userData;
  final String               password;

  const NutritionScheduleView({
    super.key,
    required this.recruitId,
    required this.userData,
    required this.password,
  });

  @override
  State<NutritionScheduleView> createState() =>
      _NutritionScheduleViewState();
}

class _NutritionScheduleViewState extends State<NutritionScheduleView> {
  List<dynamic> _schedule = [];
  List<dynamic> _plans    = [];
  bool          _loading  = true;

  static const _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];

  @override
  void initState() { super.initState(); _load(); }

  void _load() async {
    try {
      final s = await NutritionService.fetchSchedule(
          widget.userData['username'], widget.password, widget.recruitId);
      final p = await NutritionService.fetchMyPlans(
          widget.userData['username'], widget.password);
      setState(() { _schedule = s; _plans = p; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _assignDay(String day) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: FQColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: FQColors.border)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                  color: FQColors.muted.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(children: [
              Text('ASSIGN $day'.toUpperCase(),
                  style: GoogleFonts.rajdhani(
                      color: FQColors.cyan,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
            ]),
          ),
          // Plans list
          ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _plans.length + 1,
              itemBuilder: (_, i) {
                if (i == _plans.length) {
                  return ListTile(
                    leading: const Icon(Icons.bedtime_outlined,
                        color: FQColors.red, size: 18),
                    title: const Text('Rest Day',
                        style: TextStyle(color: FQColors.red)),
                    onTap: () async {
                      await NutritionService.setScheduleDay(
                          widget.userData['username'], widget.password,
                          widget.recruitId, day, null);
                      Navigator.pop(context);
                      _load();
                    },
                  );
                }
                return ListTile(
                  leading: const Icon(Icons.restaurant_outlined,
                      color: FQColors.green, size: 18),
                  title: Text(_plans[i]['name'],
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Text(
                      '${_plans[i]['total_calories']} kcal',
                      style: const TextStyle(
                          color: FQColors.muted, fontSize: 11)),
                  onTap: () async {
                    await NutritionService.setScheduleDay(
                        widget.userData['username'], widget.password,
                        widget.recruitId, day, _plans[i]['id']);
                    Navigator.pop(context);
                    _load();
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: FQColors.green));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _days.length,
      itemBuilder: (_, i) {
        final day   = _days[i];
        final entry = _schedule.firstWhere(
            (s) => s['day_of_week'] == day, orElse: () => null);
        final planName  = entry != null && entry['diet_plan_details'] != null
            ? entry['diet_plan_details']['name']
            : null;
        final isRest    = entry != null && entry['diet_plan_details'] == null;
        final isSet     = planName != null;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: FQColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isSet
                    ? FQColors.green.withOpacity(0.35)
                    : FQColors.border),
          ),
          child: ListTile(
            onTap: () => _assignDay(day),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: isSet
                    ? FQColors.green.withOpacity(0.1)
                    : FQColors.card,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(day.substring(0, 3).toUpperCase(),
                  style: TextStyle(
                      color: isSet ? FQColors.green : FQColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
            title: Text(
              isRest ? 'Rest Day' : (planName ?? 'No plan assigned'),
              style: TextStyle(
                  color: isRest
                      ? FQColors.red
                      : isSet
                          ? Colors.white
                          : FQColors.muted,
                  fontSize: 14,
                  fontWeight: isSet ? FontWeight.w600 : FontWeight.normal),
            ),
            subtitle: isSet
                ? Text(
                    '${entry['diet_plan_details']['total_calories']} kcal',
                    style: const TextStyle(
                        color: FQColors.green, fontSize: 11))
                : null,
            trailing: Icon(
              isSet ? Icons.edit_outlined : Icons.add_circle_outline,
              color: isSet ? FQColors.green : FQColors.muted,
              size: 18,
            ),
          ),
        );
      },
    );
  }
}
