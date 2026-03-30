import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../main.dart';
import '../../services/guild_service.dart';

class GuildHubScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String password;
  const GuildHubScreen({super.key, required this.userData, required this.password});

  @override
  State<GuildHubScreen> createState() => _GuildHubScreenState();
}

class _GuildHubScreenState extends State<GuildHubScreen> {
  Map<String, dynamic>? _guildData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    try {
      final data = await GuildService.fetchGuildHub(
          widget.userData['username'], widget.password);
      setState(() { _guildData = data; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FQColors.bg,
      appBar: AppBar(
        title: Text('GUILD HUB', style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: FQColors.cyan))
          : _guildData == null || _guildData!['has_guild'] == false
              ? _buildNoGuild()
              : RefreshIndicator(
                  onRefresh: () async => _load(),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildGuildHeader(),
                      const SizedBox(height: 30),
                      Text('ACTIVE BOSS RAIDS', style: GoogleFonts.rajdhani(
                          color: FQColors.gold, fontSize: 18,
                          fontWeight: FontWeight.bold, letterSpacing: 2)),
                      const SizedBox(height: 16),
                      if ((_guildData!['active_quests'] as List).isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: Text('No active boss raids', style: TextStyle(color: FQColors.muted))),
                        )
                      else
                        ...(_guildData!['active_quests'] as List).map((q) => _buildBossCard(q)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildNoGuild() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.group_off_outlined, size: 80, color: FQColors.muted),
          const SizedBox(height: 20),
          Text('YOU ARE NOT IN A GUILD', style: GoogleFonts.rajdhani(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text('Join a squad to participate in Co-Op Boss Raids and earn exclusive rewards!',
                textAlign: TextAlign.center, style: TextStyle(color: FQColors.muted)),
          ),
        ],
      ),
    );
  }

  Widget _buildGuildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [FQColors.surface, FQColors.bg],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FQColors.cyan.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: FQColors.cyan.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.shield, color: FQColors.cyan, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_guildData!['guild_name'].toString().toUpperCase(), style: GoogleFonts.rajdhani(
                  color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              Text('SQUAD FOUNDED', style: TextStyle(color: FQColors.muted, fontSize: 12, letterSpacing: 1)),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        Text(_guildData!['guild_description'] ?? 'A legendary gathering of athletes.',
            style: const TextStyle(color: FQColors.muted, fontSize: 14)),
      ]),
    );
  }

  Widget _buildBossCard(Map<String, dynamic> q) {
    final progress = (q['progress_percent'] as num).toDouble() / 100;
    final metricLabel = q['target_metric'] == 'steps' ? 'STEPS' : 'KG LIFTED';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FQColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FQColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.bolt, color: FQColors.red, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(q['title'].toString().toUpperCase(), style: GoogleFonts.rajdhani(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 12),
        Text(q['description'], style: const TextStyle(color: FQColors.muted, fontSize: 13)),
        const SizedBox(height: 20),
        
        // Progress Bar (Boss Health)
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('BOSS HEALTH', style: GoogleFonts.rajdhani(
              color: FQColors.red, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
          Text('${(100 - (progress * 100)).toInt()}% HP', style: GoogleFonts.rajdhani(
              color: FQColors.red, fontSize: 12, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: FQColors.red.withOpacity(0.1),
            color: FQColors.red,
            minHeight: 12,
          ),
        ),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('SQUAD PROGRESS:', style: TextStyle(color: FQColors.muted, fontSize: 11)),
          Text('${q['current_progress']} / ${q['target_value']} $metricLabel',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ]),
      ]),
    );
  }
}
