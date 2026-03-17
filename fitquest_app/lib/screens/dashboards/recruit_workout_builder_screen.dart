import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../main.dart';
import '../../services/workout_service.dart';

// ══════════════════════════════════════════════════════════════════════════════
// RECRUIT WORKOUT BUILDER — Athletes without a coach can build their own plan
// ══════════════════════════════════════════════════════════════════════════════
class RecruitWorkoutBuilderScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String password;

  const RecruitWorkoutBuilderScreen({
    super.key,
    required this.userData,
    required this.password,
  });

  @override
  State<RecruitWorkoutBuilderScreen> createState() =>
      _RecruitWorkoutBuilderScreenState();
}

class _RecruitWorkoutBuilderScreenState
    extends State<RecruitWorkoutBuilderScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  List<dynamic> _allExercises = [];
  bool _loadingExercises = true;
  bool _saving = false;

  // day -> list of exercise entries
  final Map<String, List<Map<String, dynamic>>> _dayExercises = {
    'Monday': [],
    'Tuesday': [],
    'Wednesday': [],
    'Thursday': [],
    'Friday': [],
    'Saturday': [],
    'Sunday': [],
  };

  String _selectedDay = 'Monday';
  String _filterGroup = 'All';

  static const _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday'
  ];
  static const _dayAbbr = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _muscleGroups = [
    'All', 'Chest', 'Back', 'Legs', 'Shoulders',
    'Biceps', 'Triceps', 'Core', 'Cardio', 'Full Body'
  ];

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    try {
      final exs = await WorkoutService.fetchExercises(
          widget.userData['username'], widget.password);
      if (mounted) setState(() { _allExercises = exs; _loadingExercises = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingExercises = false);
    }
  }

  List<dynamic> get _filteredExercises {
    if (_filterGroup == 'All') return _allExercises;
    return _allExercises
        .where((e) => e['muscle_group'] == _filterGroup)
        .toList();
  }

  void _addExercise(Map<String, dynamic> exercise) {
    setState(() {
      _dayExercises[_selectedDay]!.add({
        'exercise_id': exercise['id'],
        'exercise_name': exercise['name'],
        'muscle_group': exercise['muscle_group'] ?? '',
        'sets': 3,
        'reps': '10-12',
        'rest_time': 60,
        'day_label': _selectedDay,
      });
    });
    Navigator.pop(context); // close picker sheet
  }

  void _removeExercise(int index) {
    setState(() => _dayExercises[_selectedDay]!.removeAt(index));
  }

  void _showExercisePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: FQColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(builder: (ctx, setSheetState) {
        final filtered = _filterGroup == 'All'
            ? _allExercises
            : _allExercises
                .where((e) => e['muscle_group'] == _filterGroup)
                .toList();
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (_, sc) => Column(children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: FQColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 12),
            Text('ADD EXERCISE — $_selectedDay'.toUpperCase(),
                style: GoogleFonts.rajdhani(
                    color: FQColors.cyan,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    fontSize: 15)),
            const SizedBox(height: 10),
            // Group filter chips
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: _muscleGroups.map((g) {
                  final sel = _filterGroup == g;
                  return GestureDetector(
                    onTap: () {
                      setSheetState(() => _filterGroup = g);
                      setState(() => _filterGroup = g);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel
                            ? FQColors.cyan.withOpacity(0.15)
                            : FQColors.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: sel
                                ? FQColors.cyan
                                : FQColors.border),
                      ),
                      child: Text(g,
                          style: TextStyle(
                              color: sel ? FQColors.cyan : FQColors.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loadingExercises
                  ? const Center(
                      child: CircularProgressIndicator(color: FQColors.cyan))
                  : ListView.builder(
                      controller: sc,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final ex = filtered[i];
                        return ListTile(
                          onTap: () => _addExercise(
                              Map<String, dynamic>.from(ex)),
                          leading: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: FQColors.cyan.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.fitness_center,
                                color: FQColors.cyan, size: 18),
                          ),
                          title: Text(ex['name']?.toString() ?? '',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13)),
                          subtitle: Text(
                              '${ex["muscle_group"]} · ${ex["difficulty"]}',
                              style: const TextStyle(
                                  color: FQColors.muted, fontSize: 11)),
                          trailing: const Icon(Icons.add_circle_outline,
                              color: FQColors.cyan, size: 22),
                        );
                      },
                    ),
            ),
          ]),
        );
      }),
    );
  }

  Future<void> _savePlan() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Plan name is required'),
          backgroundColor: FQColors.red));
      return;
    }

    final allExercises = <Map<String, dynamic>>[];
    int order = 1;
    for (final day in _days) {
      for (final ex in _dayExercises[day]!) {
        allExercises.add({
          'exercise_id': ex['exercise_id'],
          'sets': ex['sets'],
          'reps': ex['reps'],
          'rest_time': ex['rest_time'],
          'order': order++,
          'day_label': day,
        });
      }
    }

    setState(() => _saving = true);
    try {
      await WorkoutService.createSelfWorkoutPlan(
        widget.userData['username'],
        widget.password,
        {
          'name': _nameCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'day_names': {},
          'workout_exercises': allExercises,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Plan created!'),
            backgroundColor: FQColors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), backgroundColor: FQColors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentExercises = _dayExercises[_selectedDay]!;
    final totalExercises = _dayExercises.values
        .fold<int>(0, (sum, list) => sum + list.length);

    return Scaffold(
      backgroundColor: FQColors.bg,
      appBar: AppBar(
        backgroundColor: FQColors.surface,
        foregroundColor: Colors.white,
        title: Text('BUILD YOUR PLAN',
            style: GoogleFonts.rajdhani(
                fontWeight: FontWeight.w800, letterSpacing: 2, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: FQColors.border, height: 1),
        ),
        actions: [
          if (totalExercises > 0)
            TextButton(
              onPressed: _saving ? null : _savePlan,
              child: Text('SAVE',
                  style: GoogleFonts.rajdhani(
                      color: FQColors.cyan,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ),
        ],
      ),
      body: Column(children: [
        // Plan name + description
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(children: [
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Plan name (e.g. My Push Day Plan)',
                hintStyle: TextStyle(color: FQColors.muted),
                prefixIcon: Icon(Icons.edit_outlined,
                    color: FQColors.muted, size: 18),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Description (optional)',
                hintStyle: TextStyle(color: FQColors.muted, fontSize: 13),
                prefixIcon: Icon(Icons.notes_outlined,
                    color: FQColors.muted, size: 18),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        // Day tabs
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _days.length,
            itemBuilder: (_, i) {
              final day = _days[i];
              final sel = _selectedDay == day;
              final count = _dayExercises[day]!.length;
              return GestureDetector(
                onTap: () => setState(() => _selectedDay = day),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel
                        ? FQColors.cyan.withOpacity(0.12)
                        : FQColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: sel ? FQColors.cyan : FQColors.border),
                  ),
                  child: Row(children: [
                    Text(_dayAbbr[i],
                        style: TextStyle(
                            color: sel ? FQColors.cyan : FQColors.muted,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                    if (count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: FQColors.cyan,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('$count',
                            style: const TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ]),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Container(height: 1, color: FQColors.border),
        // Exercise list for selected day
        Expanded(
          child: currentExercises.isEmpty
              ? Center(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    const Icon(Icons.fitness_center_outlined,
                        color: FQColors.muted, size: 40),
                    const SizedBox(height: 10),
                    Text('No exercises for $_selectedDay',
                        style: const TextStyle(
                            color: FQColors.muted, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _showExercisePicker,
                      icon: const Icon(Icons.add, color: FQColors.cyan),
                      label: Text('Add Exercise',
                          style: GoogleFonts.rajdhani(
                              color: FQColors.cyan,
                              fontWeight: FontWeight.bold)),
                    ),
                  ]),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: currentExercises.length + 1,
                  itemBuilder: (_, i) {
                    if (i == currentExercises.length) {
                      return Center(
                        child: TextButton.icon(
                          onPressed: _showExercisePicker,
                          icon: const Icon(Icons.add, color: FQColors.cyan),
                          label: Text('Add Exercise',
                              style: GoogleFonts.rajdhani(
                                  color: FQColors.cyan,
                                  fontWeight: FontWeight.bold)),
                        ),
                      );
                    }
                    final ex = currentExercises[i];
                    return _exerciseCard(ex, i);
                  },
                ),
        ),
      ]),
      floatingActionButton: currentExercises.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _showExercisePicker,
              backgroundColor: FQColors.cyan,
              foregroundColor: Colors.black,
              icon: const Icon(Icons.add),
              label: Text('ADD',
                  style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold)),
            ),
    );
  }

  Widget _exerciseCard(Map<String, dynamic> ex, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: FQColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FQColors.border),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: FQColors.cyan.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.fitness_center,
              color: FQColors.cyan, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(ex['exercise_name']?.toString() ?? '',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
            const SizedBox(height: 4),
            Row(children: [
              _setRepsEditor(ex),
            ]),
          ]),
        ),
        IconButton(
          onPressed: () => _removeExercise(index),
          icon: const Icon(Icons.close, color: FQColors.muted, size: 18),
        ),
      ]),
    );
  }

  Widget _setRepsEditor(Map<String, dynamic> ex) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      _smallField(
        label: 'Sets',
        value: ex['sets'].toString(),
        onChanged: (v) {
          final n = int.tryParse(v);
          if (n != null) setState(() => ex['sets'] = n);
        },
      ),
      const SizedBox(width: 8),
      _smallField(
        label: 'Reps',
        value: ex['reps'].toString(),
        onChanged: (v) => setState(() => ex['reps'] = v),
        isText: true,
        width: 56,
      ),
      const SizedBox(width: 8),
      _smallField(
        label: 'Rest(s)',
        value: ex['rest_time'].toString(),
        onChanged: (v) {
          final n = int.tryParse(v);
          if (n != null) setState(() => ex['rest_time'] = n);
        },
        width: 52,
      ),
    ]);
  }

  Widget _smallField({
    required String label,
    required String value,
    required void Function(String) onChanged,
    bool isText = false,
    double width = 40,
  }) {
    return SizedBox(
      width: width,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(color: FQColors.muted, fontSize: 9)),
        const SizedBox(height: 2),
        TextFormField(
          initialValue: value,
          keyboardType: isText ? TextInputType.text : TextInputType.number,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          onChanged: onChanged,
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            filled: true,
            fillColor: FQColors.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: FQColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: FQColors.border),
            ),
          ),
        ),
      ]),
    );
  }
}
