import 'package:flutter/material.dart';
import '../../services/nutrition_service.dart';
import '../../services/api_service.dart';
import 'scout_report_screen.dart'; // We will create this next!

// ==========================================
// 1. MAIN KITCHEN DASHBOARD
// ==========================================
class KitchenScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String password;

  const KitchenScreen({super.key, required this.userData, required this.password});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  List<dynamic> _myPlans = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _loadPlans(); }

  void _loadPlans() async {
    try {
      var plans = await NutritionService.fetchMyPlans(widget.userData['username'], widget.password);
      setState(() { _myPlans = plans; _isLoading = false; });
    } catch (e) { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        title: const Text("THE KITCHEN"), backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2, color: Colors.orange),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PantryManagerScreen(userData: widget.userData, password: widget.password))),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.push(context, MaterialPageRoute(builder: (context) => DietBuilderScreen(userData: widget.userData, password: widget.password)));
          if (res == true) _loadPlans();
        },
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("NEW MEAL PLAN", style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
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
                  subtitle: Text("${plan['total_calories']} kcal • ${plan['total_protein']}g Protein", style: const TextStyle(color: Colors.greenAccent)),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => DietPlanDetailScreen(plan: plan, userData: widget.userData, password: widget.password)));
                    _loadPlans();
                  },
                ),
              );
            },
          ),
    );
  }
}

// ==========================================
// 2. DIET PLAN DETAIL SCREEN (With Editing)
// ==========================================
class DietPlanDetailScreen extends StatefulWidget {
  final Map<String, dynamic> plan;
  final Map<String, dynamic> userData;
  final String password;

  const DietPlanDetailScreen({super.key, required this.plan, required this.userData, required this.password});

  @override
  State<DietPlanDetailScreen> createState() => _DietPlanDetailScreenState();
}

class _DietPlanDetailScreenState extends State<DietPlanDetailScreen> {
  late Map<String, dynamic> _plan;

  @override
  void initState() { super.initState(); _plan = widget.plan; }

  Future<void> _refreshPlan() async {
    var plans = await NutritionService.fetchMyPlans(widget.userData['username'], widget.password);
    var updated = plans.firstWhere((p) => p['id'] == _plan['id']);
    setState(() => _plan = updated);
  }

  void _editMeal(Map<String, dynamic> meal) async {
    List<Map<String, dynamic>> currentItems = [];
    for (var item in meal['items']) {
      currentItems.add({
        "food_id": item['food_id'] ?? item['food_details']['id'],
        "name": item['food_details']['name'],
        "quantity": item['quantity'],
        "display_grams": item['quantity'] * 100
      });
    }

    await showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => EditMealSheet(
        mealName: meal['name'], initialItems: currentItems, userData: widget.userData, password: widget.password,
        onSave: (newItems) async {
          await NutritionService.updateMeal(widget.userData['username'], widget.password, meal['id'], newItems);
          _refreshPlan();
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _assignPlan() async {
    try {
      List<dynamic> recruits = await ApiService.fetchMyRoster(widget.userData['username'], widget.password);
      showDialog(context: context, builder: (ctx) => AssignDietDialog(plan: _plan, recruits: recruits, userData: widget.userData, password: widget.password));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final meals = _plan['meals'] as List;
    final recruits = _plan['assigned_recruits'] as List;

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(title: Text(_plan['name'].toUpperCase()), backgroundColor: Colors.black, actions: [
        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async {
           await NutritionService.deletePlan(widget.userData['username'], widget.password, _plan['id']);
           Navigator.pop(context);
        })
      ]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // MACROS
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _macroCol("Calories", "${_plan['total_calories']}"),
                  _macroCol("Protein", "${_plan['total_protein']}g", Colors.green),
                  _macroCol("Carbs", "${_plan['total_carbs']}g", Colors.blue),
                  _macroCol("Fats", "${_plan['total_fats']}g", Colors.orange),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ASSIGNED RECRUITS
            const Text("ASSIGNED RECRUITS", style: TextStyle(color: Colors.cyanAccent, fontSize: 12, letterSpacing: 1.5)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: recruits.map((r) => ActionChip(
                backgroundColor: Colors.blueGrey[800],
                label: Text(r['username'], style: const TextStyle(color: Colors.white)),
                avatar: const Icon(Icons.person, size: 16, color: Colors.cyan),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ScoutReportScreen(recruit: r, userData: widget.userData, password: widget.password))),
              )).toList(),
            ),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _assignPlan, style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text("Assign to Recruit")),

            const Divider(color: Colors.white24, height: 40),

            // MEALS
            const Text("MEAL BREAKDOWN (Tap to Edit)", style: TextStyle(color: Colors.cyanAccent, fontSize: 12, letterSpacing: 1.5)),
            const SizedBox(height: 10),
            ...meals.map((meal) {
              final items = meal['items'] as List;
              return GestureDetector(
                onTap: () => _editMeal(meal),
                child: Card(
                  color: Colors.white.withOpacity(0.05),
                  shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.white12), borderRadius: BorderRadius.circular(8)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(meal['name'], style: const TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold)),
                          const Icon(Icons.edit, size: 14, color: Colors.white24)
                        ]),
                        const SizedBox(height: 8),
                        if (items.isEmpty) const Text("Empty meal", style: TextStyle(color: Colors.white24, fontStyle: FontStyle.italic)),
                        ...items.map((item) {
                          double grams = item['quantity'] * 100;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Text(item['food_details']['name'], style: const TextStyle(color: Colors.white)),
                                Text("${grams.toStringAsFixed(0)}g", style: const TextStyle(color: Colors.white70)),
                            ]),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _macroCol(String label, String value, [Color color = Colors.white]) {
    return Column(children: [Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10))]);
  }
}

