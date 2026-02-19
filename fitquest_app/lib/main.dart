import 'package:flutter/material.dart';
import 'screens/auth_gate_screen.dart';

void main() {
  runApp(const FitQuestApp());
}

class FitQuestApp extends StatelessWidget {
  const FitQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitQuest',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AuthGateScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}