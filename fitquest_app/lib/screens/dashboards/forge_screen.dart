import 'package:flutter/material.dart';
import '../../services/workout_service.dart';
import '../../services/api_service.dart';

// ==========================================
// 1. THE MAIN FORGE SCREEN (List of Plans)
// ==========================================
class ForgeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String password;

  const ForgeScreen({super.key, required this.userData, required this.password});

  @override
  State<ForgeScreen> createState() => _ForgeScreenState();
}

class _ForgeScreenState extends State<ForgeScreen> {
  List<dynamic> _myPlans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  void _loadPlans() async {
    try {
      // With pagination disabled on backend, this now returns a simple List
      var plans = await WorkoutService.fetchMyPlans(widget.userData['username'], widget.password);
      setState(() { _myPlans = plans; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
      print("Error loading plans: $e");
    }
  }

  void _openBuilder() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ForgeBuilderScreen(userData: widget.userData, password: widget.password)),
    );
    if (result == true) _loadPlans(); // Refresh list if a plan was saved
  }

  void _showAssignDialog(Map<String, dynamic> plan) async {
    try {
      List<dynamic> recruits = await ApiService.fetchMyRoster(widget.userData['username'], widget.password);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AssignDialog(
          planName: plan['name'],
          planId: plan['id'],
          recruits: recruits,
          userData: widget.userData,
          password: widget.password,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error loading roster: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        title: const Text("MY PROTOCOLS"),
        backgroundColor: Colors.black,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadPlans)],
      ),
      // CREATE BUTTON
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openBuilder,
        backgroundColor: Colors.cyan,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text("CREATE NEW", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _myPlans.isEmpty
          ? const Center(child: Text("No protocols created yet.\nTap 'CREATE NEW' to start.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _myPlans.length,
              itemBuilder: (context, index) {
                final plan = _myPlans[index];
                return Card(
                  color: Colors.white10,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(plan['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text("${plan['workout_exercises'].length} Exercises", style: const TextStyle(color: Colors.cyan)),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      onPressed: () => _showAssignDialog(plan),
                      child: const Text("ASSIGN"),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ==========================================
// 2. THE BUILDER SCREEN (Create New Plan)
// ==========================================
class ForgeBuilderScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String password;

  const ForgeBuilderScreen({super.key, required this.userData, required this.password});

  @override
  State<ForgeBuilderScreen> createState() => _ForgeBuilderScreenState();
}

class _ForgeBuilderScreenState extends State<ForgeBuilderScreen> {
  final TextEditingController _planNameController = TextEditingController();
  List<Map<String, dynamic>> _selectedExercises = [];
  bool _isSaving = false;

  List<dynamic> _allExercises = [];
  List<dynamic> _filteredExercises = [];
  String _selectedMuscleFilter = "All";
  final List<String> _muscleGroups = ["All", "Chest", "Back", "Legs", "Shoulders", "Biceps", "Triceps", "Core", "Cardio"];

  @override
  void initState() {
    super.initState();
    _loadLibrary();
  }

  void _loadLibrary() async {
    try {
      var ex = await WorkoutService.fetchExercises(widget.userData['username'], widget.password);
      setState(() { _allExercises = ex; _filteredExercises = ex; });
    } catch (e) {
      print("Error loading library: $e");
    }
  }

  void _filterExercises(String muscle) {
    setState(() {
      _selectedMuscleFilter = muscle;
      _filteredExercises = muscle == "All"
          ? _allExercises
          : _allExercises.where((ex) => ex['muscle_group'] == muscle).toList();
    });
  }

  void _addExercise(dynamic ex) {
    setState(() {
      _selectedExercises.add({
        "id": ex['id'],
        "name": ex['name'],
        "sets": "3",
        "reps": "10",
        "rest": "60"
      });
    });
    Navigator.pop(context);
  }

  void _savePlan() async {
    if (_planNameController.text.isEmpty || _selectedExercises.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter a name and add at least one exercise.")));
        return;
    }
    setState(() => _isSaving = true);

    Map<String, dynamic> planData = {
      "name": _planNameController.text,
      "description": "Custom Plan",
      "workout_exercises": _selectedExercises.map((e) => {
        "exercise_id": e['id'],
        "sets": int.parse(e['sets'].toString()),
        "reps": e['reps'],
        "rest_time": int.parse(e['rest'].toString()),
        "order": _selectedExercises.indexOf(e) + 1
      }).toList()
    };

    try {
      await WorkoutService.createPlan(widget.userData['username'], widget.password, planData);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      setState(() => _isSaving = false);
    }
  }

  void _showArsenal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1a1a2e),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text("ARSENAL", style: TextStyle(color: Colors.cyanAccent, fontSize: 20, letterSpacing: 2)),
                const SizedBox(height: 15),
                // ✅ FIXED FILTER TABS (Visible Colors)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _muscleGroups.map((m) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(m),
                        labelStyle: TextStyle(color: _selectedMuscleFilter == m ? Colors.black : Colors.white),
                        backgroundColor: Colors.grey[800],
                        selectedColor: Colors.cyan,
                        selected: _selectedMuscleFilter == m,
                        onSelected: (bool selected) {
                          setModalState(() => _filterExercises(m));
                          setState(() => _filterExercises(m));
                        },
                      ),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: ListView.builder(
                    itemCount: _filteredExercises.length,
                    itemBuilder: (ctx, i) {
                      final ex = _filteredExercises[i];
                      return ListTile(
                        leading: const Icon(Icons.fitness_center, color: Colors.white54),
                        title: Text(ex['name'], style: const TextStyle(color: Colors.white)),
                        subtitle: Text(ex['description'] ?? "", style: const TextStyle(color: Colors.white30, fontSize: 10)),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.green),
                          onPressed: () => _addExercise(ex),
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(title: const Text("NEW PROTOCOL"), backgroundColor: Colors.black),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _planNameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "PROTOCOL NAME",
                labelStyle: TextStyle(color: Colors.cyanAccent),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
          ),
          Expanded(
            child: _selectedExercises.isEmpty
              ? const Center(child: Text("Add exercises to begin.", style: TextStyle(color: Colors.white54)))
              : ReorderableListView(
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final item = _selectedExercises.removeAt(oldIndex);
                      _selectedExercises.insert(newIndex, item);
                    });
                  },
                  children: [
                    for (int index = 0; index < _selectedExercises.length; index++)
                      Card(
                        key: ValueKey(_selectedExercises[index]),
                        color: Colors.white10,
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          title: Text(_selectedExercises[index]['name'], style: const TextStyle(color: Colors.white)),
                          subtitle: Row(
                            children: [
                              _buildMiniInput(index, "sets", "Sets"),
                              const SizedBox(width: 10),
                              _buildMiniInput(index, "reps", "Reps"),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () => setState(() => _selectedExercises.removeAt(index)),
                          ),
                        ),
                      )
                  ],
                ),
          ),
          // ✅ FIXED BUTTON LAYOUT (Side by Side, no overlap)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black26,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showArsenal,
                    icon: const Icon(Icons.list),
                    label: const Text("ADD"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _savePlan,
                    icon: const Icon(Icons.save),
                    label: Text(_isSaving ? "SAVING..." : "SAVE"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 15)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMiniInput(int index, String key, String label) {
    return SizedBox(
      width: 50,
      child: TextFormField(
        initialValue: _selectedExercises[index][key].toString(),
        style: const TextStyle(color: Colors.white),
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white54), isDense: true, border: InputBorder.none),
        onChanged: (val) => _selectedExercises[index][key] = val,
      ),
    );
  }
}

// ==========================================
// 3. ASSIGN DIALOG (Pop-up)
// ==========================================
class AssignDialog extends StatefulWidget {
  final String planName;
  final int planId;
  final List<dynamic> recruits;
  final Map<String, dynamic> userData;
  final String password;

  const AssignDialog({super.key, required this.planName, required this.planId, required this.recruits, required this.userData, required this.password});

  @override
  State<AssignDialog> createState() => _AssignDialogState();
}

class _AssignDialogState extends State<AssignDialog> {
  final List<int> _selectedRecruits = [];

  void _assign() async {
    try {
      await WorkoutService.assignPlan(widget.userData['username'], widget.password, widget.planId, _selectedRecruits);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Assigned ${widget.planName}!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1a1a2e),
      title: Text("Assign '${widget.planName}'", style: const TextStyle(color: Colors.cyanAccent)),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: widget.recruits.isEmpty
          ? const Center(child: Text("No recruits in roster.", style: TextStyle(color: Colors.white54)))
          : ListView.builder(
              itemCount: widget.recruits.length,
              itemBuilder: (ctx, i) {
                final r = widget.recruits[i];
                final isSelected = _selectedRecruits.contains(r['id']);
                return CheckboxListTile(
                  title: Text(r['username'], style: const TextStyle(color: Colors.white)),
                  value: isSelected,
                  activeColor: Colors.cyan,
                  checkColor: Colors.black,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) _selectedRecruits.add(r['id']);
                      else _selectedRecruits.remove(r['id']);
                    });
                  },
                );
              },
            ),
      ),
      actions: [
        TextButton(child: const Text("CANCEL"), onPressed: () => Navigator.pop(context)),
        ElevatedButton(
          onPressed: _selectedRecruits.isEmpty ? null : _assign,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text("CONFIRM"),
        )
      ],
    );
  }
}