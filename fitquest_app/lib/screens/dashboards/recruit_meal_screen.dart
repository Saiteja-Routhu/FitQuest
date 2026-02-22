import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../main.dart';
import '../../services/nutrition_service.dart';

const _weekDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _dayAbbr  = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

// ══════════════════════════════════════════════════════════════════════════════
// RECRUIT MEAL SCREEN — Weekly schedule view with day strip
// ══════════════════════════════════════════════════════════════════════════════
class RecruitMealScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String password;

  const RecruitMealScreen(
      {super.key, required this.userData, required this.password});

  @override
  State<RecruitMealScreen> createState() => _RecruitMealScreenState();
}

class _RecruitMealScreenState extends State<RecruitMealScreen> {
  List<dynamic> _plans = [];
  List<dynamic> _schedule = [];
  bool _loading = true;

  // Today's day index (0=Mon…6=Sun), using weekday 1=Mon…7=Sun
  final int _todayIdx = DateTime.now().weekday - 1;
  late int _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _todayIdx;
    _load();
  }

  void _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        NutritionService.fetchAssignedDietPlans(
            widget.userData['username'], widget.password),
        NutritionService.fetchMySchedule(
            widget.userData['username'], widget.password),
      ]);
      if (mounted) {
        setState(() {
          _plans    = results[0];
          _schedule = results[1];
          _loading  = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Returns the diet plan for the currently selected day, or null.
  Map<String, dynamic>? _planForDay(int dayIdx) {
    final dayName = _weekDays[dayIdx];
    try {
      final entry = _schedule.firstWhere(
        (s) => s['day_of_week'] == dayName,
        orElse: () => null,
      );
      if (entry == null) return null;
      final planId = entry['diet_plan'];
      return _plans.firstWhere((p) => p['id'] == planId, orElse: () => null)
          as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSchedule = _schedule.isNotEmpty;

    return Scaffold(
      backgroundColor: FQColors.bg,
      appBar: AppBar(
        backgroundColor: FQColors.surface,
        foregroundColor: Colors.white,
        title: Text('MY MEALS', style: GoogleFonts.rajdhani(
            fontWeight: FontWeight.w800, letterSpacing: 2, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: FQColors.border, height: 1),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: FQColors.green))
          : Column(children: [
              // Day pill strip (always shown)
              _dayStrip(),
              const Divider(height: 1, color: FQColors.border),
              Expanded(
                child: hasSchedule
                    ? _scheduleView()
                    : _allPlansView(),
              ),
            ]),
    );
  }

  Widget _dayStrip() {
    return Container(
      color: FQColors.surface,
      height: 58,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: 7,
        itemBuilder: (_, i) {
          final isToday    = i == _todayIdx;
          final isSelected = i == _selectedDay;
          final hasEntry   = _schedule.any((s) => s['day_of_week'] == _weekDays[i]);

          return GestureDetector(
            onTap: () => setState(() => _selectedDay = i),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? FQColors.cyan.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? FQColors.cyan
                      : isToday
                          ? FQColors.cyan.withOpacity(0.4)
                          : FQColors.border,
                ),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  _dayAbbr[i].toUpperCase(),
                  style: GoogleFonts.rajdhani(
                    color: isSelected ? FQColors.cyan : FQColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                if (hasEntry)
                  Container(
                    width: 4, height: 4,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? FQColors.cyan : FQColors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _scheduleView() {
    final plan = _planForDay(_selectedDay);
    if (plan == null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.calendar_today_outlined,
              size: 48, color: FQColors.muted),
          const SizedBox(height: 12),
          Text('No plan scheduled for ${_dayAbbr[_selectedDay]}',
              style: GoogleFonts.rajdhani(
                  color: FQColors.muted, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Ask your coach to assign a plan for this day.',
              style: TextStyle(color: FQColors.muted, fontSize: 12)),
        ]),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: _planCard(plan),
    );
  }

  Widget _allPlansView() {
    if (_plans.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.restaurant_outlined,
              size: 56, color: FQColors.muted.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text('No meal plans assigned yet',
              style: GoogleFonts.rajdhani(color: FQColors.muted, fontSize: 16)),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: _plans.length,
      itemBuilder: (_, i) => _planCard(_plans[i] as Map<String, dynamic>),
    );
  }

  Widget _planCard(Map<String, dynamic> plan) {
    final kcal    = (plan['total_calories'] ?? 0).round();
    final protein = (plan['total_protein']  ?? 0).round();
    final water   = (plan['water_target_liters'] ?? 3.0);

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => RecruitDietDetailScreen(
                plan: plan,
                userData: widget.userData,
                password: widget.password,
              ))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: FQColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: FQColors.border),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: FQColors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.restaurant_outlined,
                color: FQColors.green, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(plan['name'] ?? 'Diet Plan',
                  style: GoogleFonts.rajdhani(
                      color: Colors.white, fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const SizedBox(height: 6),
              Wrap(spacing: 6, children: [
                _chip('$kcal kcal', FQColors.gold),
                _chip('${protein}g protein', FQColors.green),
                _chip('${water}L water', FQColors.cyan),
              ]),
            ]),
          ),
          const Icon(Icons.chevron_right, color: FQColors.muted, size: 20),
        ]),
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 11)),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// RECRUIT DIET DETAIL — Macros header + meals list + supplements + completion
// ══════════════════════════════════════════════════════════════════════════════
class RecruitDietDetailScreen extends StatefulWidget {
  final Map<String, dynamic> plan;
  final Map<String, dynamic> userData;
  final String password;

  const RecruitDietDetailScreen({
    super.key,
    required this.plan,
    required this.userData,
    required this.password,
  });

  @override
  State<RecruitDietDetailScreen> createState() => _RecruitDietDetailScreenState();
}

class _RecruitDietDetailScreenState extends State<RecruitDietDetailScreen> {
  // meal_name → completion map {id, photo_url}
  Map<String, Map<String, dynamic>> _completions = {};
  bool _loadingCompletions = true;

  String get _username => widget.userData['username'] ?? '';

  @override
  void initState() {
    super.initState();
    _loadCompletions();
  }

  Future<void> _loadCompletions() async {
    try {
      final today = _todayString();
      final list = await NutritionService.fetchMealCompletions(
          _username, widget.password, today);
      final map = <String, Map<String, dynamic>>{};
      for (final c in list) {
        map[c['meal_name'] as String] = Map<String, dynamic>.from(c);
      }
      if (mounted) setState(() { _completions = map; _loadingCompletions = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingCompletions = false);
    }
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _undoCompletion(String mealName) async {
    final comp = _completions[mealName];
    if (comp == null) return;
    try {
      await NutritionService.deleteMealCompletion(
          _username, widget.password, comp['id'] as int);
      setState(() => _completions.remove(mealName));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Completion removed'), backgroundColor: FQColors.muted),
        );
      }
    } catch (_) {}
  }

  Future<void> _showCompletionSheet(String mealName, int? planId) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MealCompletionSheet(
        mealName: mealName,
        dietPlanId: planId,
        username: _username,
        password: widget.password,
        onCompleted: (comp) {
          setState(() => _completions[mealName] = comp);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$mealName logged! +XP'),
              backgroundColor: FQColors.green,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meals       = widget.plan['meals'] as List? ?? [];
    final supplements = widget.plan['supplements'] as List? ?? [];
    final kcal        = (widget.plan['total_calories'] ?? 0).round();
    final protein     = (widget.plan['total_protein'] ?? 0).round();
    final carbs       = (widget.plan['total_carbs'] ?? 0).round();
    final fats        = (widget.plan['total_fats'] ?? 0).round();
    final water       = widget.plan['water_target_liters'] ?? 3.0;
    final planId      = widget.plan['id'] as int?;

    return Scaffold(
      backgroundColor: FQColors.bg,
      appBar: AppBar(
        backgroundColor: FQColors.surface,
        foregroundColor: Colors.white,
        title: Text(widget.plan['name'] ?? 'Diet Plan',
            style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold)),
      ),
      body: _loadingCompletions
          ? const Center(child: CircularProgressIndicator(color: FQColors.green))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _macroCard(kcal, protein, carbs, fats, water),
                const SizedBox(height: 16),
                ...meals.map((m) => _mealSection(
                      m as Map<String, dynamic>,
                      planId,
                    )),
                if (supplements.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _supplementsSection(supplements),
                ],
              ],
            ),
    );
  }

  Widget _macroCard(int kcal, int protein, int carbs, int fats, dynamic water) {
    return Container(
      decoration: BoxDecoration(
        color: FQColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FQColors.green.withOpacity(0.25)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _macroCell('$kcal', 'kcal', FQColors.gold),
          _macroCell('${protein}g', 'protein', FQColors.green),
          _macroCell('${carbs}g', 'carbs', FQColors.cyan),
          _macroCell('${fats}g', 'fats', FQColors.purple),
        ]),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.water_drop_outlined, color: FQColors.cyan, size: 14),
          const SizedBox(width: 6),
          Text('${water}L water target',
              style: const TextStyle(color: FQColors.muted, fontSize: 12)),
        ]),
      ]),
    );
  }

  Widget _macroCell(String value, String label, Color color) => Column(
        children: [
          Text(value,
              style: GoogleFonts.rajdhani(
                  color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(color: FQColors.muted, fontSize: 10)),
        ],
      );

  Widget _mealSection(Map<String, dynamic> meal, int? planId) {
    final items    = meal['items'] as List? ?? [];
    final mealName = meal['name']?.toString() ?? '';
    final comp     = _completions[mealName];
    final isCompleted = comp != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: FQColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? FQColors.green.withOpacity(0.4)
              : FQColors.border,
        ),
      ),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: FQColors.border))),
          child: Row(children: [
            const Icon(Icons.restaurant_outlined, color: FQColors.green, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(mealName,
                  style: GoogleFonts.rajdhani(
                      color: FQColors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.5)),
            ),
            if (isCompleted)
              const Icon(Icons.check_circle, color: FQColors.green, size: 18),
          ]),
        ),
        // Food items
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(14),
            child: Text('No items',
                style: TextStyle(color: FQColors.muted, fontSize: 12)),
          )
        else
          ...items.map((item) => _foodItemRow(item as Map<String, dynamic>)),
        // Completion row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: FQColors.border))),
          child: isCompleted
              ? _completedRow(mealName, comp)
              : _completeButton(mealName, planId),
        ),
      ]),
    );
  }

  Widget _completeButton(String mealName, int? planId) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showCompletionSheet(mealName, planId),
        icon: const Text('📸', style: TextStyle(fontSize: 14)),
        label: Text('COMPLETE MEAL',
            style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, fontSize: 13)),
        style: OutlinedButton.styleFrom(
          foregroundColor: FQColors.cyan,
          side: const BorderSide(color: FQColors.cyan),
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Widget _completedRow(String mealName, Map<String, dynamic> comp) {
    final photoUrl = comp['photo_url'] as String?;

    return Row(children: [
      if (photoUrl != null)
        Container(
          width: 40, height: 40,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: FQColors.green.withOpacity(0.5)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(photoUrl, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image_outlined, color: FQColors.muted, size: 20)),
          ),
        ),
      const Icon(Icons.check_circle, color: FQColors.green, size: 16),
      const SizedBox(width: 6),
      Expanded(
        child: Text('Completed!',
            style: GoogleFonts.rajdhani(
                color: FQColors.green, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
      GestureDetector(
        onTap: () => _undoCompletion(mealName),
        child: const Text('UNDO',
            style: TextStyle(color: FQColors.muted, fontSize: 11)),
      ),
    ]);
  }

  Widget _foodItemRow(Map<String, dynamic> item) {
    final food    = item['food_details'] as Map<String, dynamic>? ?? {};
    final name    = food['name']?.toString() ?? '';
    final qty     = (item['quantity'] ?? 1.0) as num;
    final measure = food['measurement_type']?.toString() ?? 'per_100g';
    final unit    = food['unit_name']?.toString() ?? 'unit';
    final kcal    = ((food['calories'] ?? 0) as num) * qty;
    final prot    = ((food['protein'] ?? 0) as num) * qty;

    final qtyLabel = measure == 'per_unit'
        ? '${qty.toStringAsFixed(0)} ${unit}(s) of $name'
        : '${qty.toStringAsFixed(0)}g $name';

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Row(children: [
        Expanded(
          child: Text(qtyLabel,
              style: const TextStyle(color: Colors.white, fontSize: 13)),
        ),
        Text(
            '${kcal.toStringAsFixed(0)} kcal  •  ${prot.toStringAsFixed(0)}g prot',
            style: const TextStyle(color: FQColors.muted, fontSize: 11)),
      ]),
    );
  }

  Widget _supplementsSection(List<dynamic> supplements) {
    return Container(
      decoration: BoxDecoration(
        color: FQColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FQColors.border),
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: FQColors.border))),
          child: Row(children: [
            const Icon(Icons.medication_outlined,
                color: FQColors.purple, size: 16),
            const SizedBox(width: 8),
            Text('SUPPLEMENTS',
                style: GoogleFonts.rajdhani(
                    color: FQColors.purple,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.5)),
          ]),
        ),
        ...supplements.map((s) => Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              child: Row(children: [
                Expanded(
                  child: Text(s['name']?.toString() ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 13)),
                ),
                Text(s['dosage']?.toString() ?? '',
                    style: const TextStyle(color: FQColors.muted, fontSize: 12)),
              ]),
            )),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MEAL COMPLETION SHEET
