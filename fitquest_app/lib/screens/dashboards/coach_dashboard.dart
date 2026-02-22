import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../main.dart';
import '../../services/api_service.dart';
import '../../services/analytics_service.dart';
import '../auth_gate_screen.dart';
import '../edit_profile_screen.dart';
import 'forge_screen.dart';
import 'kitchen_screen.dart';
import 'leaderboard_screen.dart';
import 'quest_screen.dart';
import 'scout_report_screen.dart';
import 'shop_screen.dart';
import 'transformations_screen.dart';
import 'war_room_screen.dart';

class CoachDashboard extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String password;

  const CoachDashboard(
      {super.key, required this.userData, required this.password});

  @override
  State<CoachDashboard> createState() => _CoachDashboardState();
}

class _CoachDashboardState extends State<CoachDashboard> {
  late Map<String, dynamic> _userData;

  // Athletes sheet state
  int  _newCount        = 0;
  bool _loadingAthletes = false;

  // Summary stats state
  bool _loadingStats         = true;
  int  _athleteCount         = 0;
  int  _planCount            = 0;
  int  _dietPlanCount        = 0;
  int  _questCount           = 0;
  int  _completedQuestCount  = 0;
  int  _pendingPurchaseCount = 0;

  @override
  void initState() {
    super.initState();
    _userData = Map<String, dynamic>.from(widget.userData);
    _loadSummary();
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

  void _loadSummary() async {
    try {
      final s = await ApiService.fetchCoachSummary(
          widget.userData['username'], widget.password);
      if (mounted) {
        setState(() {
          _athleteCount         = s['athlete_count']          ?? 0;
          _newCount             = s['new_athlete_count']      ?? 0;
          _planCount            = s['plan_count']             ?? 0;
          _dietPlanCount        = s['diet_plan_count']        ?? 0;
          _questCount           = s['quest_count']            ?? 0;
          _completedQuestCount  = s['completed_quest_count']  ?? 0;
          _pendingPurchaseCount = s['pending_purchase_count'] ?? 0;
          _loadingStats         = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  void _logout() async {
    await ApiService.clearSession();
    if (mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const AuthGateScreen()));
    }
  }

  void _openAthleteProfile(Map<String, dynamic> athlete) {
    if (athlete['is_new_assignment'] == true) {
      ApiService.acknowledgeRecruit(
          widget.userData['username'], widget.password, athlete['id']);
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScoutReportScreen(
          recruit: athlete,
          userData: widget.userData,
          password: widget.password,
        ),
      ),
    );
  }

  void _showTransformationsPickerSheet() async {
    if (_loadingAthletes) return;
    setState(() => _loadingAthletes = true);
    try {
      final athletes = await ApiService.fetchMyRoster(
          widget.userData['username'], widget.password);
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetCtx) => _AthletePickerSheet(
          athletes: athletes,
          onSelect: (a) {
            Navigator.pop(sheetCtx);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TransformationsScreen(
                  userData: widget.userData,
                  password: widget.password,
                  athleteId: a['id'],
                  athleteUsername: a['username'],
                ),
              ),
            );
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), backgroundColor: FQColors.red));
      }
    } finally {
      if (mounted) setState(() => _loadingAthletes = false);
    }
  }

  void _showAthletesSheet() async {
    if (_loadingAthletes) return;
    setState(() => _loadingAthletes = true);
    try {
      final athletes = await ApiService.fetchMyRoster(
          widget.userData['username'], widget.password);
      if (!mounted) return;
      setState(() {
        _newCount = athletes.where((a) => a['is_new_assignment'] == true).length;
      });
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _AthletesSheet(
          athletes: athletes,
          userData: widget.userData,
          password: widget.password,
          onTap: (a) {
            Navigator.pop(context);
            _openAthleteProfile(a);
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), backgroundColor: FQColors.red));
      }
    } finally {
      if (mounted) setState(() => _loadingAthletes = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = _userData['username'] ?? 'Coach';
    return Scaffold(
      backgroundColor: FQColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(username),
            _buildStatsRow(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.88,
                  children: [
                    _menuCard(
                      icon: Icons.group_outlined,
                      title: 'MY ATHLETES',
                      subtitle: _loadingStats
                          ? 'Loading...'
                          : '$_athleteCount athletes on your roster',
                      color: FQColors.cyan,
                      badge: _newCount > 0 ? '$_newCount' : null,
                      onTap: _showAthletesSheet,
                      loading: _loadingAthletes,
                    ),
                    _menuCard(
                      icon: Icons.fitness_center,
                      title: 'THE FORGE',
                      subtitle: _loadingStats
                          ? 'Loading...'
                          : '$_planCount training programs',
                      color: FQColors.gold,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ForgeScreen(
                                  userData: widget.userData,
                                  password: widget.password))),
                    ),
                    _menuCard(
                      icon: Icons.restaurant_outlined,
                      title: 'THE KITCHEN',
                      subtitle: _loadingStats
                          ? 'Loading...'
                          : '$_dietPlanCount meal plans',
                      color: FQColors.green,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => KitchenScreen(
                                  userData: widget.userData,
                                  password: widget.password))),
                    ),
                    _menuCard(
                      icon: Icons.military_tech_outlined,
                      title: 'QUEST BOARD',
                      subtitle: _loadingStats
                          ? 'Loading...'
                          : '$_questCount quests • $_completedQuestCount done',
                      color: FQColors.purple,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => QuestScreen(
                                  userData: widget.userData,
                                  password: widget.password))),
                    ),
                    _menuCard(
                      icon: Icons.storefront_outlined,
                      title: 'THE SHOP',
                      subtitle: _loadingStats
                          ? 'Loading...'
                          : 'Rewards & services',
                      color: FQColors.gold,
                      badge: _pendingPurchaseCount > 0
                          ? '$_pendingPurchaseCount'
                          : null,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ShopScreen(
                                  userData: widget.userData,
                                  password: widget.password))).then((_) {
                        setState(() => _loadingStats = true);
                        _loadSummary();
                      }),
                    ),
                    _menuCard(
                      icon: Icons.leaderboard_outlined,
                      title: 'LEADERBOARD',
                      subtitle: 'Athlete rankings by XP',
                      color: FQColors.cyan,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => LeaderboardScreen(
                                  userData: widget.userData,
                                  password: widget.password))),
                    ),
                    _menuCard(
                      icon: Icons.forum_outlined,
                      title: 'THE WAR ROOM',
                      subtitle: 'Chat with athletes',
                      color: FQColors.purple,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => WarRoomScreen(
                                  userData: widget.userData,
                                  password: widget.password))),
                    ),
                    _menuCard(
                      icon: Icons.timeline_outlined,
                      title: 'TRANSFORMATIONS',
                      subtitle: 'Athlete progress timelines',
                      color: FQColors.green,
                      onTap: _showTransformationsPickerSheet,
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

  Widget _buildHeader(String username) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: FQColors.border))),
      child: Row(children: [
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
            child: const Icon(Icons.shield_outlined, color: FQColors.cyan, size: 22),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('COACH HQ',
                style: GoogleFonts.rajdhani(
                    color: FQColors.muted, fontSize: 14, letterSpacing: 3)),
            Text(username.toUpperCase(),
                style: GoogleFonts.rajdhani(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          ]),
        ),
        IconButton(
            icon: const Icon(Icons.refresh, color: FQColors.muted, size: 20),
            onPressed: () {
              setState(() => _loadingStats = true);
              _loadSummary();
            }),
        IconButton(
            icon: const Icon(Icons.logout, color: FQColors.muted),
            onPressed: _logout),
      ]),
    );
  }

  Widget _buildStatsRow() {
    final total = _planCount + _dietPlanCount;
    final stats = [
      _StatTile(
          label: 'ATHLETES',
          value: _loadingStats ? '—' : '$_athleteCount',
          color: FQColors.cyan),
      _StatTile(
          label: 'PLANS',
          value: _loadingStats ? '—' : '$total',
          color: FQColors.gold),
      _StatTile(
          label: 'QUESTS',
          value: _loadingStats ? '—' : '$_questCount',
          color: FQColors.purple),
      _StatTile(
          label: 'PENDING',
          value: _loadingStats ? '—' : '$_pendingPurchaseCount',
          color: _pendingPurchaseCount > 0 ? FQColors.red : FQColors.muted),
    ];

    return Container(
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: FQColors.border))),
      child: IntrinsicHeight(
        child: Row(
          children: List.generate(stats.length * 2 - 1, (i) {
            if (i.isOdd) {
              return const VerticalDivider(
                  color: FQColors.border, width: 1, thickness: 1);
            }
            return Expanded(child: stats[i ~/ 2]);
          }),
        ),
      ),
    );
  }

  Widget _menuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    String? badge,
    bool loading = false,
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
                  child: loading
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: color, strokeWidth: 2))
                      : Icon(icon, color: color, size: 22),
                ),
                Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title,
                      style: GoogleFonts.rajdhani(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: FQColors.muted, fontSize: 13)),
                ]),
              ],
            ),
            if (badge != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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

// ─── Stat tile ───────────────────────────────────────────────────────────────
class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatTile(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(value,
            style: GoogleFonts.rajdhani(
                color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style: GoogleFonts.rajdhani(
                color: FQColors.muted, fontSize: 11, letterSpacing: 1.5)),
      ]),
    );
  }
}

