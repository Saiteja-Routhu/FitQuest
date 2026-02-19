import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../auth_gate_screen.dart';

class AdminDashboard extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String password;

  const AdminDashboard({super.key, required this.userData, required this.password});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  void _logout() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AuthGateScreen()));
  }

  void _generateKeyDialog() async {
    try {
      String newKey = await ApiService.generateCoachKey(widget.userData['username'], widget.password);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text("New Access Key", style: TextStyle(color: Colors.white)),
          content: SelectableText(newKey, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.amber)),
        ),
      );
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"))); }
  }

  void _showPersonnelDialog() async {
    try {
      List<dynamic> users = await ApiService.fetchAllUsers(widget.userData['username'], widget.password);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1a1a2e),
          title: const Text("Personnel Roster", style: TextStyle(color: Colors.cyanAccent)),
          content: SizedBox(
            width: double.maxFinite, height: 400,
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (c, i) => ListTile(
                leading: Icon(Icons.person, color: users[i]['role'] == 'GUILD_MASTER' ? Colors.amber : Colors.white),
                title: Text(users[i]['username'], style: const TextStyle(color: Colors.white)),
                subtitle: Text(users[i]['role'], style: const TextStyle(color: Colors.white54)),
              ),
            ),
          ),
        ),
      );
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"))); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(title: const Text("HIGH COUNCIL"), backgroundColor: Colors.black, actions: [IconButton(icon: const Icon(Icons.logout), onPressed: _logout)]),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Overseer Status: ONLINE", style: TextStyle(color: Colors.greenAccent)),
            const SizedBox(height: 20),
            _buildAdminButton("Generate Coach Key", Icons.vpn_key, Colors.amber, _generateKeyDialog),
            _buildAdminButton("View Personnel", Icons.people, Colors.cyan, _showPersonnelDialog),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.black),
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}