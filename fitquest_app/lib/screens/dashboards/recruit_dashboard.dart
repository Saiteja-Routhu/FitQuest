import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth_gate_screen.dart';
import '../edit_profile_screen.dart';
import '../../services/api_service.dart';
import '../../services/analytics_service.dart';
import '../../main.dart';
import 'quest_screen.dart';
import 'shop_screen.dart';
import 'leaderboard_screen.dart';
import 'war_room_screen.dart';
import 'recruit_workout_screen.dart';
import 'recruit_meal_screen.dart';
import 'water_tracker_screen.dart';
import 'step_counter_screen.dart';
import 'pose_coach_screen.dart';
import 'body_scan_screen.dart';
import 'super_coach_services_screen.dart';
import 'transformations_screen.dart';

class RecruitDashboard extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String password;

  const RecruitDashboard(
      {super.key, required this.userData, required this.password});

  @override
  State<RecruitDashboard> createState() => _RecruitDashboardState();
}

class _RecruitDashboardState extends State<RecruitDashboard> {
  late Map<String, dynamic> _userData;

  // Activity data for calendar dots
  Map<String, dynamic> _todayActivity = {};

  @override
  void initState() {
    super.initState();
    _userData = Map<String, dynamic>.from(widget.userData);
    _loadActivity();
  }