// ─── Athletes Bottom Sheet ───────────────────────────────────────────────────
class _AthletesSheet extends StatefulWidget {
  final List<dynamic>        athletes;
  final Function(Map<String, dynamic>) onTap;
  final Map<String, dynamic> userData;
  final String               password;

  const _AthletesSheet({
    required this.athletes,
    required this.onTap,
    required this.userData,
    required this.password,
  });

  @override
  State<_AthletesSheet> createState() => _AthletesSheetState();
}

class _AthletesSheetState extends State<_AthletesSheet> {
  String _search = '';
  Map<int, Map<String, dynamic>> _activityMap = {};
  Timer? _activityTimer;

  @override
  void initState() {
    super.initState();
    _loadActivity();
    _activityTimer = Timer.periodic(
        const Duration(seconds: 15), (_) => _loadActivity());
  }

  @override
  void dispose() {
    _activityTimer?.cancel();
    super.dispose();
  }

  void _loadActivity() async {
    try {
      final list = await AnalyticsService.fetchTeamActivity(
          widget.userData['username'], widget.password);
      final map = <int, Map<String, dynamic>>{};
      for (final item in list) {
        if (item['id'] != null) {
          map[item['id'] as int] = Map<String, dynamic>.from(item);
        }
      }
      if (mounted) setState(() => _activityMap = map);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.athletes
        .where((a) => a['username']
            .toString()
            .toLowerCase()
            .contains(_search.toLowerCase()))
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: FQColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: FQColors.border)),
      ),
      child: Column(
        children: [
          Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                  color: FQColors.muted.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Text('MY ATHLETES',
                  style: GoogleFonts.rajdhani(
                      color: FQColors.cyan,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2)),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: FQColors.cyan.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10)),
                child: Text('${widget.athletes.length}',
                    style: const TextStyle(
                        color: FQColors.cyan, fontSize: 12)),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(
                hintText: 'Search athletes...',
                prefixIcon:
                    Icon(Icons.search, color: FQColors.muted, size: 18),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text('No athletes found',
                        style: TextStyle(color: FQColors.muted)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final a = filtered[i] as Map<String, dynamic>;
                      final athleteId = a['id'] as int?;
                      final actData = athleteId != null
                          ? _activityMap[athleteId]
                          : null;
                      return _AthleteTile(
                          athlete: a,
                          activityData: actData,
                          onTap: () => widget.onTap(a));
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Single athlete row ──────────────────────────────────────────────────────
class _AthleteTile extends StatelessWidget {
  final Map<String, dynamic>  athlete;
  final VoidCallback          onTap;
  final Map<String, dynamic>? activityData;

  const _AthleteTile({
    required this.athlete,
    required this.onTap,
    this.activityData,
  });

  @override
  Widget build(BuildContext context) {
    final isNew          = athlete['is_new_assignment'] == true;
    final goal           = athlete['goal']?.toString() ?? 'N/A';
    final level          = athlete['level'] ?? 1;
    final weight         = athlete['weight'];
    final isLive         = activityData != null && activityData!['is_live'] == true;
    final activityType   = activityData?['activity_type'] as String? ?? 'idle';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isLive
            ? FQColors.green.withOpacity(0.04)
            : isNew
                ? FQColors.cyan.withOpacity(0.05)
                : FQColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isLive
                ? FQColors.green.withOpacity(0.3)
                : isNew
                    ? FQColors.cyan.withOpacity(0.35)
                    : FQColors.border),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        onTap: onTap,
        leading: Stack(children: [
          CircleAvatar(
            backgroundColor: isLive
                ? FQColors.green.withOpacity(0.15)
                : isNew
                    ? FQColors.cyan.withOpacity(0.2)
                    : FQColors.surface,
            child: Text(
              athlete['username'].toString().substring(0, 1).toUpperCase(),
              style: TextStyle(
                  color: isLive
                      ? FQColors.green
                      : isNew
                          ? FQColors.cyan
                          : Colors.white,
                  fontWeight: FontWeight.bold),
            ),
          ),
          if (isLive)
            Positioned(
              right: 0, bottom: 0,
              child: Container(
                width: 10, height: 10,
                decoration: const BoxDecoration(
                    color: FQColors.green, shape: BoxShape.circle),
              ),
            ),
        ]),
        title: Row(children: [
          Expanded(
            child: Text(athlete['username'],
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
          if (isLive && activityType != 'idle')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: FQColors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                activityType == 'working_out' ? '💪 Working Out' : '🏃 Walking',
                style: const TextStyle(color: FQColors.green, fontSize: 10),
              ),
            ),
        ]),
        subtitle: Row(
          children: [
            goalBadge(goal),
            const SizedBox(width: 6),
            Text('Lv.$level',
                style: const TextStyle(
                    color: FQColors.gold, fontSize: 11)),
            if (weight != null) ...[
              const SizedBox(width: 6),
              Text('${weight}kg',
                  style: const TextStyle(
                      color: FQColors.muted, fontSize: 11)),
            ],
          ],
        ),
        trailing: isNew
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: FQColors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: FQColors.red.withOpacity(0.4))),
                child: const Text('NEW',
                    style: TextStyle(
                        color: FQColors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              )
            : const Icon(Icons.chevron_right,
                color: FQColors.muted, size: 18),
      ),
    );
  }
}

