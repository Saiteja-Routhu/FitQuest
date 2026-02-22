import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../main.dart';
import '../../services/api_service.dart';

class LeaderboardScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String password;

  const LeaderboardScreen(
      {super.key, required this.userData, required this.password});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<dynamic> _ranked = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    try {
      final roster = await ApiService.fetchLeaderboard(
          widget.userData['username'], widget.password);
      roster.sort((a, b) {
        final lvA = (a['level'] ?? 1) as int;
        final lvB = (b['level'] ?? 1) as int;
        if (lvB != lvA) return lvB.compareTo(lvA);
        final xpA = (a['xp'] ?? 0) as int;
        final xpB = (b['xp'] ?? 0) as int;
        return xpB.compareTo(xpA);
      });
      if (mounted) setState(() { _ranked = roster; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FQColors.bg,
      appBar: AppBar(
        title: const Text('LEADERBOARD'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: FQColors.cyan))
          : _ranked.isEmpty
              ? Center(
                  child: Text('No athletes yet',
                      style: GoogleFonts.rajdhani(
                          color: FQColors.muted, fontSize: 18)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: _ranked.length,
                  itemBuilder: (_, i) =>
                      _LeaderboardTile(rank: i + 1, athlete: _ranked[i]),
                ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> athlete;

  const _LeaderboardTile({required this.rank, required this.athlete});

  Color get _medalColor {
    if (rank == 1) return const Color(0xFFFFD700); // gold
    if (rank == 2) return const Color(0xFFC0C0C0); // silver
    if (rank == 3) return const Color(0xFFCD7F32); // bronze
    return FQColors.muted;
  }

  bool get _hasMedal => rank <= 3;

  @override
  Widget build(BuildContext context) {
    final xp    = (athlete['xp'] ?? 0) as int;
    final level = (athlete['level'] ?? 1) as int;
    final coins = (athlete['coins'] ?? 0) as int;
    final xpProgress = (xp % 500) / 500.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _hasMedal
            ? _medalColor.withOpacity(0.06)
            : FQColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: _hasMedal
                ? _medalColor.withOpacity(0.3)
                : FQColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          // Rank indicator
          SizedBox(
            width: 36,
            child: _hasMedal
                ? Icon(Icons.emoji_events, color: _medalColor, size: 26)
                : Text('$rank',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.rajdhani(
                        color: FQColors.muted,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          // Avatar
          CircleAvatar(
            backgroundColor: _hasMedal
                ? _medalColor.withOpacity(0.2)
                : FQColors.card,
            child: Text(
              athlete['username'].toString().substring(0, 1).toUpperCase(),
              style: TextStyle(
                  color: _hasMedal ? _medalColor : Colors.white,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          // Name + XP bar
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(athlete['username'],
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text('Lv.$level  •  $xp XP',
                  style: const TextStyle(color: FQColors.muted, fontSize: 11)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: xpProgress,
                  backgroundColor: FQColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      _hasMedal ? _medalColor : FQColors.cyan),
                  minHeight: 4,
                ),
              ),
            ]),
          ),
          const SizedBox(width: 12),
          // Coins
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.monetization_on_outlined,
                color: FQColors.gold, size: 14),
            const SizedBox(width: 3),
            Text('$coins',
                style: GoogleFonts.rajdhani(
                    color: FQColors.gold,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
          ]),
        ]),
      ),
    );
  }
}
