import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../main.dart';
import '../../services/analytics_service.dart';

class WaterTrackerScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String password;

  const WaterTrackerScreen(
      {super.key, required this.userData, required this.password});

  @override
  State<WaterTrackerScreen> createState() => _WaterTrackerScreenState();
}

class _WaterTrackerScreenState extends State<WaterTrackerScreen> {
  int _waterMl = 0;
  int _goalMl = 2500;
  bool _loading = true;

  String get _username => widget.userData['username'] ?? '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await AnalyticsService.fetchTodayActivity(
          _username, widget.password);
      setState(() {
        _waterMl = data['water_ml'] ?? 0;
        _goalMl = data['water_goal_ml'] ?? 2500;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _add(int ml) async {
    final newVal = _waterMl + ml;
    setState(() => _waterMl = newVal);
    try {
      await AnalyticsService.updateTodayActivity(
          _username, widget.password, waterMl: newVal);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sync failed: $e'),
                backgroundColor: FQColors.red));
      }
    }
  }

  Future<void> _showCustomDialog() async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: FQColors.surface,
        title: Text('Add Custom Amount',
            style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 18)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
              hintText: 'ml', hintStyle: TextStyle(color: FQColors.muted)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL',
                  style: TextStyle(color: FQColors.muted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: FQColors.cyan, foregroundColor: Colors.black),
            onPressed: () {
              final v = int.tryParse(ctrl.text);
              if (v != null && v > 0) _add(v);
              Navigator.pop(context);
            },
            child: const Text('ADD'),
          ),
        ],
      ),
    );
  }

  Future<void> _setGoalDialog() async {
    final ctrl = TextEditingController(text: '$_goalMl');
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: FQColors.surface,
        title: Text('Set Daily Goal',
            style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 18)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
              hintText: 'ml', hintStyle: TextStyle(color: FQColors.muted)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL',
                  style: TextStyle(color: FQColors.muted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: FQColors.cyan, foregroundColor: Colors.black),
            onPressed: () async {
              final v = int.tryParse(ctrl.text);
              if (v != null && v > 0) {
                setState(() => _goalMl = v);
                await AnalyticsService.updateTodayActivity(
                    _username, widget.password, waterGoalMl: v);
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  String get _statusLabel {
    final pct = _goalMl > 0 ? _waterMl / _goalMl : 0.0;
    if (pct >= 1.0) return 'HYDRATED';
    if (pct >= 0.5) return 'KEEP DRINKING';
    return 'DEHYDRATED';
  }

  Color get _statusColor {
    final pct = _goalMl > 0 ? _waterMl / _goalMl : 0.0;
    if (pct >= 1.0) return FQColors.green;
    if (pct >= 0.5) return FQColors.cyan;
    return FQColors.red;
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        _goalMl > 0 ? (_waterMl / _goalMl).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: FQColors.bg,
      appBar: AppBar(
        backgroundColor: FQColors.surface,
        foregroundColor: Colors.white,
        title: Text('WATER TRACKER',
            style: GoogleFonts.rajdhani(
                fontWeight: FontWeight.bold, letterSpacing: 2)),
        actions: [
          IconButton(
              icon: const Icon(Icons.track_changes_outlined,
                  color: FQColors.cyan),
              onPressed: _setGoalDialog,
              tooltip: 'Set Goal'),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: FQColors.cyan))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  // Circular progress
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 220,
                        height: 220,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 14,
                          backgroundColor: FQColors.border,
                          color: FQColors.cyan,
                        ),
                      ),
                      Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.water_drop,
                            color: FQColors.cyan, size: 32),
                        const SizedBox(height: 8),
                        Text('${_waterMl}ml',
                            style: GoogleFonts.rajdhani(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold)),
                        Text('of ${_goalMl}ml',
                            style: const TextStyle(
                                color: FQColors.muted, fontSize: 13)),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Status label
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _statusColor.withOpacity(0.4)),
                    ),
                    child: Text(_statusLabel,
                        style: GoogleFonts.rajdhani(
                            color: _statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 2)),
                  ),
                  const SizedBox(height: 32),
                  // Quick add buttons
                  Text('QUICK ADD',
                      style: GoogleFonts.rajdhani(
                          color: FQColors.muted,
                          fontSize: 12,
                          letterSpacing: 2)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (final ml in [200, 350, 500]) ...[
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _add(ml),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  FQColors.cyan.withOpacity(0.12),
                              foregroundColor: FQColors.cyan,
                              side: BorderSide(
                                  color: FQColors.cyan.withOpacity(0.4)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                            ),
                            child: Text('+${ml}ml',
                                style: GoogleFonts.rajdhani(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                          ),
                        ),
                        if (ml != 500) const SizedBox(width: 8),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showCustomDialog,
                      icon: const Icon(Icons.add, color: FQColors.cyan,
                          size: 16),
                      label: Text('CUSTOM AMOUNT',
                          style: GoogleFonts.rajdhani(
                              color: FQColors.cyan,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: FQColors.cyan.withOpacity(0.3)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Progress bar
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                      const Text('Progress',
                          style: TextStyle(
                              color: FQColors.muted, fontSize: 12)),
                      Text('${(progress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                              color: FQColors.cyan, fontSize: 12)),
                    ]),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: FQColors.border,
                        color: FQColors.cyan,
                        minHeight: 8,
                      ),
                    ),
                  ]),
                ],
              ),
            ),
    );
  }
}
