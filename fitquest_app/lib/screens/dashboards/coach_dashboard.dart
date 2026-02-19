import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../auth_gate_screen.dart';
import 'forge_screen.dart';
import 'kitchen_screen.dart';

class CoachDashboard extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String password;

  const CoachDashboard({super.key, required this.userData, required this.password});

  @override
  State<CoachDashboard> createState() => _CoachDashboardState();
}

class _CoachDashboardState extends State<CoachDashboard> {
  void _logout() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AuthGateScreen()));
  }

  void _showRosterDialog() async {
    try {
      List<dynamic> recruits = await ApiService.fetchMyRoster(widget.userData['username'], widget.password);
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1a1a2e), // Dark Blue Theme
          title: const Text("ACTIVE ROSTER", style: TextStyle(color: Colors.cyanAccent, letterSpacing: 2)),
          content: SizedBox(
            width: double.maxFinite, height: 400,
            child: recruits.isEmpty
              ? const Center(child: Text("No recruits assigned.", style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  itemCount: recruits.length,
                  itemBuilder: (context, index) {
                    final recruit = recruits[index];
                    bool isNew = recruit['is_new_assignment'] ?? false;

                    return Card(
                      color: isNew ? Colors.cyan.withOpacity(0.1) : Colors.white10,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: isNew ? Colors.cyan : Colors.transparent),
                        borderRadius: BorderRadius.circular(10)
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isNew ? Colors.cyan : Colors.grey,
                          child: Icon(Icons.person, color: Colors.black),
                        ),
                        title: Text(recruit['username'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text("${recruit['goal']} • Active: 2d ago", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        trailing: isNew
                          ? const Chip(label: Text("NEW", style: TextStyle(fontSize: 10)), backgroundColor: Colors.orange)
                          : const Icon(Icons.arrow_forward_ios, color: Colors.white30, size: 16),
                        onTap: () {
                          Navigator.pop(ctx);
                          _openScoutReport(recruit);
                        },
                      ),
                    );
                  },
                ),
          ),
        ),
      );
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"))); }
  }

  void _openScoutReport(Map<String, dynamic> recruit) {
    // If new, mark as seen
    if (recruit['is_new_assignment'] == true) {
      ApiService.acknowledgeRecruit(widget.userData['username'], widget.password, recruit['id']);
    }

    Navigator.push(context, MaterialPageRoute(builder: (context) => ScoutReportScreen(recruit: recruit)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        title: const Text("COMMAND CENTER"),
        backgroundColor: Colors.black,
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: _logout)]
      ),
      body: GridView.count(
        crossAxisCount: 2, padding: const EdgeInsets.all(20), mainAxisSpacing: 15, crossAxisSpacing: 15,
        children: [
          _buildCard(Icons.group, "THE ROSTER", _showRosterDialog),
          // Inside build() -> GridView
          _buildCard(Icons.fitness_center, "THE FORGE", () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ForgeScreen(
                  userData: widget.userData,
                  password: widget.password
                )
              )
            );
          }),
          _buildCard(Icons.restaurant, "THE KITCHEN", () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => KitchenScreen(
                  userData: widget.userData,
                  password: widget.password
                 )
                )
              );
            }),
          _buildCard(Icons.chat, "COMMS", () {}),
        ],
      ),
    );
  }

  Widget _buildCard(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.cyan.withOpacity(0.3))
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Icon(icon, size: 40, color: Colors.cyan), const SizedBox(height: 10), Text(title, style: const TextStyle(color: Colors.white))],
        ),
      ),
    );
  }
}

// --- NEW FILE CONTENT: SCOUT REPORT SCREEN ---
// You can move this to a separate file later if you want: `lib/screens/scout_report_screen.dart`

class ScoutReportScreen extends StatelessWidget {
  final Map<String, dynamic> recruit;

  const ScoutReportScreen({super.key, required this.recruit});

