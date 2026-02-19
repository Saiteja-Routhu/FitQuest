import 'package:flutter/material.dart';
import '../../services/nutrition_service.dart';

class ScoutReportScreen extends StatefulWidget {
  final dynamic recruit;
  final Map<String, dynamic> userData; // Coach data
  final String password;

  const ScoutReportScreen({super.key, required this.recruit, required this.userData, required this.password});

  @override
  State<ScoutReportScreen> createState() => _ScoutReportScreenState();
}

class _ScoutReportScreenState extends State<ScoutReportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        title: Text(widget.recruit['username']),
        backgroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.cyan,
          unselectedLabelColor: Colors.white54,
          indicatorColor: Colors.cyan,
          tabs: const [
            Tab(text: "STATS"),
            Tab(text: "ASSESSMENT"),
            Tab(text: "NUTRITION"), // 👈 The new Schedule Tab
          ],
        )
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
           // 1. STATS (Placeholder for now)
           const Center(child: Text("Training Stats Coming Soon", style: TextStyle(color: Colors.white54))),

           // 2. ASSESSMENT (Placeholder)
           const Center(child: Text("Physical Assessment Coming Soon", style: TextStyle(color: Colors.white54))),

           // 3. NUTRITION SCHEDULE
           NutritionScheduleView(recruitId: widget.recruit['id'], userData: widget.userData, password: widget.password),
        ],
      ),
    );
  }
}

// 🟢 WEEKLY SCHEDULER WIDGET
class NutritionScheduleView extends StatefulWidget {
  final int recruitId;
  final Map<String, dynamic> userData;
  final String password;

  const NutritionScheduleView({super.key, required this.recruitId, required this.userData, required this.password});

  @override
  State<NutritionScheduleView> createState() => _NutritionScheduleViewState();
}

class _NutritionScheduleViewState extends State<NutritionScheduleView> {
  List<dynamic> _schedule = [];
  List<dynamic> _plans = [];
  final List<String> _days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];

  @override
  void initState() { super.initState(); _load(); }

  void _load() async {
    try {
      var s = await NutritionService.fetchSchedule(widget.userData['username'], widget.password, widget.recruitId);
      var p = await NutritionService.fetchMyPlans(widget.userData['username'], widget.password);
      setState(() { _schedule = s; _plans = p; });
    } catch (e) { print(e); }
  }

  void _assignDay(String day) {
    showModalBottomSheet(context: context, backgroundColor: Colors.grey[900], builder: (ctx) => ListView.builder(
      itemCount: _plans.length + 1, // +1 for "Rest Day" option
      itemBuilder: (c, i) {
        if (i == _plans.length) {
          return ListTile(
            title: const Text("Clear / Rest Day", style: TextStyle(color: Colors.red)),
            onTap: () async {
               await NutritionService.setScheduleDay(widget.userData['username'], widget.password, widget.recruitId, day, null);
               Navigator.pop(c); _load();
            },
          );
        }
        return ListTile(
          title: Text(_plans[i]['name'], style: const TextStyle(color: Colors.white)),
          shape: const Border(bottom: BorderSide(color: Colors.white12)),
          onTap: () async {
            await NutritionService.setScheduleDay(widget.userData['username'], widget.password, widget.recruitId, day, _plans[i]['id']);
            Navigator.pop(c);
            _load();
          },
        );
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _days.length,
      itemBuilder: (ctx, i) {
        String day = _days[i];
        var entry = _schedule.firstWhere((s) => s['day_of_week'] == day, orElse: () => null);
        String planName = entry != null && entry['diet_plan_details'] != null ? entry['diet_plan_details']['name'] : "No Plan Assigned";
        Color color = entry != null ? Colors.cyan : Colors.white24;

        return Card(
          color: Colors.white10,
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: Colors.black26, child: Text(day.substring(0, 3), style: TextStyle(color: color, fontSize: 12))),
            title: Text(planName, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.edit, color: Colors.white54),
            onTap: () => _assignDay(day),
          ),
        );
      },
    );
  }
}