import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../main.dart';
import '../../services/workout_service.dart';
import '../../services/api_service.dart';

// ══════════════════════════════════════════════════════════════════════════════
// 1.  FORGE SCREEN — My Training Plans
// ══════════════════════════════════════════════════════════════════════════════
class ForgeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String password;
  const ForgeScreen(
      {super.key, required this.userData, required this.password});

  @override
  State<ForgeScreen> createState() => _ForgeScreenState();
}

class _ForgeScreenState extends State<ForgeScreen> {
  List<dynamic> _plans    = [];
  bool          _loading  = true;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  void _loadPlans() async {
    try {
      final p = await WorkoutService.fetchMyPlans(
          widget.userData['username'], widget.password);
      setState(() { _plans = p; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _openBuilder() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => ForgeBuilderScreen(
              userData: widget.userData, password: widget.password)),
    );
    if (result == true) _loadPlans();
  }

  void _openEditor(Map<String, dynamic> plan) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => ForgeBuilderScreen(
              userData: widget.userData,
              password: widget.password,
              existingPlan: plan)),
    );
    if (result == true) _loadPlans();
  }

  void _deletePlan(Map<String, dynamic> plan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: FQColors.surface,
        title: const Text('Delete Plan',
            style: TextStyle(color: Colors.white)),
        content: Text('Delete "${plan['name']}"?',
            style: const TextStyle(color: FQColors.muted)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL',
                  style: TextStyle(color: FQColors.muted))),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: FQColors.red, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('DELETE')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await WorkoutService.deletePlan(
          widget.userData['username'], widget.password, plan['id']);
      _loadPlans();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: FQColors.red));
      }
    }
  }

  void _showAssignDialog(Map<String, dynamic> plan) async {
    try {
      final roster = await ApiService.fetchMyRoster(
          widget.userData['username'], widget.password);
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _AssignSheet(
          planName: plan['name'],
          planId:   plan['id'],
          athletes: roster,
          userData: widget.userData,
          password: widget.password,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: FQColors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FQColors.bg,
      appBar: AppBar(
        title: const Text('MY TRAINING PLANS'),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: _loadPlans)
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openBuilder,
        icon: const Icon(Icons.add, color: Colors.black),
        label: Text('NEW PLAN',
            style: GoogleFonts.rajdhani(
                color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: FQColors.cyan))
          : _plans.isEmpty
              ? _emptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: _plans.length,
                  itemBuilder: (_, i) => _planCard(_plans[i]),
                ),
    );
  }

  Widget _planCard(Map<String, dynamic> plan) {
    final exercises = plan['workout_exercises'] as List;
    final assigned  = (plan['assigned_count'] ?? 0) as int;

    // Collect days that have exercises
    final daysWithExercises = <String>{};
    for (final ex in exercises) {
      final day = ex['day_label']?.toString() ?? 'Any';
      if (day != 'Any') daysWithExercises.add(day);
    }
    const dayOrder = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    final sortedDays = dayOrder.where((d) => daysWithExercises.contains(d)).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: FQColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FQColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: FQColors.gold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.fitness_center, color: FQColors.gold, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(plan['name'],
                    style: GoogleFonts.rajdhani(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Row(children: [
                  _infoChip('${exercises.length} exercises', FQColors.cyan),
                  const SizedBox(width: 6),
                  _infoChip('$assigned assigned', FQColors.green),
                ]),
              ]),
            ),
            Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                  icon: const Icon(Icons.edit_outlined, color: FQColors.gold, size: 18),
                  onPressed: () => _openEditor(plan)),
              IconButton(
                  icon: const Icon(Icons.delete_outline, color: FQColors.muted, size: 18),
                  onPressed: () => _deletePlan(plan)),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: FQColors.gold,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  textStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                onPressed: () => _showAssignDialog(plan),
                child: const Text('ASSIGN'),
              ),
            ]),
          ]),
          if (sortedDays.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: sortedDays.map((d) {
                final focusName = (plan['day_names'] as Map<String, dynamic>?)?[d];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: FQColors.gold.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: FQColors.gold.withOpacity(0.25)),
                  ),
                  child: Text(
                    focusName != null
                        ? '${d.substring(0, 3)}: $focusName'
                        : d.substring(0, 3),
                    style: const TextStyle(color: FQColors.gold, fontSize: 10),
                  ),
                );
              }).toList(),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _infoChip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: TextStyle(color: color, fontSize: 10)),
      );

  Widget _emptyState() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.fitness_center,
              size: 56, color: FQColors.muted.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text('No training plans yet',
              style: GoogleFonts.rajdhani(
                  color: FQColors.muted, fontSize: 18)),
          const SizedBox(height: 6),
          const Text('Tap "NEW PLAN" to build your first program',
              style: TextStyle(color: FQColors.muted, fontSize: 12)),
        ]),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// 2.  BUILDER SCREEN — Create / edit plan with Mon-Sun day tabs
