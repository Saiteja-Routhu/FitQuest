import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../main.dart';
import '../../services/api_service.dart';

class TDEEScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String username;
  final String password;

  const TDEEScreen({
    super.key,
    required this.userData,
    required this.username,
    required this.password,
  });

  @override
  State<TDEEScreen> createState() => _TDEEScreenState();
}

class _TDEEScreenState extends State<TDEEScreen> {
  late TextEditingController _weightCtrl;
  late TextEditingController _heightCtrl;
  late TextEditingController _ageCtrl;
  String _gender = 'male';
  String _activityLevel = 'Sedentary';
  bool _saving = false;

  static const _activityLevels = ['Sedentary', 'Lightly Active', 'Active', 'Very Active'];
  static const _activityMultipliers = {
    'Sedentary': 1.2,
    'Lightly Active': 1.375,
    'Active': 1.55,
    'Very Active': 1.725,
  };

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(
        text: widget.userData['weight']?.toString() ?? '');
    _heightCtrl = TextEditingController(
        text: widget.userData['height']?.toString() ?? '');
    _ageCtrl = TextEditingController(
        text: widget.userData['age']?.toString() ?? '');
    _gender = widget.userData['gender'] ?? 'male';
    _activityLevel = widget.userData['activity_level'] ?? 'Sedentary';
    if (!_activityLevels.contains(_activityLevel)) _activityLevel = 'Sedentary';
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  double? get _bmr {
    final weight = double.tryParse(_weightCtrl.text);
    final height = double.tryParse(_heightCtrl.text);
    final age = int.tryParse(_ageCtrl.text);
    if (weight == null || height == null || age == null) return null;
    if (_gender == 'male') {
      return 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
    } else {
      return 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
    }
  }

  double? get _tdee {
    final bmr = _bmr;
    if (bmr == null) return null;
    return bmr * (_activityMultipliers[_activityLevel] ?? 1.2);
  }

