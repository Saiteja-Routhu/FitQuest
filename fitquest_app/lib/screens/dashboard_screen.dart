import 'package:flutter/material.dart';
import 'dashboards/admin_dashboard.dart';
import 'dashboards/coach_dashboard.dart';
import 'dashboards/recruit_dashboard.dart';
import 'dashboards/super_coach_dashboard.dart';

class DashboardScreen extends StatelessWidget {
  final Map<String, dynamic> userData;
  final String role;
  final String password;

  const DashboardScreen({
    super.key,
    required this.userData,
    required this.role,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    if (role == 'HIGH_COUNCIL') {
      return AdminDashboard(userData: userData, password: password);
    } else if (role == 'SUPER_COACH') {
      return SuperCoachDashboard(userData: userData, password: password);
    } else if (role == 'GUILD_MASTER') {
      return CoachDashboard(userData: userData, password: password);
    } else {
      return RecruitDashboard(userData: userData, password: password);
    }
  }
}