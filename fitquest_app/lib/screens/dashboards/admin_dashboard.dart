import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../main.dart';
import '../../services/api_service.dart';
import '../auth_gate_screen.dart';
import '../edit_profile_screen.dart';

class AdminDashboard extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String password;

  const AdminDashboard(
      {super.key, required this.userData, required this.password});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late Map<String, dynamic> _userData;

  @override
  void initState() {
    super.initState();
    _userData = Map<String, dynamic>.from(widget.userData);
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
    if (updated != null && mounted) {
      setState(() => _userData = updated);
    }
  }

  void _generateSuperCoachKeyDialog() async {
    try {
      final result = await ApiService.generateKeyForRole(
          _userData['username'], widget.password, 'SUPER_COACH');
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: FQColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            const Icon(Icons.vpn_key, color: FQColors.purple, size: 22),
            const SizedBox(width: 8),
            Text('SUPER COACH KEY',
                style: GoogleFonts.rajdhani(
                    color: FQColors.purple,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
          ]),
          content: SelectableText(
            result['key'] ?? '',
            style: GoogleFonts.rajdhani(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 3),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CLOSE',
                  style: GoogleFonts.rajdhani(color: FQColors.muted)),
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

  void _showUserManagementDialog() async {
    try {
      final users = await ApiService.fetchAllUsers(
          _userData['username'], widget.password);
      if (!mounted) return;

      final recruits = users.where((u) => u['role'] == 'RECRUIT').toList();
      final coaches  = users.where((u) => u['role'] == 'GUILD_MASTER').toList();
      final supers   = users.where((u) => u['role'] == 'SUPER_COACH').toList();

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _UserManagementSheet(
          users: [...supers, ...coaches, ...recruits],
          currentUserId: _userData['id'] as int,
          username: _userData['username'],
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

  void _showPersonnelDialog() async {
    try {
      final users = await ApiService.fetchAllUsers(
          _userData['username'], widget.password);
      if (!mounted) return;

      final coaches  = users.where((u) => u['role'] == 'GUILD_MASTER').toList();
      final recruits = users.where((u) => u['role'] == 'RECRUIT').toList();
      final admins   = users.where((u) => u['role'] == 'HIGH_COUNCIL').toList();

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => Container(
          height: MediaQuery.of(context).size.height * 0.80,
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
                Text('PERSONNEL',
                    style: GoogleFonts.rajdhani(
                        color: FQColors.cyan,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2)),
                const SizedBox(width: 10),
                _countChip('${users.length}', FQColors.cyan),
              ]),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (admins.isNotEmpty) ...[
                    _sectionHeader('HIGH COUNCIL', FQColors.red, admins.length),
                    ...admins.map((u) => _personnelTile(u, FQColors.red)),
                    const SizedBox(height: 12),
                  ],
                  if (coaches.isNotEmpty) ...[
                    _sectionHeader('COACHES', FQColors.gold, coaches.length),
                    ...coaches.map((u) => _personnelTile(u, FQColors.gold)),
                    const SizedBox(height: 12),
                  ],
                  if (recruits.isNotEmpty) ...[
                    _sectionHeader('ATHLETES', FQColors.cyan, recruits.length),
                    ...recruits.map((u) => _personnelTile(u, FQColors.cyan)),
                  ],
                ],
              ),
            ),
          ]),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: FQColors.red));
      }
    }
  }

  void _showCoachesSheet() async {
    try {
      final users = await ApiService.fetchAllUsers(
          _userData['username'], widget.password);
      if (!mounted) return;

      final coaches  = users.where((u) => u['role'] == 'GUILD_MASTER').toList();
      final recruits = users.where((u) => u['role'] == 'RECRUIT').toList();

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => Container(
          height: MediaQuery.of(context).size.height * 0.92,
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
                const Icon(Icons.sports, color: FQColors.purple, size: 20),
                const SizedBox(width: 8),
                Text('COACHING STAFF',
                    style: GoogleFonts.rajdhani(
                        color: FQColors.purple,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2)),
                const SizedBox(width: 10),
                _countChip('${coaches.length}', FQColors.purple),
              ]),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: coaches.isEmpty
                  ? Center(
                      child: Text('No coaches found',
                          style: TextStyle(color: FQColors.muted)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: coaches.length,
                      itemBuilder: (_, i) {
                        final coach = coaches[i] as Map<String, dynamic>;
                        final coachId = coach['id'] as int;
                        final athleteCount = recruits
                            .where((r) => r['coach'] == coachId)
                            .length;
                        return GestureDetector(
                          onTap: () {
                            final coachAthletes = recruits
                                .where((r) => r['coach'] == coachId)
                                .toList();
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => _CoachDetailSheet(
                                coach: coach,
                                athletes: coachAthletes,
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: FQColors.card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: FQColors.border),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: FQColors.purple.withOpacity(0.15),
                                child: Text(
                                  coach['username'].toString().substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                      color: FQColors.purple,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(coach['username'],
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text('$athleteCount athletes',
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
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: FQColors.red));
      }
    }
  }

  Widget _sectionHeader(String label, Color color, int count) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Text(label,
              style: GoogleFonts.rajdhani(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2)),
          const SizedBox(width: 8),
          _countChip('$count', color),
        ]),
      );

  Widget _countChip(String val, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(val, style: TextStyle(color: color, fontSize: 11)),
      );

  Widget _personnelTile(Map<String, dynamic> user, Color color) => Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: FQColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: FQColors.border),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Text(
              user['username'].toString().substring(0, 1).toUpperCase(),
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(user['username'],
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
          subtitle: Text(user['email'] ?? '',
              style: const TextStyle(color: FQColors.muted, fontSize: 11)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final username = _userData['username'] ?? 'Admin';
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
                    color: FQColors.red.withOpacity(0.12),
                    border: Border.all(color: FQColors.red.withOpacity(0.35)),
                  ),
                  child: const Icon(Icons.security, color: FQColors.red, size: 22),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('HIGH COUNCIL',
                      style: GoogleFonts.rajdhani(
                          color: FQColors.muted,
                          fontSize: 11,
                          letterSpacing: 3)),
                  Text(username.toUpperCase(),
                      style: GoogleFonts.rajdhani(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: FQColors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: FQColors.green.withOpacity(0.3)),
                ),
                child: Text('ONLINE',
                    style: GoogleFonts.rajdhani(
                        color: FQColors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1)),
              ),
              IconButton(
                  icon: const Icon(Icons.logout, color: FQColors.muted),
                  onPressed: _logout),
            ]),
          ),

          // Grid cards
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.88,
                children: [
                  _adminCard(
                    icon: Icons.vpn_key_outlined,
                    title: 'SUPER COACH KEY',
                    subtitle: 'Generate super coach key',
                    color: FQColors.purple,
                    onTap: _generateSuperCoachKeyDialog,
                  ),
                  _adminCard(
                    icon: Icons.people_outline,
                    title: 'PERSONNEL',
                    subtitle: 'View all system users',
                    color: FQColors.cyan,
                    onTap: _showPersonnelDialog,
                  ),
                  _adminCard(
                    icon: Icons.sports_outlined,
                    title: 'COACHES',
                    subtitle: 'View coaching staff',
                    color: FQColors.gold,
                    onTap: _showCoachesSheet,
                  ),
                  _adminCard(
                    icon: Icons.manage_accounts_outlined,
                    title: 'USER MGMT',
                    subtitle: 'Delete or manage users',
                    color: FQColors.red,
                    onTap: _showUserManagementDialog,
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _adminCard({
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
              Text(title,
                  style: GoogleFonts.rajdhani(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(color: FQColors.muted, fontSize: 11)),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── Coach Detail Sheet ────────────────────────────────────────────────────────
class _CoachDetailSheet extends StatelessWidget {
  final Map<String, dynamic> coach;
  final List<dynamic>        athletes;

  const _CoachDetailSheet({required this.coach, required this.athletes});

  @override
  Widget build(BuildContext context) {
    final totalXp = athletes.fold<int>(
        0, (sum, a) => sum + ((a['xp'] ?? 0) as int));

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
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
              backgroundColor: FQColors.purple.withOpacity(0.15),
              child: Text(
                coach['username'].toString().substring(0, 1).toUpperCase(),
                style: const TextStyle(
                    color: FQColors.purple, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(coach['username'].toString().toUpperCase(),
                    style: GoogleFonts.rajdhani(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text('${athletes.length} athletes  •  $totalXp total XP',
                    style: const TextStyle(color: FQColors.muted, fontSize: 12)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        const Divider(height: 1, color: FQColors.border),
        Expanded(
          child: athletes.isEmpty
              ? Center(
                  child: Text('No athletes assigned',
                      style: TextStyle(color: FQColors.muted)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: athletes.length,
                  itemBuilder: (_, i) {
                    final a     = athletes[i] as Map<String, dynamic>;
                    final goal  = a['goal']?.toString()  ?? 'N/A';
                    final level = a['level']             ?? 1;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: FQColors.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: FQColors.border),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
                        leading: CircleAvatar(
                          backgroundColor: FQColors.cyan.withOpacity(0.1),
                          child: Text(
                            a['username'].toString().substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: FQColors.cyan),
                          ),
                        ),
                        title: Text(a['username'],
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w600)),
                        subtitle: Row(children: [
                          goalBadge(goal),
                          const SizedBox(width: 6),
                          Text('Lv.$level',
                              style: const TextStyle(
                                  color: FQColors.gold, fontSize: 11)),
                        ]),
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

// ── User Management Sheet ─────────────────────────────────────────────────────
class _UserManagementSheet extends StatefulWidget {
  final List<dynamic> users;
  final int currentUserId;
  final String username;
  final String password;

  const _UserManagementSheet({
    required this.users,
    required this.currentUserId,
    required this.username,
    required this.password,
  });

  @override
  State<_UserManagementSheet> createState() => _UserManagementSheetState();
}

class _UserManagementSheetState extends State<_UserManagementSheet> {
  late List<dynamic> _users;

  @override
  void initState() {
    super.initState();
    _users = List.from(widget.users);
  }

  void _confirmDelete(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: FQColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('DELETE USER?', style: GoogleFonts.rajdhani(
            color: FQColors.red, fontWeight: FontWeight.bold, fontSize: 18)),
        content: Text(
          'Are you sure you want to delete "${user['username']}"? This cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: GoogleFonts.rajdhani(color: FQColors.muted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ApiService.deleteUser(
                    widget.username, widget.password, user['id'] as int);
                setState(() => _users.remove(user));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('${user['username']} deleted'),
                    backgroundColor: FQColors.green,
                  ));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: FQColors.red,
                  ));
                }
              }
            },
            child: Text('DELETE', style: GoogleFonts.rajdhani(
                color: FQColors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'SUPER_COACH': return FQColors.purple;
      case 'GUILD_MASTER': return FQColors.gold;
      case 'RECRUIT': return FQColors.cyan;
      default: return FQColors.muted;
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
            const Icon(Icons.manage_accounts, color: FQColors.red, size: 20),
            const SizedBox(width: 8),
            Text('USER MANAGEMENT', style: GoogleFonts.rajdhani(
                color: FQColors.red, fontSize: 20,
                fontWeight: FontWeight.bold, letterSpacing: 2)),
          ]),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _users.isEmpty
              ? Center(child: Text('No users', style: TextStyle(color: FQColors.muted)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _users.length,
                  itemBuilder: (_, i) {
                    final u = _users[i] as Map<String, dynamic>;
                    final isSelf = u['id'] == widget.currentUserId;
                    final color = _roleColor(u['role'] ?? '');
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: FQColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: FQColors.border),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.15),
                          child: Text(
                            u['username'].toString().substring(0, 1).toUpperCase(),
                            style: TextStyle(color: color, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(u['username'],
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          (u['role'] ?? '').toString().replaceAll('_', ' '),
                          style: TextStyle(color: color, fontSize: 11),
                        ),
                        trailing: isSelf
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: FQColors.red, size: 20),
                                onPressed: () => _confirmDelete(u),
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