// ══════════════════════════════════════════════════════════════════════════════
class _MealCompletionSheet extends StatefulWidget {
  final String mealName;
  final int? dietPlanId;
  final String username;
  final String password;
  final void Function(Map<String, dynamic>) onCompleted;

  const _MealCompletionSheet({
    required this.mealName,
    required this.dietPlanId,
    required this.username,
    required this.password,
    required this.onCompleted,
  });

  @override
  State<_MealCompletionSheet> createState() => _MealCompletionSheetState();
}

class _MealCompletionSheetState extends State<_MealCompletionSheet> {
  File? _photo;
  bool _submitting = false;

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
        source: source, imageQuality: 75, maxWidth: 1024);
    if (picked != null && mounted) {
      setState(() => _photo = File(picked.path));
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final result = await NutritionService.completeMeal(
        widget.username,
        widget.password,
        widget.mealName,
        dietPlanId: widget.dietPlanId,
        photo: _photo,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onCompleted(result);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: FQColors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: FQColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
              color: FQColors.border, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 16),
        Text(widget.mealName.toUpperCase(),
            style: GoogleFonts.rajdhani(
                color: FQColors.cyan,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 2)),
        const SizedBox(height: 4),
        const Text('Take a photo to log this meal',
            style: TextStyle(color: FQColors.muted, fontSize: 12)),
        const SizedBox(height: 20),
        // Photo preview / placeholder
        GestureDetector(
          onTap: () => _pickImage(ImageSource.camera),
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: FQColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: _photo != null
                      ? FQColors.green.withOpacity(0.5)
                      : FQColors.border,
                  width: _photo != null ? 2 : 1),
            ),
            child: _photo != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_photo!, fit: BoxFit.cover),
                  )
                : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.camera_alt_outlined,
                        color: FQColors.muted, size: 48),
                    const SizedBox(height: 10),
                    const Text('Tap to take a photo',
                        style: TextStyle(color: FQColors.muted, fontSize: 13)),
                  ]),
          ),
        ),
        const SizedBox(height: 12),
        // Camera / Gallery buttons
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt, size: 16),
              label: const Text('Camera'),
              style: OutlinedButton.styleFrom(
                foregroundColor: FQColors.cyan,
                side: const BorderSide(color: FQColors.border),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined, size: 16),
              label: const Text('Gallery'),
              style: OutlinedButton.styleFrom(
                foregroundColor: FQColors.cyan,
                side: const BorderSide(color: FQColors.border),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        // Submit
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: FQColors.green,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.black))
                : Text('SUBMIT',
                    style: GoogleFonts.rajdhani(
                        fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ]),
    );
  }
}