  Future<void> _saveToProfile() async {
    final weight = double.tryParse(_weightCtrl.text);
    final height = double.tryParse(_heightCtrl.text);
    final age = int.tryParse(_ageCtrl.text);
    setState(() => _saving = true);
    try {
      await ApiService.patchProfile(
        widget.username,
        widget.password,
        {
          if (weight != null) 'weight': weight,
          if (height != null) 'height': height,
          if (age != null) 'age': age,
          'gender': _gender,
          'activity_level': _activityLevel,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile updated!'),
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
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bmr = _bmr;
    final tdee = _tdee;

    return Scaffold(
      backgroundColor: FQColors.bg,
      appBar: AppBar(
        backgroundColor: FQColors.surface,
        foregroundColor: Colors.white,
        title: Text('TDEE CALCULATOR',
            style: GoogleFonts.rajdhani(
                fontWeight: FontWeight.w800, letterSpacing: 2, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: FQColors.border, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── INPUTS ──────────────────────────────────────────────────────
          _sectionLabel('BODY STATS'),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: _inputField(
                controller: _weightCtrl,
                label: 'Weight (kg)',
                icon: Icons.monitor_weight_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _inputField(
                controller: _heightCtrl,
                label: 'Height (cm)',
                icon: Icons.height,
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: _inputField(
                controller: _ageCtrl,
                label: 'Age (years)',
                icon: Icons.cake_outlined,
                isInt: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _genderToggle()),
          ]),
          const SizedBox(height: 20),
          _sectionLabel('ACTIVITY LEVEL'),
          const SizedBox(height: 12),
          ..._activityLevels.map((level) => _activityTile(level)),
          const SizedBox(height: 24),

          // ── RESULTS ─────────────────────────────────────────────────────
          if (bmr != null && tdee != null) ...[
            _sectionLabel('RESULTS'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _statCard('BMR', '${bmr.round()} kcal', FQColors.cyan, 'Basal Metabolic Rate')),
              const SizedBox(width: 12),
              Expanded(child: _statCard('TDEE', '${tdee.round()} kcal', FQColors.gold, 'Total Daily Energy')),
            ]),
            const SizedBox(height: 20),
            _sectionLabel('CALORIE TARGETS'),
            const SizedBox(height: 12),
            _goalCard('CUT', tdee - 500, FQColors.red, 'Fat loss deficit'),
            const SizedBox(height: 10),
            _goalCard('MAINTAIN', tdee, FQColors.green, 'Body recomposition'),
            const SizedBox(height: 10),
            _goalCard('BULK', tdee + 300, FQColors.gold, 'Muscle building surplus'),
            const SizedBox(height: 28),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: FQColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: FQColors.border),
              ),
              child: Column(children: [
                Icon(Icons.calculate_outlined, color: FQColors.muted, size: 40),
                const SizedBox(height: 12),
                Text('Fill in all fields to see your TDEE',
                    style: GoogleFonts.rajdhani(
                        color: FQColors.muted, fontSize: 14, letterSpacing: 0.5)),
              ]),
            ),
            const SizedBox(height: 28),
          ],

          // ── SAVE BUTTON ──────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _saveToProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: FQColors.cyan,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                textStyle: GoogleFonts.rajdhani(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.black, strokeWidth: 2))
                  : const Text('SAVE TO PROFILE'),
            ),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: GoogleFonts.rajdhani(
          color: FQColors.muted,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 2));

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isInt = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isInt
          ? TextInputType.number
          : const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: FQColors.muted, fontSize: 12),
        prefixIcon: Icon(icon, color: FQColors.muted, size: 18),
        filled: true,
        fillColor: FQColors.surface,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }

  Widget _genderToggle() {
    return Container(
      decoration: BoxDecoration(
        color: FQColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: FQColors.border),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(children: [
        Expanded(child: _genderBtn('male', Icons.male, 'Male')),
        Expanded(child: _genderBtn('female', Icons.female, 'Female')),
      ]),
    );
  }

  Widget _genderBtn(String value, IconData icon, String label) {
    final selected = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? FQColors.cyan.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: selected ? FQColors.cyan : FQColors.muted, size: 18),
          Text(label,
              style: TextStyle(
                  color: selected ? FQColors.cyan : FQColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  Widget _activityTile(String level) {
    final selected = _activityLevel == level;
    return GestureDetector(
      onTap: () => setState(() => _activityLevel = level),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? FQColors.gold.withOpacity(0.08) : FQColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? FQColors.gold.withOpacity(0.5) : FQColors.border),
        ),
        child: Row(children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: selected ? FQColors.gold : FQColors.muted,
            size: 18,
          ),
          const SizedBox(width: 12),
          Text(level,
              style: TextStyle(
                  color: selected ? Colors.white : FQColors.muted,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14)),
        ]),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FQColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: GoogleFonts.rajdhani(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value,
            style: GoogleFonts.rajdhani(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22)),
        Text(subtitle,
            style: const TextStyle(color: FQColors.muted, fontSize: 10)),
      ]),
    );
  }

  Widget _goalCard(String label, double kcal, Color color, String subtitle) {
    final protein = (kcal * 0.30 / 4).round();
    final carbs = (kcal * 0.40 / 4).round();
    final fat = (kcal * 0.30 / 9).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FQColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(children: [
        Container(
          width: 4,
          height: 56,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(label,
                  style: GoogleFonts.rajdhani(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1)),
              const SizedBox(width: 8),
              Text(subtitle,
                  style: const TextStyle(color: FQColors.muted, fontSize: 11)),
            ]),
            const SizedBox(height: 4),
            Text('${kcal.round()} kcal / day',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          _macroChip('P', '${protein}g', FQColors.cyan),
          const SizedBox(height: 2),
          _macroChip('C', '${carbs}g', FQColors.gold),
          const SizedBox(height: 2),
          _macroChip('F', '${fat}g', FQColors.purple),
        ]),
      ]),
    );
  }

  Widget _macroChip(String label, String value, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text('$label ', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 10)),
    ]);
  }
}