// ==========================================
// 3. EDIT MEAL SHEET (New)
// ==========================================
class EditMealSheet extends StatefulWidget {
  final String mealName;
  final List<Map<String, dynamic>> initialItems;
  final Map<String, dynamic> userData;
  final String password;
  final Function(List<Map<String, dynamic>>) onSave;

  const EditMealSheet({super.key, required this.mealName, required this.initialItems, required this.userData, required this.password, required this.onSave});

  @override
  State<EditMealSheet> createState() => _EditMealSheetState();
}

class _EditMealSheetState extends State<EditMealSheet> {
  late List<Map<String, dynamic>> _items;
  List<dynamic> _pantry = [];

  @override
  void initState() { super.initState(); _items = List.from(widget.initialItems); _loadPantry(); }

  void _loadPantry() async {
    try {
      var p = await NutritionService.fetchPantry(widget.userData['username'], widget.password);
      setState(() => _pantry = p);
    } catch (e) {}
  }

  void _addItem() {
    showModalBottomSheet(context: context, backgroundColor: Colors.grey[900], builder: (ctx) => ListView.builder(
      itemCount: _pantry.length,
      itemBuilder: (c, i) => ListTile(
        title: Text(_pantry[i]['name'], style: const TextStyle(color: Colors.white)),
        shape: const Border(bottom: BorderSide(color: Colors.white12)), // ✅ Border for pantry list
        onTap: () {
          Navigator.pop(c);
          setState(() {
            _items.add({"food_id": _pantry[i]['id'], "name": _pantry[i]['name'], "quantity": 1.0, "display_grams": 100.0});
          });
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(color: const Color(0xFF1a1a2e), borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text("Editing ${widget.mealName}", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (ctx, i) {
                final item = _items[i];
                return Card(
                  color: Colors.white10,
                  shape: RoundedRectangleBorder(side: BorderSide(color: Colors.cyan.withOpacity(0.3)), borderRadius: BorderRadius.circular(8)),
                  child: ListTile(
                    title: Text(item['name'], style: const TextStyle(color: Colors.white)),
                    subtitle: Text("${item['display_grams'].toStringAsFixed(0)}g", style: const TextStyle(color: Colors.cyan)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.remove_circle, color: Colors.white54), onPressed: () {
                          setState(() {
                            if (item['display_grams'] > 50) {
                              item['display_grams'] -= 50;
                              item['quantity'] = item['display_grams'] / 100;
                            }
                          });
                        }),
                        IconButton(icon: const Icon(Icons.add_circle, color: Colors.white54), onPressed: () {
                          setState(() {
                            item['display_grams'] += 50;
                            item['quantity'] = item['display_grams'] / 100;
                          });
                        }),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _items.removeAt(i))),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          ElevatedButton.icon(onPressed: _addItem, icon: const Icon(Icons.add), label: const Text("Add Food from Pantry"), style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey)),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => widget.onSave(_items), style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text("SAVE CHANGES"))),
        ],
      ),
    );
  }
}