  @override
  Widget build(BuildContext context) {
    final form = recruit['assessment'] ?? {};
    bool hasAssessment = recruit['assessment'] != null;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1a1a2e),
          title: Text("${recruit['username']}'s REPORT", style: const TextStyle(color: Colors.cyanAccent)),
          bottom: const TabBar(
            indicatorColor: Colors.cyanAccent,
            labelColor: Colors.cyanAccent,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: "OVERVIEW"),
              Tab(text: "ASSESSMENT"),
              Tab(text: "HISTORY"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: OVERVIEW (Quick Stats)
            _buildOverviewTab(recruit, form),

            // TAB 2: FULL ASSESSMENT (The PDF Data)
            hasAssessment
              ? _buildAssessmentTab(form)
              : const Center(child: Text("No Assessment Form Submitted", style: TextStyle(color: Colors.white54))),

            // TAB 3: HISTORY (Placeholder)
            const Center(child: Text("Workout History Log (Coming Soon)", style: TextStyle(color: Colors.white54))),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(Map<String, dynamic> user, Map<String, dynamic> form) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildHeader("CURRENT STATUS"),
        _buildStatCard("Level", "${user['level']}", Icons.star, Colors.amber),
        _buildStatCard("Goal", "${user['goal']}", Icons.flag, Colors.redAccent),
        _buildStatCard("Current Weight", "${user['weight'] ?? 'N/A'} kg", Icons.monitor_weight, Colors.blue),
        const SizedBox(height: 20),
        _buildHeader("QUICK ALERTS"),
        if (form['injuries'] != null && form['injuries'].toString().isNotEmpty)
          _buildAlertTile("INJURY REPORTED", form['injuries'], Colors.red),
        if (form['food_allergies'] != null && form['food_allergies'].toString().isNotEmpty)
          _buildAlertTile("ALLERGIES", form['food_allergies'], Colors.orange),
      ],
    );
  }

  Widget _buildAssessmentTab(Map<String, dynamic> form) {
    // We access the user's height/weight from the parent widget
    final userWeight = recruit['weight'] ?? "N/A";
    final userHeight = recruit['height'] ?? "N/A";

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildHeader("PHYSICAL PROFILE"),
        // ✅ NEW: Height & Weight added here
        _buildDetailRow("Height", "$userHeight cm"),
        _buildDetailRow("Weight", "$userWeight kg"),

        // ✅ NEW: Body Measurements added here
        _buildDetailRow("Waist", "${form['waist_circumference'] ?? '-'} inches"),
        _buildDetailRow("Chest", "${form['chest_size'] ?? '-'} inches"),
        _buildDetailRow("Bicep", "${form['bicep_size'] ?? '-'} inches"),
        _buildDetailRow("Thigh", "${form['thigh_size'] ?? '-'} inches"),

        const SizedBox(height: 10),
        _buildDetailRow("Injuries", form['injuries'] ?? "None"),
        _buildDetailRow("Medical Hist", form['medical_history'] ?? "None"),

        const SizedBox(height: 20),
        _buildHeader("NUTRITION & LIFESTYLE"),
        _buildDetailRow("Type", form['food_preference']),
        _buildDetailRow("Meals/Day", "${form['meals_per_day']}"),
        _buildDetailRow("Tea/Coffee", form['tea_coffee_cups']),
        _buildDetailRow("Alcohol", form['alcohol_frequency']),

        const SizedBox(height: 20),
        _buildHeader("TYPICAL DIET"),
        _buildDetailRow("Breakfast", form['typical_breakfast']),
        _buildDetailRow("Lunch", form['typical_lunch']),
        _buildDetailRow("Dinner", form['typical_dinner']),
        _buildDetailRow("Snacks", form['typical_snacks']),

        const SizedBox(height: 20),
        _buildHeader("EXERCISE BACKGROUND"),
        _buildDetailRow("Experience", form['exercise_experience']),
        _buildDetailRow("Preference", form['preferred_exercise']),
        _buildDetailRow("Availability", form['days_available']),
      ],
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: const TextStyle(color: Colors.cyan, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.white54))),
          Expanded(child: Text(value ?? "N/A", style: const TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      color: Colors.white10,
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        subtitle: Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildAlertTile(String title, String body, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border(left: BorderSide(color: color, width: 4))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(body, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}