  void _openProfile() async {
    final updated = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => EditProfileScreen(
        userData: _userData, password: widget.password)),
    );
    if (updated != null && mounted) {
      setState(() => _userData = updated);
    }
  }

  Future<void> _loadActivity() async {
    try {
      final data = await AnalyticsService.fetchTodayActivity(
          _userData['username'] ?? '', widget.password);
      if (mounted) setState(() => _todayActivity = data);
    } catch (_) {}
  }

  void _logout(BuildContext context) async {
    await ApiService.clearSession();
    if (context.mounted) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const AuthGateScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = _userData['username'] ?? 'Athlete';
    final xp       = _userData['xp']    ?? 0;
    final coins    = _userData['coins'] ?? 0;
    final level    = _userData['level'] ?? 1;
    final goal     = _userData['goal']?.toString() ?? 'General Fitness';

    final xpInLevel  = xp % 500;
    final xpProgress = xpInLevel / 500.0;

    return Scaffold(
      backgroundColor: FQColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, username, level, xp, coins, goal, xpProgress),
            // Calendar strip
            _CalendarStrip(todayActivity: _todayActivity),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.90,
                  children: [
                    _menuCard(
                      context: context,
                      icon: Icons.military_tech_outlined,
                      title: 'MY QUESTS',
                      subtitle: 'Complete for XP & coins',
                      color: FQColors.purple,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => RecruitQuestScreen(
                                  userData: _userData,
                                  password: widget.password))),
                    ),
                    _menuCard(
                      context: context,
                      icon: Icons.storefront_outlined,
                      title: 'THE SHOP',
                      subtitle: 'Spend your coins',
                      color: FQColors.gold,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => RecruitShopScreen(
                                  userData: _userData,
                                  password: widget.password))),
                    ),
                    _menuCard(
                      context: context,
                      icon: Icons.fitness_center,
                      title: 'MY WORKOUTS',
                      subtitle: 'Your training programs',
                      color: FQColors.cyan,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => RecruitWorkoutScreen(
                                  userData: _userData,
                                  password: widget.password))),
                    ),
                    _menuCard(
                      context: context,
                      icon: Icons.restaurant_outlined,
                      title: 'MY MEALS',
                      subtitle: 'Your nutrition plan',
                      color: FQColors.green,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => RecruitMealScreen(
                                  userData: _userData,
                                  password: widget.password))),
                    ),
                    _menuCard(
                      context: context,
                      icon: Icons.leaderboard_outlined,
                      title: 'LEADERBOARD',
                      subtitle: 'Team rankings',
                      color: FQColors.cyan,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => LeaderboardScreen(
                                  userData: _userData,
                                  password: widget.password))),
                    ),
                    _menuCard(
                      context: context,
                      icon: Icons.forum_outlined,
                      title: 'THE WAR ROOM',
                      subtitle: 'Chat with your coach',
                      color: FQColors.purple,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => RecruitWarRoomScreen(
                                  userData: _userData,
                                  password: widget.password))),
                    ),
                    _menuCard(
                      context: context,
                      icon: Icons.water_drop_outlined,
                      title: 'WATER TRACKER',
                      subtitle: 'Stay hydrated',
                      color: FQColors.cyan,
                      onTap: () async {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => WaterTrackerScreen(
                                    userData: _userData,
                                    password: widget.password)));
                        _loadActivity();
                      },
                    ),
                    _menuCard(
                      context: context,
                      icon: Icons.directions_walk_outlined,
                      title: 'STEP COUNTER',
                      subtitle: 'Track your movement',
                      color: FQColors.green,
                      onTap: () async {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => StepCounterScreen(
                                    userData: _userData,
                                    password: widget.password)));
                        _loadActivity();
                      },
                    ),
                    _menuCard(
                      context: context,
                      icon: Icons.accessibility_new_outlined,
                      title: 'POSE COACH',
                      subtitle: 'Live form correction',
                      color: FQColors.purple,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PoseCoachScreen())),
                    ),
                    _menuCard(
                      context: context,
                      icon: Icons.camera_outlined,
                      title: 'BODY SCAN',
                      subtitle: 'AI physique analysis',
                      color: FQColors.gold,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => BodyScanScreen(
                                  userData: _userData,
                                  password: widget.password))),
                    ),
                    _menuCard(
                      context: context,
                      icon: Icons.workspace_premium_outlined,
                      title: 'SC SERVICES',
                      subtitle: 'Premium coach services',
                      color: FQColors.gold,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => SuperCoachServicesScreen(
                                  userData: _userData,
                                  password: widget.password))),
                    ),
                    _menuCard(
                      context: context,
                      icon: Icons.insights_outlined,
                      title: 'MY PROGRESS',
                      subtitle: 'Progress timeline & analytics',
                      color: FQColors.green,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => TransformationsScreen(
                                  userData: _userData,
                                  password: widget.password))),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String username, int level, int xp,
      int coins, String goal, double xpProgress) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: FQColors.border))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          GestureDetector(
            onTap: _openProfile,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: FQColors.cyan.withOpacity(0.12),
                border: Border.all(color: FQColors.cyan.withOpacity(0.35)),
              ),
              child: const Icon(Icons.person_outline,
                  color: FQColors.cyan, size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('ATHLETE HQ',
                  style: GoogleFonts.rajdhani(
                      color: FQColors.muted, fontSize: 11, letterSpacing: 3)),
              Text(username.toUpperCase(),
                  style: GoogleFonts.rajdhani(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
            ]),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: FQColors.gold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: FQColors.gold.withOpacity(0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.monetization_on_outlined,
                  color: FQColors.gold, size: 14),
              const SizedBox(width: 4),
              Text('$coins',
                  style: GoogleFonts.rajdhani(
                      color: FQColors.gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ]),
          ),
          const SizedBox(width: 8),
          IconButton(
              icon: const Icon(Icons.logout, color: FQColors.muted),
              onPressed: () => _logout(context)),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: FQColors.gold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.star, color: FQColors.gold, size: 12),
              const SizedBox(width: 4),
              Text('LEVEL $level',
                  style: GoogleFonts.rajdhani(
                      color: FQColors.gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ]),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${xp % 500} / 500 XP',
                  style: const TextStyle(
                      color: FQColors.muted, fontSize: 10)),
              const SizedBox(height: 3),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: xpProgress,
                  backgroundColor: FQColors.border,
                  color: FQColors.gold,
                  minHeight: 5,
                ),
              ),
            ]),
          ),
          const SizedBox(width: 10),
          goalBadge(goal),
        ]),
      ]),
    );
  }

  Widget _menuCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: FQColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.all(18),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: GoogleFonts.rajdhani(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: FQColors.muted, fontSize: 11)),
                ]),
              ],
            ),
            if (badge != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: FQColors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(badge,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Calendar Strip ─────────────────────────────────────────────────────────────
class _CalendarStrip extends StatefulWidget {
  final Map<String, dynamic> todayActivity;

  const _CalendarStrip({required this.todayActivity});

  @override
  State<_CalendarStrip> createState() => _CalendarStripState();
}

class _CalendarStripState extends State<_CalendarStrip> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Auto-scroll to today (last item) after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(14, (i) => now.subtract(Duration(days: 13 - i)));
    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Today's goal completion
    final waterMl = widget.todayActivity['water_ml'] ?? 0;
    final waterGoal = widget.todayActivity['water_goal_ml'] ?? 2500;
    final steps = widget.todayActivity['steps'] ?? 0;
    final stepGoal = widget.todayActivity['step_goal'] ?? 8000;
    final waterMet = waterMl >= waterGoal && waterGoal > 0;
    final stepsMet = steps >= stepGoal && stepGoal > 0;

    return Container(
      height: 88,
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: FQColors.border))),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: days.length,
        itemBuilder: (_, i) {
          final day = days[i];
          final isToday = i == 13;
          final dayLabel = dayLabels[day.weekday - 1];

          return Container(
            width: 52,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: isToday
                  ? FQColors.cyan.withOpacity(0.08)
                  : FQColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isToday
                    ? FQColors.cyan.withOpacity(0.5)
                    : FQColors.border,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(dayLabel,
                    style: TextStyle(
                        color: isToday ? FQColors.cyan : FQColors.muted,
                        fontSize: 9,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('${day.day}',
                    style: TextStyle(
                        color: isToday ? Colors.white : FQColors.muted,
                        fontSize: 15,
                        fontWeight: isToday
                            ? FontWeight.bold
                            : FontWeight.normal)),
                const SizedBox(height: 4),
                // Micro dots: water=cyan, steps=green
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _dot(isToday && waterMet ? FQColors.cyan : Colors.transparent,
                      isToday && !waterMet ? FQColors.border : null),
                  const SizedBox(width: 3),
                  _dot(isToday && stepsMet ? FQColors.green : Colors.transparent,
                      isToday && !stepsMet ? FQColors.border : null),
                ]),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _dot(Color color, Color? borderColor) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: borderColor != null
            ? Border.all(color: borderColor, width: 1)
            : null,
      ),
    );
  }
}