// ══════════════════════════════════════════════════════════════════════════════
class ForgeBuilderScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String password;
  final Map<String, dynamic>? existingPlan;

  const ForgeBuilderScreen(
      {super.key, required this.userData, required this.password,
       this.existingPlan});

  @override
  State<ForgeBuilderScreen> createState() => _ForgeBuilderScreenState();
}

class _ForgeBuilderScreenState extends State<ForgeBuilderScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();

  static const _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];
  static const _dayAbbr = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  final Map<String, List<Map<String, dynamic>>> _dayExercises = {
    'Monday': [], 'Tuesday': [], 'Wednesday': [],
    'Thursday': [], 'Friday': [], 'Saturday': [], 'Sunday': [],
  };

  // Day focus labels (e.g. "Back", "Chest & Triceps")
  final Map<String, TextEditingController> _dayNameCtrl = {
    for (final d in ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'])
      d: TextEditingController()
  };

  List<dynamic> _allEx    = [];
  List<dynamic> _filtered = [];
  String _muscleFilter    = 'All';
  String _searchQuery     = '';
  bool   _isSaving        = false;

  late TabController _tabController;

  static const _muscles = [
    'All', 'Chest', 'Back', 'Legs', 'Shoulders', 'Biceps', 'Triceps', 'Core', 'Cardio'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);

    // Pre-populate if editing
    if (widget.existingPlan != null) {
      final plan = widget.existingPlan!;
      _nameCtrl.text = plan['name'] ?? '';
      // Restore day focus names
      final savedDayNames = plan['day_names'] as Map<String, dynamic>? ?? {};
      for (final d in _days) {
        _dayNameCtrl[d]!.text = savedDayNames[d]?.toString() ?? '';
      }
      for (final ex in plan['workout_exercises'] as List) {
        final day = ex['day_label']?.toString() ?? 'Monday';
        final target = _dayExercises.containsKey(day) ? day : 'Monday';
        _dayExercises[target]!.add({
          'id':   ex['exercise']['id'],
          'name': ex['exercise']['name'],
          'sets': ex['sets'].toString(),
          'reps': ex['reps'].toString(),
          'rest': ex['rest_time'].toString(),
        });
      }
    }
    _loadLibrary();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    for (final c in _dayNameCtrl.values) c.dispose();
    super.dispose();
  }

  void _loadLibrary() async {
    try {
      final ex = await WorkoutService.fetchExercises(
          widget.userData['username'], widget.password);
      setState(() { _allEx = ex; _applyFilter(); });
    } catch (_) {}
  }

  void _applyFilter() {
    setState(() {
      _filtered = _allEx.where((ex) {
        final matchMuscle = _muscleFilter == 'All' ||
            ex['muscle_group'] == _muscleFilter;
        final matchSearch = _searchQuery.isEmpty ||
            ex['name'].toString().toLowerCase()
                .contains(_searchQuery.toLowerCase());
        return matchMuscle && matchSearch;
      }).toList();
    });
  }

  String get _currentDay => _days[_tabController.index];

  void _addExercise(dynamic ex) {
    final day = _currentDay;
    setState(() => _dayExercises[day]!.add({
      'id':   ex['id'],
      'name': ex['name'],
      'sets': '3',
      'reps': '10',
      'rest': '60',
    }));
    Navigator.pop(context);
  }

  void _savePlan() async {
    final allExercises = _dayExercises.entries
        .expand((e) => e.value.map((ex) => {...ex, 'day_label': e.key}))
        .toList();

    if (_nameCtrl.text.isEmpty || allExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Enter a name and add at least one exercise.')));
      return;
    }
    setState(() => _isSaving = true);

    // Build day_names map — only include days that have a label set
    final dayNames = <String, String>{};
    for (final d in _days) {
      final v = _dayNameCtrl[d]!.text.trim();
      if (v.isNotEmpty) dayNames[d] = v;
    }

    final planData = {
      'name': _nameCtrl.text,
      'description': 'Custom Plan',
      'day_names': dayNames,
      'workout_exercises': allExercises.asMap().entries.map((e) => {
        'exercise_id': e.value['id'],
        'sets':        int.tryParse(e.value['sets'].toString()) ?? 3,
        'reps':        e.value['reps'],
        'rest_time':   int.tryParse(e.value['rest'].toString()) ?? 60,
        'order':       e.key + 1,
        'day_label':   e.value['day_label'],
      }).toList(),
    };

    try {
      if (widget.existingPlan != null) {
        await WorkoutService.updatePlan(
            widget.userData['username'], widget.password,
            widget.existingPlan!['id'], planData);
      } else {
        await WorkoutService.createPlan(
            widget.userData['username'], widget.password, planData);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: FQColors.red));
      setState(() => _isSaving = false);
    }
  }

  void _showLibrary() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setModal) {
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
                Text('EXERCISE LIBRARY',
                    style: GoogleFonts.rajdhani(
                        color: FQColors.cyan,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2)),
                const SizedBox(width: 8),
                Text('→ $_currentDay',
                    style: GoogleFonts.rajdhani(
                        color: FQColors.gold, fontSize: 14)),
              ]),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                onChanged: (v) {
                  setModal(() => _searchQuery = v);
                  _applyFilter();
                },
                decoration: const InputDecoration(
                  hintText: 'Search exercises...',
                  prefixIcon: Icon(Icons.search, color: FQColors.muted, size: 18),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: _muscles.map((m) {
                  final sel = _muscleFilter == m;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(m,
                          style: TextStyle(
                              color: sel ? Colors.black : FQColors.muted,
                              fontSize: 12)),
                      selected: sel,
                      backgroundColor: FQColors.card,
                      selectedColor: FQColors.cyan,
                      showCheckmark: false,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: sel ? FQColors.cyan : FQColors.border),
                      ),
                      onSelected: (_) {
                        setModal(() => _muscleFilter = m);
                        _applyFilter();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final ex = _filtered[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: FQColors.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: FQColors.border),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: FQColors.gold.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.fitness_center,
                            color: FQColors.gold, size: 16),
                      ),
                      title: Text(ex['name'],
                          style: const TextStyle(color: Colors.white, fontSize: 14)),
                      subtitle: Text(ex['muscle_group'] ?? '',
                          style: const TextStyle(color: FQColors.muted, fontSize: 11)),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_circle,
                            color: FQColors.green, size: 28),
                        onPressed: () => _addExercise(ex),
                      ),
                    ),
                  );
                },
              ),
            ),
          ]),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FQColors.bg,
      appBar: AppBar(
        title: Text(widget.existingPlan != null ? 'EDIT PLAN' : 'NEW TRAINING PLAN'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: FQColors.gold,
          labelColor: FQColors.gold,
          unselectedLabelColor: FQColors.muted,
          labelStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: List.generate(7, (i) => Tab(text: _dayAbbr[i])),
          isScrollable: true,
          onTap: (_) => setState(() {}),
        ),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'PLAN NAME',
              labelStyle: TextStyle(color: FQColors.muted),
              prefixIcon: Icon(Icons.edit_note, color: FQColors.muted, size: 20),
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: List.generate(7, (dayIdx) {
              final day      = _days[dayIdx];
              final dayItems = _dayExercises[day]!;
              return Column(
                children: [
                  // Day focus label input
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                    child: TextField(
                      controller: _dayNameCtrl[day],
                      style: GoogleFonts.rajdhani(
                          color: FQColors.gold, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'e.g. Back, Chest & Triceps, Legs...',
                        hintStyle: const TextStyle(
                            color: FQColors.muted, fontSize: 13),
                        labelText: '$day Focus',
                        labelStyle: const TextStyle(
                            color: FQColors.muted, fontSize: 12),
                        prefixIcon: const Icon(Icons.label_outline,
                            color: FQColors.gold, size: 18),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: FQColors.border),
                  Expanded(
                    child: dayItems.isEmpty
                        ? Center(
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.add_box_outlined,
                                  size: 48, color: FQColors.muted.withOpacity(0.4)),
                              const SizedBox(height: 12),
                              Text('No exercises for $day',
                                  style: const TextStyle(color: FQColors.muted)),
                              const SizedBox(height: 6),
                              const Text('Tap "+ ADD EXERCISE" below',
                                  style: TextStyle(color: FQColors.muted, fontSize: 12)),
                            ]),
                          )
                        : ReorderableListView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      onReorder: (o, n) {
                        setState(() {
                          if (n > o) n -= 1;
                          final item = dayItems.removeAt(o);
                          dayItems.insert(n, item);
                        });
                      },
                      children: [
                        for (int idx = 0; idx < dayItems.length; idx++)
                          Container(
                            key: ValueKey('$day-$idx-${dayItems[idx]['id']}'),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: FQColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: FQColors.border),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                              leading: const Icon(Icons.drag_handle,
                                  color: FQColors.muted, size: 20),
                              title: Text(dayItems[idx]['name'],
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 14)),
                              subtitle: Row(children: [
                                _miniInput(day, idx, 'sets', 'Sets'),
                                const SizedBox(width: 16),
                                _miniInput(day, idx, 'reps', 'Reps'),
                                const SizedBox(width: 16),
                                _miniInput(day, idx, 'rest', 'Rest(s)'),
                              ]),
                              trailing: IconButton(
                                icon: const Icon(Icons.close,
                                    color: FQColors.red, size: 20),
                                onPressed: () =>
                                    setState(() => dayItems.removeAt(idx)),
                              ),
                            ),
                          ),
                      ],
                    ),  // closes ReorderableListView
                  ),    // closes Expanded
                ],
              );        // closes Column (return value)
            }),
          ),
        ),
        // Bottom action bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: FQColors.border))),
          child: Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showLibrary,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('ADD EXERCISE'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: FQColors.cyan,
                  side: const BorderSide(color: FQColors.cyan),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _savePlan,
                icon: const Icon(Icons.save, size: 18, color: Colors.black),
                label: Text(_isSaving ? 'SAVING...' : 'SAVE PLAN',
                    style: GoogleFonts.rajdhani(
                        color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FQColors.gold,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _miniInput(String day, int idx, String key, String label) {
    return SizedBox(
      width: 58,
      child: TextFormField(
        initialValue: _dayExercises[day]![idx][key].toString(),
        style: const TextStyle(color: Colors.white, fontSize: 13),
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: FQColors.muted, fontSize: 10),
          isDense: true,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: FQColors.cyan, width: 1)),
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (v) => _dayExercises[day]![idx][key] = v,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 3.  ASSIGN SHEET — Assign plan to athletes with search + details
// ══════════════════════════════════════════════════════════════════════════════
class _AssignSheet extends StatefulWidget {
  final String   planName;
  final int      planId;
  final List<dynamic> athletes;
  final Map<String, dynamic> userData;
  final String   password;

  const _AssignSheet({
    required this.planName,
    required this.planId,
    required this.athletes,
    required this.userData,
    required this.password,
  });

  @override
  State<_AssignSheet> createState() => _AssignSheetState();
}

class _AssignSheetState extends State<_AssignSheet> {
  final List<int> _selected = [];
  String _search = '';
  bool   _saving  = false;
  final _xpCtrl   = TextEditingController(text: '100');
  final _coinCtrl  = TextEditingController(text: '10');

  List<dynamic> get _filtered => widget.athletes.where((a) =>
      a['username'].toString().toLowerCase().contains(_search.toLowerCase())).toList();

  @override
  void dispose() {
    _xpCtrl.dispose();
    _coinCtrl.dispose();
    super.dispose();
  }

  void _assign() async {
    if (_selected.isEmpty) return;
    setState(() => _saving = true);
    try {
      await WorkoutService.assignPlan(
          widget.userData['username'], widget.password,
          widget.planId, _selected,
          xpReward: int.tryParse(_xpCtrl.text) ?? 100,
          coinReward: int.tryParse(_coinCtrl.text) ?? 10);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Assigned "${widget.planName}" to ${_selected.length} athlete(s)'),
        backgroundColor: FQColors.green,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: FQColors.red));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
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
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ASSIGN PLAN', style: GoogleFonts.rajdhani(
                color: FQColors.cyan, fontSize: 18,
                fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 2),
            Text(widget.planName,
                style: const TextStyle(color: FQColors.muted, fontSize: 13)),
          ]),
        ),
        const SizedBox(height: 16),
        // Search
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
        // List
        Expanded(
          child: _filtered.isEmpty
              ? const Center(
                  child: Text('No athletes found',
                      style: TextStyle(color: FQColors.muted)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) {
                    final a = _filtered[i] as Map<String, dynamic>;
                    final isSelected = _selected.contains(a['id']);
                    return _AssignAthleteTile(
                      athlete: a,
                      selected: isSelected,
                      onToggle: (val) {
                        setState(() {
                          if (val) _selected.add(a['id']);
                          else _selected.remove(a['id']);
                        });
                      },
                    );
                  },
                ),
        ),
        // XP / Coin reward fields
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('QUEST REWARDS (auto-created)',
                  style: GoogleFonts.rajdhani(
                      color: FQColors.gold, fontSize: 12,
                      fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _xpCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'XP REWARD',
                      labelStyle: const TextStyle(color: FQColors.gold, fontSize: 12),
                      prefixIcon: const Icon(Icons.star, color: FQColors.gold, size: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _coinCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'COIN REWARD',
                      labelStyle: const TextStyle(color: FQColors.gold, fontSize: 12),
                      prefixIcon: const Icon(Icons.monetization_on_outlined,
                          color: FQColors.gold, size: 16),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
            ],
          ),
        ),
        // Confirm button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: (_selected.isEmpty || _saving) ? null : _assign,
              style: ElevatedButton.styleFrom(
                backgroundColor: FQColors.gold,
                foregroundColor: Colors.black,
                disabledBackgroundColor: FQColors.border,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const CircularProgressIndicator(
                      color: Colors.black, strokeWidth: 2)
                  : Text(
                      _selected.isEmpty
                          ? 'SELECT ATHLETES'
                          : 'ASSIGN TO ${_selected.length} ATHLETE(S)',
                      style: GoogleFonts.rajdhani(
                          fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ),
      ]),
    );
  }
}

// Athlete tile with checkbox + goal badge + level
class _AssignAthleteTile extends StatelessWidget {
  final Map<String, dynamic> athlete;
  final bool selected;
  final ValueChanged<bool> onToggle;

  const _AssignAthleteTile(
      {required this.athlete, required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final goal   = athlete['goal']?.toString() ?? 'N/A';
    final level  = athlete['level'] ?? 1;
    final weight = athlete['weight'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: selected ? FQColors.gold.withOpacity(0.06) : FQColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: selected
                ? FQColors.gold.withOpacity(0.4)
                : FQColors.border),
      ),
      child: CheckboxListTile(
        value: selected,
        onChanged: (v) => onToggle(v ?? false),
        activeColor: FQColors.gold,
        checkColor: Colors.black,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(athlete['username'],
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: Row(children: [
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
        ]),
        secondary: CircleAvatar(
          backgroundColor:
              selected ? FQColors.gold.withOpacity(0.2) : FQColors.surface,
          child: Text(
            athlete['username'].toString().substring(0, 1).toUpperCase(),
            style: TextStyle(
                color: selected ? FQColors.gold : Colors.white,
                fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
