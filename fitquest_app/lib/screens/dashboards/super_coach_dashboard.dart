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
import 'quest_screen.dart';
import 'shop_screen.dart';
import 'scout_report_screen.dart';
import 'super_coach_services_screen.dart';
import 'super_coach_war_room_screen.dart';
import 'transformations_screen.dart';

class SuperCoachDashboard extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String password;

  const SuperCoachDashboard(
      {super.key, required this.userData, required this.password});

  @override
  State<SuperCoachDashboard> createState() => _SuperCoachDashboardState();
}

class _SuperCoachDashboardState extends State<SuperCoachDashboard> {
  late Map<String, dynamic> _userData;
  List<dynamic> _coaches = [];
  bool _loadingCoaches = true;

  @override
  void initState() {
    super.initState();
    _userData = Map<String, dynamic>.from(widget.userData);
    _loadCoaches();
  }

  void _loadCoaches() async {
    try {
      final coaches = await ApiService.fetchManagedCoaches(
          _userData['username'], widget.password);
      if (mounted) setState(() { _coaches = coaches; _loadingCoaches = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingCoaches = false);
    }
  }

  void _logout() async {
    await ApiService.clearSession();
    if (mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const AuthGateScreen()));
    }
  }

  void _openProfile() async {
    final updated = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => EditProfileScreen(
        userData: _userData, password: widget.password)),
    );
    if (updated != null && mounted) setState(() => _userData = updated);
  }

  void _showTransformationsPickerSheet() async {
    try {
      final athletes = await ApiService.fetchAllAthletesSC(
          _userData['username'], widget.password);
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetCtx) => _SCAthletePickerSheet(
          athletes: athletes,
          onSelect: (a) {
            Navigator.pop(sheetCtx);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TransformationsScreen(
                  userData: _userData,
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
    }
  }

  void _generateCoachKeyDialog() async {
    try {
      final result = await ApiService.generateKeyForRole(
          _userData['username'], widget.password, 'COACH');
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: FQColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            const Icon(Icons.vpn_key, color: FQColors.gold, size: 22),
            const SizedBox(width: 8),
            Text('COACH KEY', style: GoogleFonts.rajdhani(
                color: FQColors.gold, fontWeight: FontWeight.bold, fontSize: 18)),
          ]),
          content: SelectableText(
            result['key'] ?? '',
            style: GoogleFonts.rajdhani(
                fontSize: 28, fontWeight: FontWeight.bold,
                color: Colors.white, letterSpacing: 3),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CLOSE', style: GoogleFonts.rajdhani(color: FQColors.muted)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: FQColors.red));
      }
    }
  }

  void _showAssignCoachSheet() async {
    try {
      final results = await Future.wait([
        ApiService.fetchAllCoachesSC(_userData['username'], widget.password),
        ApiService.fetchAllAthletesSC(_userData['username'], widget.password),
      ]);
      final coaches  = results[0];
      // Show all athletes in picker (sheet lets user see their coach status)
      final recruits = results[1];

      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _AssignCoachSheet(
          coaches: coaches,
          recruits: recruits,
          username: _userData['username'],
          password: widget.password,
          superCoachId: _userData['id'] as int,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: FQColors.red));
      }
    }
  }

  void _showMyCoachesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MyCoachesSheet(
        coaches: _coaches,
        userData: _userData,
        password: widget.password,
      ),
    );
  }

  void _showAllCoachesSheet() async {
    try {
      final coaches = await ApiService.fetchAllCoachesSC(
          _userData['username'], widget.password);
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _AllCoachesSheet(
          coaches: coaches,
          userData: _userData,
          password: widget.password,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: FQColors.red));
      }
    }
  }

  void _showAllAthletesSheet() async {
    try {
      final athletes = await ApiService.fetchAllAthletesSC(
          _userData['username'], widget.password);
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _AllAthletesSheet(
          athletes: athletes,
          userData: _userData,
          password: widget.password,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: FQColors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = _userData['username'] ?? 'Super Coach';
    final coachCount = _coaches.length;

    return Scaffold(
      backgroundColor: FQColors.bg,
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: FQColors.border))),
            child: Row(children: [
              GestureDetector(
                onTap: _openProfile,
                child: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [FQColors.gold, FQColors.purple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: FQColors.gold.withOpacity(0.5), width: 2),
                  ),
                  child: const Icon(Icons.supervisor_account, color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('SUPER COACH', style: GoogleFonts.rajdhani(
                      color: FQColors.gold, fontSize: 11, letterSpacing: 3)),
                  Text(username.toUpperCase(), style: GoogleFonts.rajdhani(
                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: FQColors.purple.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: FQColors.purple.withOpacity(0.3)),
                ),
                child: Text(
                  _loadingCoaches ? '—' : '$coachCount COACHES',
                  style: GoogleFonts.rajdhani(
                      color: FQColors.purple, fontSize: 11,
                      fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
              IconButton(
                  icon: const Icon(Icons.refresh, color: FQColors.muted, size: 20),
                  onPressed: _loadCoaches),
              IconButton(
                  icon: const Icon(Icons.logout, color: FQColors.muted),
                  onPressed: _logout),
            ]),
          ),

          // Card grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.88,
                children: [
                  _card(icon: Icons.group_outlined, title: 'MY COACHES',
                      subtitle: 'Manage your coaching team',
                      color: FQColors.purple, onTap: _showMyCoachesSheet),
                  _card(icon: Icons.link_outlined, title: 'ASSIGN COACH',
                      subtitle: 'Link athletes to coaches',
                      color: FQColors.green, onTap: _showAssignCoachSheet),
                  _card(icon: Icons.fitness_center_outlined, title: 'THE FORGE',
                      subtitle: 'Create training plans',
                      color: FQColors.cyan,
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => ForgeScreen(
                              userData: _userData, password: widget.password)))),
                  _card(icon: Icons.restaurant_outlined, title: 'THE KITCHEN',
                      subtitle: 'Create meal plans',
                      color: FQColors.green,
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => KitchenScreen(
                              userData: _userData, password: widget.password)))),
                  _card(icon: Icons.military_tech_outlined, title: 'QUEST BOARD',
                      subtitle: 'Manage quests',
                      color: FQColors.gold,
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => QuestScreen(
                              userData: _userData, password: widget.password)))),
                  _card(icon: Icons.storefront_outlined, title: 'THE SHOP',
                      subtitle: 'Manage rewards store',
                      color: FQColors.gold,
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => ShopScreen(
                              userData: _userData, password: widget.password)))),
                  _card(icon: Icons.forum_outlined, title: 'WAR ROOM',
                      subtitle: 'Coach & team chats',
                      color: FQColors.purple,
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => SuperCoachWarRoomScreen(
                              userData: _userData, password: widget.password)))),
                  _card(icon: Icons.vpn_key_outlined, title: 'GENERATE KEY',
                      subtitle: 'Create coach access key',
                      color: FQColors.cyan, onTap: _generateCoachKeyDialog),
                  _card(icon: Icons.workspace_premium_outlined, title: 'MY SERVICES',
                      subtitle: 'Manage SC service store',
                      color: FQColors.purple,
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => SuperCoachServiceManagementScreen(
                              userData: _userData, password: widget.password)))),
                  _card(icon: Icons.timeline_outlined, title: 'TRANSFORMATIONS',
                      subtitle: 'Athlete progress timelines',
                      color: FQColors.green,
                      onTap: _showTransformationsPickerSheet),
                  _card(icon: Icons.groups_2_outlined, title: 'ALL COACHES',
                      subtitle: 'Browse & claim coaches',
                      color: FQColors.purple,
                      onTap: _showAllCoachesSheet),
                  _card(icon: Icons.people_alt_outlined, title: 'ALL ATHLETES',
                      subtitle: 'Browse & claim athletes',
                      color: FQColors.cyan,
                      onTap: _showAllAthletesSheet),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _card({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
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
        child: Column(
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
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: GoogleFonts.rajdhani(
                  color: Colors.white, fontWeight: FontWeight.bold,
                  fontSize: 14, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(color: FQColors.muted, fontSize: 10)),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── My Coaches Sheet ──────────────────────────────────────────────────────────
class _MyCoachesSheet extends StatefulWidget {
  final List<dynamic> coaches;
  final Map<String, dynamic> userData;
  final String password;

  const _MyCoachesSheet({
    required this.coaches,
    required this.userData,
    required this.password,
  });

  @override
  State<_MyCoachesSheet> createState() => _MyCoachesSheetState();
}

class _MyCoachesSheetState extends State<_MyCoachesSheet> {
  // Track which coach IDs are currently loading to prevent duplicate taps
  final Set<int> _loadingIds = {};

  void _showCoachDetail(BuildContext context, Map<String, dynamic> coach) async {
    final id = coach['id'] as int;
    if (_loadingIds.contains(id)) return; // already loading — ignore duplicate tap
    setState(() => _loadingIds.add(id));
    try {
      final athletes = await ApiService.fetchCoachAthletes(
          widget.userData['username'], widget.password, id);
      if (!context.mounted) return;
      setState(() => _loadingIds.remove(id));
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _CoachDetailSheet(
            coach: coach, athletes: athletes,
            userData: widget.userData, password: widget.password),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _loadingIds.remove(id));
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: FQColors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: FQColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: FQColors.border)),
      ),
      child: Column(children: [
        Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
                color: FQColors.muted.withOpacity(0.35),
                borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            const Icon(Icons.group, color: FQColors.purple, size: 20),
            const SizedBox(width: 8),
            Text('MY COACHES', style: GoogleFonts.rajdhani(
                color: FQColors.purple, fontSize: 20,
                fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: FQColors.purple.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${widget.coaches.length}',
                  style: const TextStyle(color: FQColors.purple, fontSize: 11)),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: widget.coaches.isEmpty
              ? Center(child: Text('No coaches assigned to you yet.',
                  style: TextStyle(color: FQColors.muted)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: widget.coaches.length,
                  itemBuilder: (_, i) {
                    final coach = widget.coaches[i] as Map<String, dynamic>;
                    final id = coach['id'] as int;
                    final isLoading = _loadingIds.contains(id);
                    return GestureDetector(
                      onTap: () => _showCoachDetail(context, coach),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: FQColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: FQColors.border),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: FQColors.gold.withOpacity(0.15),
                            child: Text(
                              coach['username'].toString().substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                  color: FQColors.gold, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(coach['username'],
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w600)),
                          subtitle: Text('Lv.${coach['level'] ?? 1}',
                              style: const TextStyle(
                                  color: FQColors.muted, fontSize: 11)),
                          trailing: isLoading
                              ? const SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(
                                      color: FQColors.purple, strokeWidth: 2))
                              : const Icon(Icons.chevron_right,
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

// ── Coach Detail Sheet ────────────────────────────────────────────────────────
class _CoachDetailSheet extends StatefulWidget {
  final Map<String, dynamic> coach;
  final List<dynamic>        athletes;
  final Map<String, dynamic> userData;
  final String               password;

  const _CoachDetailSheet({
    required this.coach,
    required this.athletes,
    required this.userData,
    required this.password,
  });

  @override
  State<_CoachDetailSheet> createState() => _CoachDetailSheetState();
}

class _CoachDetailSheetState extends State<_CoachDetailSheet> {
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
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: FQColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: FQColors.border)),
      ),
      child: Column(children: [
        Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
                color: FQColors.muted.withOpacity(0.35),
                borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            CircleAvatar(
              backgroundColor: FQColors.gold.withOpacity(0.15),
              child: Text(
                widget.coach['username'].toString().substring(0, 1).toUpperCase(),
                style: const TextStyle(color: FQColors.gold, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.coach['username'].toString().toUpperCase(),
                    style: GoogleFonts.rajdhani(
                        color: Colors.white, fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text('${widget.athletes.length} athletes',
                    style: const TextStyle(color: FQColors.muted, fontSize: 12)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        const Divider(height: 1, color: FQColors.border),
        Expanded(
          child: widget.athletes.isEmpty
              ? Center(child: Text('No athletes assigned',
                  style: TextStyle(color: FQColors.muted)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.athletes.length,
                  itemBuilder: (_, i) {
                    final a = widget.athletes[i] as Map<String, dynamic>;
                    final athleteId = a['id'] as int?;
                    final actData = athleteId != null ? _activityMap[athleteId] : null;
                    final isLive = actData != null && actData['is_live'] == true;
                    final activityType = actData?['activity_type'] as String? ?? 'idle';

                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => ScoutReportScreen(
                              recruit: a,
                              userData: widget.userData,
                              password: widget.password))),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isLive
                              ? FQColors.green.withOpacity(0.05)
                              : FQColors.card,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: isLive
                                  ? FQColors.green.withOpacity(0.3)
                                  : FQColors.border),
                        ),
                        child: ListTile(
                          leading: Stack(children: [
                            CircleAvatar(
                              backgroundColor: FQColors.cyan.withOpacity(0.1),
                              child: Text(
                                a['username'].toString().substring(0, 1).toUpperCase(),
                                style: const TextStyle(color: FQColors.cyan),
                              ),
                            ),
                            if (isLive)
                              Positioned(
                                right: 0, bottom: 0,
                                child: Container(
                                  width: 10, height: 10,
                                  decoration: const BoxDecoration(
                                    color: FQColors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ]),
                          title: Row(children: [
                            Expanded(
                              child: Text(a['username'],
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600)),
                            ),
                            if (isLive && activityType != 'idle')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: FQColors.green.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  activityType == 'working_out'
                                      ? '💪 Working Out'
                                      : '🏃 Walking',
                                  style: const TextStyle(
                                      color: FQColors.green, fontSize: 10),
                                ),
                              ),
                          ]),
                          subtitle: Text(
                              'Lv.${a['level'] ?? 1}  •  ${a['goal'] ?? 'N/A'}',
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

// ── Assign Coach Sheet ────────────────────────────────────────────────────────
class _AssignCoachSheet extends StatefulWidget {
  final List<dynamic> coaches;
  final List<dynamic> recruits;
  final String username;
  final String password;
  final int superCoachId;

  const _AssignCoachSheet({
    required this.coaches,
    required this.recruits,
    required this.username,
    required this.password,
    required this.superCoachId,
  });

  @override
  State<_AssignCoachSheet> createState() => _AssignCoachSheetState();
}

class _AssignCoachSheetState extends State<_AssignCoachSheet> {
  Map<String, dynamic>? _selectedCoach;
  final Set<int> _selectedRecruits = {};
  bool _saving = false;

  void _assign() async {
    if (_selectedCoach == null || _selectedRecruits.isEmpty) return;
    setState(() => _saving = true);
    try {
      for (final recruitId in _selectedRecruits) {
        await ApiService.assignCoach(
            widget.username, widget.password,
            recruitId, _selectedCoach!['id'] as int);
      }
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Assigned ${_selectedRecruits.length} athlete(s) to ${_selectedCoach!['username']}'),
        backgroundColor: FQColors.green,
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: FQColors.red));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: FQColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: FQColors.border)),
      ),
      child: Column(children: [
        Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
                color: FQColors.muted.withOpacity(0.35),
                borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            const Icon(Icons.link, color: FQColors.green, size: 20),
            const SizedBox(width: 8),
            Text('ASSIGN COACH', style: GoogleFonts.rajdhani(
                color: FQColors.green, fontSize: 20,
                fontWeight: FontWeight.bold, letterSpacing: 2)),
          ]),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: DropdownButtonFormField<Map<String, dynamic>>(
            value: _selectedCoach,
            hint: Text('Select a Coach', style: TextStyle(color: FQColors.muted)),
            dropdownColor: FQColors.card,
            decoration: const InputDecoration(
              labelText: 'COACH',
              labelStyle: TextStyle(color: FQColors.gold),
              prefixIcon: Icon(Icons.shield_outlined, color: FQColors.gold, size: 18),
            ),
            items: widget.coaches.map((c) => DropdownMenuItem<Map<String, dynamic>>(
              value: c as Map<String, dynamic>,
              child: Text(c['username'],
                  style: const TextStyle(color: Colors.white)),
            )).toList(),
            onChanged: (v) => setState(() => _selectedCoach = v),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Text('SELECT ATHLETES', style: GoogleFonts.rajdhani(
                color: FQColors.muted, fontSize: 11,
                letterSpacing: 2, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            if (_selectedRecruits.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: FQColors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${_selectedRecruits.length} selected',
                    style: const TextStyle(color: FQColors.green, fontSize: 11)),
              ),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: widget.recruits.isEmpty
              ? Center(child: Text('No athletes found',
                  style: TextStyle(color: FQColors.muted)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: widget.recruits.length,
                  itemBuilder: (_, i) {
                    final r  = widget.recruits[i] as Map<String, dynamic>;
                    final id = r['id'] as int;
                    final checked = _selectedRecruits.contains(id);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: checked ? FQColors.green.withOpacity(0.06) : FQColors.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: checked
                                ? FQColors.green.withOpacity(0.4)
                                : FQColors.border),
                      ),
                      child: CheckboxListTile(
                        value: checked,
                        activeColor: FQColors.green,
                        checkColor: Colors.black,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                        title: Text(r['username'],
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          'Lv.${r['level'] ?? 1}  •  ${r['goal'] ?? 'N/A'}'
                          '${r['coach_name'] != null ? "  •  Coach: ${r['coach_name']}" : "  •  No coach"}',
                          style: const TextStyle(color: FQColors.muted, fontSize: 10),
                        ),
                        secondary: CircleAvatar(
                          backgroundColor: FQColors.green.withOpacity(checked ? 0.2 : 0.08),
                          child: Text(
                            r['username'].toString().substring(0, 1).toUpperCase(),
                            style: TextStyle(
                                color: checked ? FQColors.green : Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        onChanged: (_) => setState(() {
                          if (checked) _selectedRecruits.remove(id);
                          else _selectedRecruits.add(id);
                        }),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: (_selectedCoach == null || _selectedRecruits.isEmpty || _saving)
                  ? null : _assign,
              style: ElevatedButton.styleFrom(
                backgroundColor: FQColors.green,
                foregroundColor: Colors.black,
                disabledBackgroundColor: FQColors.border,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const CircularProgressIndicator(color: Colors.black, strokeWidth: 2)
                  : Text(
                      _selectedCoach == null
                          ? 'SELECT A COACH FIRST'
                          : _selectedRecruits.isEmpty
                              ? 'SELECT ATHLETES'
                              : 'ASSIGN ${_selectedRecruits.length} ATHLETE(S)',
                      style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── All Coaches Sheet ─────────────────────────────────────────────────────────
class _AllCoachesSheet extends StatefulWidget {
  final List<dynamic> coaches;
  final Map<String, dynamic> userData;
  final String password;

  const _AllCoachesSheet({
    required this.coaches,
    required this.userData,
    required this.password,
  });

  @override
  State<_AllCoachesSheet> createState() => _AllCoachesSheetState();
}

class _AllCoachesSheetState extends State<_AllCoachesSheet> {
  late List<dynamic> _coaches;
  String _search = '';
  final Set<int> _claiming = {};

  @override
  void initState() {
    super.initState();
    _coaches = List.from(widget.coaches);
  }

  List<dynamic> get _filtered => _search.isEmpty
      ? _coaches
      : _coaches
          .where((c) => (c['username'] as String)
              .toLowerCase()
              .contains(_search.toLowerCase()))
          .toList();

  Future<void> _claim(Map<String, dynamic> coach) async {
    final id = coach['id'] as int;
    setState(() => _claiming.add(id));
    try {
      await ApiService.scClaimCoach(
          widget.userData['username'], widget.password, id);
      if (!mounted) return;
      // Update local list so the row flips to "YOURS"
      setState(() {
        final idx = _coaches.indexWhere((c) => c['id'] == id);
        if (idx >= 0) {
          _coaches[idx] = Map<String, dynamic>.from(_coaches[idx])
            ..['super_coach_id'] = widget.userData['id']
            ..['super_coach_name'] = widget.userData['username'];
        }
        _claiming.remove(id);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${coach['username']} now under your management'),
        backgroundColor: FQColors.purple,
      ));
    } catch (e) {
      if (mounted) {
        setState(() => _claiming.remove(id));
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: FQColors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final scId = widget.userData['id'];

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: FQColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: FQColors.border)),
      ),
      child: Column(children: [
        Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
                color: FQColors.muted.withOpacity(0.35),
                borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            const Icon(Icons.groups_2_outlined, color: FQColors.purple, size: 20),
            const SizedBox(width: 8),
            Text('ALL COACHES',
                style: GoogleFonts.rajdhani(
                    color: FQColors.purple,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: FQColors.purple.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${_coaches.length}',
                  style: const TextStyle(color: FQColors.purple, fontSize: 11)),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search coaches...',
              hintStyle: const TextStyle(color: FQColors.muted, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: FQColors.muted, size: 18),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              filled: true,
              fillColor: FQColors.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: FQColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: FQColors.border),
              ),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: filtered.isEmpty
              ? Center(child: Text('No coaches found',
                  style: TextStyle(color: FQColors.muted)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final c = filtered[i] as Map<String, dynamic>;
                    final id = c['id'] as int;
                    final superCoachId = c['super_coach_id'];
                    final isYours = superCoachId != null && superCoachId == scId;
                    final isClaiming = _claiming.contains(id);
                    final managedBy = c['super_coach_name'] as String?;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isYours
                            ? FQColors.purple.withOpacity(0.05)
                            : FQColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: isYours
                                ? FQColors.purple.withOpacity(0.3)
                                : FQColors.border),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: FQColors.purple.withOpacity(0.15),
                          child: Text(
                            c['username'].toString().substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                                color: FQColors.purple, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(c['username'],
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          isYours
                              ? '⭐ YOUR COACH'
                              : managedBy != null
                                  ? 'Managed by: $managedBy'
                                  : 'Lv.${c['level'] ?? 1}  •  Unassigned',
                          style: TextStyle(
                              color: isYours ? FQColors.purple : FQColors.muted,
                              fontSize: 11),
                        ),
                        trailing: isYours
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: FQColors.green.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text('✓ YOURS',
                                    style: TextStyle(
                                        color: FQColors.green,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                              )
                            : isClaiming
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        color: FQColors.purple, strokeWidth: 2))
                                : GestureDetector(
                                    onTap: () => _claim(c),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: FQColors.gold.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: FQColors.gold.withOpacity(0.4)),
                                      ),
                                      child: Text('CLAIM',
                                          style: GoogleFonts.rajdhani(
                                              color: FQColors.gold,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold)),
                                    ),
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

// ── All Athletes Sheet ────────────────────────────────────────────────────────
class _AllAthletesSheet extends StatefulWidget {
  final List<dynamic> athletes;
  final Map<String, dynamic> userData;
  final String password;

  const _AllAthletesSheet({
    required this.athletes,
    required this.userData,
    required this.password,
  });

  @override
  State<_AllAthletesSheet> createState() => _AllAthletesSheetState();
}

class _AllAthletesSheetState extends State<_AllAthletesSheet> {
  late List<dynamic> _athletes;
  String _search = '';
  final Set<int> _claiming = {};

  @override
  void initState() {
    super.initState();
    _athletes = List.from(widget.athletes);
  }

  List<dynamic> get _filtered => _search.isEmpty
      ? _athletes
      : _athletes
          .where((a) => (a['username'] as String)
              .toLowerCase()
              .contains(_search.toLowerCase()))
          .toList();

  Future<void> _claim(Map<String, dynamic> athlete) async {
    final id = athlete['id'] as int;
    setState(() => _claiming.add(id));
    try {
      await ApiService.scClaimAthlete(
          widget.userData['username'], widget.password, id);
      if (!mounted) return;
      setState(() {
        final idx = _athletes.indexWhere((a) => a['id'] == id);
        if (idx >= 0) {
          _athletes[idx] = Map<String, dynamic>.from(_athletes[idx])
            ..['coach_id'] = widget.userData['id']
            ..['coach_name'] = widget.userData['username'];
        }
        _claiming.remove(id);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${athlete['username']} assigned to you'),
        backgroundColor: FQColors.cyan,
      ));
    } catch (e) {
      if (mounted) {
        setState(() => _claiming.remove(id));
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: FQColors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final scId = widget.userData['id'];

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: FQColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: FQColors.border)),
      ),
      child: Column(children: [
        Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
                color: FQColors.muted.withOpacity(0.35),
                borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            const Icon(Icons.people_alt_outlined, color: FQColors.cyan, size: 20),
            const SizedBox(width: 8),
            Text('ALL ATHLETES',
                style: GoogleFonts.rajdhani(
                    color: FQColors.cyan,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: FQColors.cyan.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${_athletes.length}',
                  style: const TextStyle(color: FQColors.cyan, fontSize: 11)),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search athletes...',
              hintStyle: const TextStyle(color: FQColors.muted, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: FQColors.muted, size: 18),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              filled: true,
              fillColor: FQColors.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: FQColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: FQColors.border),
              ),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: filtered.isEmpty
              ? Center(child: Text('No athletes found',
                  style: TextStyle(color: FQColors.muted)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final a = filtered[i] as Map<String, dynamic>;
                    final id = a['id'] as int;
                    final coachId = a['coach_id'];
                    final isYours = coachId != null && coachId == scId;
                    final isClaiming = _claiming.contains(id);
                    final coachName = a['coach_name'] as String?;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isYours
                            ? FQColors.cyan.withOpacity(0.05)
                            : FQColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: isYours
                                ? FQColors.cyan.withOpacity(0.3)
                                : FQColors.border),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: FQColors.cyan.withOpacity(0.15),
                          child: Text(
                            a['username'].toString().substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                                color: FQColors.cyan, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(a['username'],
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w600)),
                        subtitle: Row(children: [
                          Expanded(
                            child: Text(
                              'Lv.${a['level'] ?? 1}  •  ${a['goal'] ?? 'N/A'}',
                              style: const TextStyle(
                                  color: FQColors.muted, fontSize: 11),
                            ),
                          ),
                          if (!isYours)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: coachName != null
                                    ? FQColors.muted.withOpacity(0.1)
                                    : FQColors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                coachName != null
                                    ? 'Coach: $coachName'
                                    : 'No Coach',
                                style: TextStyle(
                                    color: coachName != null
                                        ? FQColors.muted
                                        : FQColors.red,
                                    fontSize: 10),
                              ),
                            ),
                        ]),
                        trailing: isYours
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: FQColors.green.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text('✓ YOURS',
                                    style: TextStyle(
                                        color: FQColors.green,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                              )
                            : isClaiming
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        color: FQColors.cyan, strokeWidth: 2))
                                : GestureDetector(
                                    onTap: () => _claim(a),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: FQColors.cyan.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: FQColors.cyan.withOpacity(0.4)),
                                      ),
                                      child: Text('CLAIM',
                                          style: GoogleFonts.rajdhani(
                                              color: FQColors.cyan,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold)),
                                    ),
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

// ── SC Athlete Picker Sheet (for Transformations) ─────────────────────────────
class _SCAthletePickerSheet extends StatelessWidget {
  final List<dynamic> athletes;
  final void Function(Map<String, dynamic>) onSelect;

  const _SCAthletePickerSheet(
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
