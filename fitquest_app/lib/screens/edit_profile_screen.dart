import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String password;

  const EditProfileScreen({
    super.key,
    required this.userData,
    required this.password,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();

  String _goal = 'General Fitness';
  String _activityLevel = 'Sedentary';
  bool _isSaving = false;

  static const _goals = [
    'Weight Loss', 'Muscle Gain', 'Bulk', 'Cut', 'Maintain',
    'Endurance', 'General Fitness',
  ];
  static const _activityLevels = [
    'Sedentary', 'Lightly Active', 'Active', 'Very Active',
  ];

  @override
  void initState() {
    super.initState();
    final d = widget.userData;
    _weightCtrl.text = (d['weight'] ?? '').toString();
    _heightCtrl.text = (d['height'] ?? '').toString();

    final g = d['goal'] ?? 'General Fitness';
    _goal = _goals.contains(g) ? g : 'General Fitness';

    final a = d['activity_level'] ?? 'Sedentary';
    _activityLevel = _activityLevels.contains(a) ? a : 'Sedentary';
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  double? get _bmi {
    final w = double.tryParse(_weightCtrl.text);
    final h = double.tryParse(_heightCtrl.text);
    if (w == null || h == null || h <= 0) return null;
    final hm = h / 100;
    return w / (hm * hm);
  }

  String _bmiCategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Color _bmiColor(double bmi) {
    if (bmi < 18.5) return FQColors.cyan;
    if (bmi < 25) return FQColors.green;
    if (bmi < 30) return FQColors.gold;
    return FQColors.red;
  }

  void _save() async {
    setState(() => _isSaving = true);
    try {
      final updated = await ApiService.patchProfile(
        widget.userData['username'],
        widget.password,
        {
          'weight': double.tryParse(_weightCtrl.text) ?? widget.userData['weight'],
          'height': double.tryParse(_heightCtrl.text) ?? widget.userData['height'],
          'goal': _goal,
          'activity_level': _activityLevel,
        },
      );
      if (mounted) {
        Navigator.pop(context, updated);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: FQColors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.userData;
    final xp = (d['xp'] as num?)?.toInt() ?? 0;
    final level = (d['level'] as num?)?.toInt() ?? 1;
    final coins = (d['coins'] as num?)?.toInt() ?? 0;
    final xpInLevel = xp % 500;
    final xpProgress = xpInLevel / 500.0;
    final assessment = d['assessment'] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: FQColors.bg,
      appBar: AppBar(
        backgroundColor: FQColors.surface,
        foregroundColor: Colors.white,
        title: Text('EDIT PROFILE', style: GoogleFonts.rajdhani(
          fontWeight: FontWeight.w800, letterSpacing: 2, fontSize: 18,
        )),
        centerTitle: true,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: FQColors.border, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Hero section (read-only) ──────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: FQColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: FQColors.cyan.withOpacity(0.2)),
              ),
              child: Column(children: [
                // Avatar + username
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: FQColors.cyan.withOpacity(0.12),
                    border: Border.all(
                        color: FQColors.cyan.withOpacity(0.5), width: 2),
                  ),
                  child: const Icon(Icons.person,
                      color: FQColors.cyan, size: 36),
                ),
                const SizedBox(height: 8),
                Text(d['username'] ?? '',
                    style: GoogleFonts.rajdhani(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
                Text((d['role'] ?? '').toString().replaceAll('_', ' '),
                    style: GoogleFonts.rajdhani(
                        color: FQColors.muted, fontSize: 12, letterSpacing: 1)),
                const SizedBox(height: 16),

                // Level badge + coins
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: FQColors.gold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: FQColors.gold.withOpacity(0.3)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.star, color: FQColors.gold, size: 14),
                      const SizedBox(width: 4),
                      Text('LEVEL $level',
                          style: GoogleFonts.rajdhani(
                              color: FQColors.gold,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                    ]),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: FQColors.cyan.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: FQColors.cyan.withOpacity(0.3)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.monetization_on_outlined,
                          color: FQColors.cyan, size: 14),
                      const SizedBox(width: 4),
                      Text('$coins coins',
                          style: GoogleFonts.rajdhani(
                              color: FQColors.cyan,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 12),

                // XP progress bar
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                  Text('XP: $xp',
                      style: const TextStyle(
                          color: FQColors.muted, fontSize: 11)),
                  Text('${xpInLevel}/500 to Lv.${level + 1}',
                      style: const TextStyle(
                          color: FQColors.gold, fontSize: 11)),
                ]),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: xpProgress,
                    backgroundColor: FQColors.border,
                    color: FQColors.gold,
                    minHeight: 8,
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 24),

            // ── Assessment Summary ────────────────────────────────────────
            if (assessment != null) ...[
              _sectionLabel('ASSESSMENT SUMMARY'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: FQColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: FQColors.purple.withOpacity(0.2)),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  if (assessment['food_preference'] != null)
                    _assessmentRow(Icons.restaurant_menu,
                        'Food Preference', assessment['food_preference']),
                  if ((assessment['injuries'] as String? ?? '').isNotEmpty)
                    _assessmentRow(Icons.healing_outlined,
                        'Injuries', assessment['injuries']),
                  if (assessment['preferred_exercise'] != null)
                    _assessmentRow(Icons.fitness_center_outlined,
                        'Preferred Exercise', assessment['preferred_exercise']),
                  if (assessment['days_available'] != null)
                    _assessmentRow(Icons.calendar_month_outlined,
                        'Training Days', assessment['days_available']),
                ]),
              ),
              const SizedBox(height: 24),
            ],

            // ── Body Stats ────────────────────────────────────────────────
            _sectionLabel('BODY STATS'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _field(
                  _weightCtrl, 'Weight (kg)', Icons.monitor_weight_outlined)),
              const SizedBox(width: 12),
              Expanded(child: _field(
                  _heightCtrl, 'Height (cm)', Icons.height)),
            ]),

            // BMI display
            Builder(builder: (_) {
              final bmi = _bmi;
              if (bmi == null) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _bmiColor(bmi).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: _bmiColor(bmi).withOpacity(0.25)),
                ),
                child: Row(children: [
                  Icon(Icons.speed_outlined,
                      color: _bmiColor(bmi), size: 18),
                  const SizedBox(width: 10),
                  Text('BMI: ${bmi.toStringAsFixed(1)}',
                      style: GoogleFonts.rajdhani(
                          color: _bmiColor(bmi),
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  const SizedBox(width: 8),
                  Text(_bmiCategory(bmi),
                      style: TextStyle(
                          color: _bmiColor(bmi), fontSize: 12)),
                ]),
              );
            }),

            const SizedBox(height: 20),
            _sectionLabel('TRAINING PROFILE'),
            const SizedBox(height: 12),
            _dropdown(_goal, _goals, 'Goal', Icons.flag_outlined,
                (v) => setState(() => _goal = v!)),
            const SizedBox(height: 12),
            _dropdown(_activityLevel, _activityLevels, 'Activity Level',
                Icons.directions_run_outlined,
                (v) => setState(() => _activityLevel = v!)),
            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: _isSaving
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: FQColors.cyan))
                  : ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FQColors.cyan,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text('SAVE CHANGES',
                          style: GoogleFonts.rajdhani(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2)),
                    ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _assessmentRow(IconData icon, String label, dynamic value) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Icon(icon, color: FQColors.purple, size: 16),
          const SizedBox(width: 10),
          Text('$label: ',
              style: const TextStyle(color: FQColors.muted, fontSize: 12)),
          Expanded(
            child: Text(value?.toString() ?? '',
                style: const TextStyle(
                    color: Colors.white, fontSize: 12),
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      );

  Widget _sectionLabel(String label) {
    return Text(label,
        style: GoogleFonts.rajdhani(
            color: FQColors.muted,
            fontSize: 11,
            letterSpacing: 2,
            fontWeight: FontWeight.w600));
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white),
      onChanged: (_) => setState(() {}), // trigger BMI recalc
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: FQColors.muted),
        prefixIcon: Icon(icon, color: FQColors.muted, size: 18),
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: FQColors.cyan),
        ),
      ),
    );
  }

  Widget _dropdown(String value, List<String> items, String label,
      IconData icon, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: FQColors.card,
      style: const TextStyle(color: Colors.white),
      iconEnabledColor: FQColors.muted,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: FQColors.muted),
        prefixIcon: Icon(icon, color: FQColors.muted, size: 18),
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: FQColors.cyan),
        ),
      ),
      items: items
          .map((g) => DropdownMenuItem(
                value: g,
                child: Text(g,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14)),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}