// ==========================================
// 4. BUILDER & PANTRY & ASSIGN (Standard)
// ==========================================
class DietBuilderScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String password;
  const DietBuilderScreen({super.key, required this.userData, required this.password});

  @override
  State<DietBuilderScreen> createState() => _DietBuilderScreenState();
}

class _DietBuilderScreenState extends State<DietBuilderScreen> {
  final _planNameCtrl = TextEditingController();
  final _waterCtrl = TextEditingController(text: "3.0");
  bool _isSaving = false;
  List<Map<String, dynamic>> _meals = [{"name": "Breakfast", "items": []}, {"name": "Lunch", "items": []}, {"name": "Snack", "items": []}, {"name": "Dinner", "items": []}];
  List<dynamic> _pantry = [];

  @override
  void initState() { super.initState(); _loadPantry(); }
  void _loadPantry() async {
    try {
      var items = await NutritionService.fetchPantry(widget.userData['username'], widget.password);
      setState(() => _pantry = items);
    } catch (e) {}
  }

  void _showQuantityDialog(int mealIndex, dynamic food) {
    final qtyCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: Text(food['name']),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text("Enter weight in grams:", style: TextStyle(color: Colors.white54)),
            TextField(controller: qtyCtrl, keyboardType: TextInputType.number, autofocus: true, style: const TextStyle(color: Colors.white, fontSize: 24), decoration: const InputDecoration(suffixText: "g")),
        ]),
        actions: [ElevatedButton(onPressed: () {
              if (qtyCtrl.text.isEmpty) return;
              double grams = double.parse(qtyCtrl.text);
              double multiplier = grams / 100.0;
              setState(() {
                (_meals[mealIndex]['items'] as List).add({
                  "food_id": food['id'], "name": food['name'], "quantity": multiplier, "display_grams": grams,
                  "calories": food['calories'] * multiplier, "protein": food['protein'] * multiplier
                });
              });
              Navigator.pop(ctx);
            }, style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text("Add"))]
    ));
  }

  void _savePlan() async {
    if (_planNameCtrl.text.isEmpty || _isSaving) return;
    setState(() => _isSaving = true);
    List<Map<String, dynamic>> apiMeals = [];
    int order = 1;
    for (var meal in _meals) {
      if ((meal['items'] as List).isNotEmpty) {
        apiMeals.add({"name": meal['name'], "order": order++, "items": (meal['items'] as List).map((item) => {"food_id": item['food_id'], "quantity": item['quantity']}).toList()});
      }
    }
    Map<String, dynamic> planData = {"name": _planNameCtrl.text, "water_target": double.parse(_waterCtrl.text), "meals": apiMeals};
    try {
      await NutritionService.createDietPlan(widget.userData['username'], widget.password, planData);
      if(mounted) Navigator.pop(context, true);
    } catch (e) { setState(() => _isSaving = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(title: const Text("MEAL BUILDER"), backgroundColor: Colors.black),
      body: Column(children: [
          Padding(padding: const EdgeInsets.all(8.0), child: TextField(controller: _planNameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "PLAN NAME", filled: true, fillColor: Colors.white10))),
          Expanded(child: ListView.builder(itemCount: _meals.length, itemBuilder: (ctx, i) {
                final meal = _meals[i];
                return Card(color: Colors.white10, margin: const EdgeInsets.all(8), child: Column(children: [
                      ListTile(title: Text(meal['name'], style: const TextStyle(color: Colors.cyan)), trailing: IconButton(icon: const Icon(Icons.add_circle, color: Colors.green), onPressed: () {
                             showModalBottomSheet(context: context, backgroundColor: Colors.grey[900], builder: (c) => ListView.builder(itemCount: _pantry.length, itemBuilder: (cc, ii) => ListTile(title: Text(_pantry[ii]['name'], style: const TextStyle(color: Colors.white)), shape: const Border(bottom: BorderSide(color: Colors.white12)), onTap: () { Navigator.pop(c); _showQuantityDialog(i, _pantry[ii]); })));
                          })),
                      ...(meal['items'] as List).map((item) => ListTile(dense: true, title: Text(item['name'], style: const TextStyle(color: Colors.white)), subtitle: Text("${item['display_grams'].toStringAsFixed(0)}g", style: const TextStyle(color: Colors.white70)), trailing: Text("${item['calories'].toStringAsFixed(0)} kcal", style: const TextStyle(color: Colors.orange)))).toList()
                ]));
          })),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _savePlan, style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text("SAVE PLAN")))
      ]),
    );
  }
}

class PantryManagerScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String password;
  const PantryManagerScreen({super.key, required this.userData, required this.password});
  @override
  State<PantryManagerScreen> createState() => _PantryManagerScreenState();
}

class _PantryManagerScreenState extends State<PantryManagerScreen> {
  List<dynamic> _pantry = [];
  bool _isAdding = false;
  final _nameCtrl = TextEditingController();
  final _calCtrl = TextEditingController();
  final _protCtrl = TextEditingController();
  final _carbCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _loadPantry(); }
  void _loadPantry() async { try { var p = await NutritionService.fetchPantry(widget.userData['username'], widget.password); setState(() => _pantry = p); } catch (e) {} }
  void _deleteItem(int id) async { await NutritionService.deleteFoodItem(widget.userData['username'], widget.password, id); _loadPantry(); }

  void _showAddDialog() {
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(backgroundColor: Colors.grey[900], title: const Text("New Food (100g)", style: TextStyle(color: Colors.white)), content: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: _nameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Name")),
                Row(children: [Expanded(child: TextField(controller: _calCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Kcal"))), SizedBox(width: 5), Expanded(child: TextField(controller: _protCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Prot")))]),
                Row(children: [Expanded(child: TextField(controller: _carbCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Carb"))), SizedBox(width: 5), Expanded(child: TextField(controller: _fatCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Fat")))]),
          ]), actions: [
              TextButton(child: const Text("Cancel"), onPressed: () => Navigator.pop(context)),
              ElevatedButton(onPressed: _isAdding ? null : () async {
                  setDialogState(() => _isAdding = true);
                  await NutritionService.addFoodItem(widget.userData['username'], widget.password, {
                    "name": _nameCtrl.text, "calories": double.parse(_calCtrl.text), "protein": double.parse(_protCtrl.text), "carbs": double.parse(_carbCtrl.text), "fats": double.parse(_fatCtrl.text), "serving_unit": "100g"
                  });
                  _nameCtrl.clear(); _calCtrl.clear(); _protCtrl.clear(); _carbCtrl.clear(); _fatCtrl.clear();
                  if(mounted) { Navigator.pop(context); _loadPantry(); }
                }, style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), child: Text(_isAdding ? "Adding..." : "Add"))
          ]);
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: const Color(0xFF1a1a2e), appBar: AppBar(title: const Text("MY PANTRY"), backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white), titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20)), floatingActionButton: FloatingActionButton(onPressed: _showAddDialog, backgroundColor: Colors.orange, child: const Icon(Icons.add, color: Colors.white)), body: ListView.builder(itemCount: _pantry.length, itemBuilder: (ctx, i) {
          final item = _pantry[i];
          return Card(color: Colors.white10, shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.white12), borderRadius: BorderRadius.circular(8)), margin: const EdgeInsets.all(5), child: ListTile(title: Text(item['name'], style: const TextStyle(color: Colors.white)), subtitle: Text("${item['calories']} kcal | P:${item['protein']}", style: const TextStyle(color: Colors.white70)), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteItem(item['id']))));
    }));
  }
}

class AssignDietDialog extends StatefulWidget {
  final Map<String, dynamic> plan;
  final List<dynamic> recruits;
  final Map<String, dynamic> userData;
  final String password;
  const AssignDietDialog({super.key, required this.plan, required this.recruits, required this.userData, required this.password});
  @override
  State<AssignDietDialog> createState() => _AssignDietDialogState();
}
class _AssignDietDialogState extends State<AssignDietDialog> {
  final List<int> _selected = [];
  void _confirm() async {
    await NutritionService.assignDietPlan(widget.userData['username'], widget.password, widget.plan['id'], _selected);
    if(mounted) Navigator.pop(context);
  }
  @override
  Widget build(BuildContext context) {
    return AlertDialog(backgroundColor: Colors.grey[900], title: Text("Assign ${widget.plan['name']}", style: const TextStyle(color: Colors.white)), content: SizedBox(width: double.maxFinite, height: 300, child: ListView.builder(itemCount: widget.recruits.length, itemBuilder: (ctx, i) {
        final r = widget.recruits[i];
        return CheckboxListTile(title: Text(r['username'], style: const TextStyle(color: Colors.white)), value: _selected.contains(r['id']), onChanged: (val) => setState(() => val! ? _selected.add(r['id']) : _selected.remove(r['id'])), checkColor: Colors.black, activeColor: Colors.green);
    })), actions: [ElevatedButton(onPressed: _confirm, style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text("Assign"))]);
  }
}