import 'package:flutter/material.dart';
import '../auth_gate_screen.dart';

class RecruitDashboard extends StatelessWidget {
  final Map<String, dynamic> userData;

  const RecruitDashboard({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Recruit ${userData['username']}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AuthGateScreen())),
          )
        ],
      ),
      body: const Center(child: Text("Welcome to FitQuest! (Your Quests Go Here)")),
    );
  }
}