// ── Athlete Picker Sheet (for Transformations) ────────────────────────────────
class _AthletePickerSheet extends StatelessWidget {
  final List<dynamic> athletes;
  final void Function(Map<String, dynamic>) onSelect;

  const _AthletePickerSheet(
      {required this.athletes, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.70,
      decoration: const BoxDecoration(
        color: FQColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: FQColors.border)),
      ),
      child: Column(children: [
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(top: 12, bottom: 16),
          decoration: BoxDecoration(
            color: FQColors.muted.withOpacity(0.35),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            const Icon(Icons.timeline, color: FQColors.green, size: 20),
            const SizedBox(width: 8),
            Text('SELECT ATHLETE',
                style: GoogleFonts.rajdhani(
                    color: FQColors.green,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2)),
          ]),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: athletes.isEmpty
              ? Center(
                  child: Text('No athletes found',
                      style: TextStyle(color: FQColors.muted)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: athletes.length,
                  itemBuilder: (_, i) {
                    final a = athletes[i] as Map<String, dynamic>;
                    return GestureDetector(
                      onTap: () => onSelect(a),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: FQColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: FQColors.border),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: FQColors.cyan.withOpacity(0.15),
                            child: Text(
                              (a['username'] ?? 'A')
                                  .toString()
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: const TextStyle(
                                  color: FQColors.cyan,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(a['username'] ?? '',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              'Lv.${a['level'] ?? 1} • ${a['goal'] ?? ''}',
                              style: const TextStyle(
                                  color: FQColors.muted, fontSize: 11)),
                          trailing: const Icon(Icons.chevron_right,
                              color: FQColors.muted, size: 18),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
