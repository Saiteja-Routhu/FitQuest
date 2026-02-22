import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/auth_gate_screen.dart';

void main() {
  runApp(const FitQuestApp());
}

// ─── Global Design Tokens ───────────────────────────────────────────────────
class FQColors {
  static const Color bg       = Color(0xFF080C14);
  static const Color surface  = Color(0xFF0F1624);
  static const Color card     = Color(0xFF141D2E);
  static const Color border   = Color(0xFF1E2D40);
  static const Color cyan     = Color(0xFF00D4FF);
  static const Color gold     = Color(0xFFFFAA00);
  static const Color green    = Color(0xFF00C896);
  static const Color red      = Color(0xFFFF4757);
  static const Color purple   = Color(0xFF9B59B6);
  static const Color muted    = Color(0xFF5A6E8A);
}

// Goal colour helper — used across Forge, Kitchen, Coach screens
Color goalColor(String? goal) {
  final g = (goal ?? '').toLowerCase();
  if (g.contains('loss') || g.contains('cut'))            return const Color(0xFF00BFFF);
  if (g.contains('bulk') || g.contains('gain') || g.contains('muscle')) return const Color(0xFFFF8C00);
  if (g.contains('endurance') || g.contains('cardio'))    return const Color(0xFF00C896);
  if (g.contains('maintain') || g.contains('tone'))       return const Color(0xFF9B59B6);
  return FQColors.muted;
}

// Reusable goal badge widget
Widget goalBadge(String? goal) {
  final label = goal ?? 'N/A';
  final color = goalColor(label);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
  );
}

// ─── App ────────────────────────────────────────────────────────────────────
class FitQuestApp extends StatelessWidget {
  const FitQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitQuest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: FQColors.bg,
        colorScheme: const ColorScheme.dark(
          primary: FQColors.cyan,
          secondary: FQColors.gold,
          surface: FQColors.card,
          onPrimary: Colors.black,
          onSecondary: Colors.black,
        ),
        textTheme: GoogleFonts.rajdhaniTextTheme(ThemeData.dark().textTheme),
        appBarTheme: AppBarTheme(
          backgroundColor: FQColors.bg,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.rajdhani(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actionsIconTheme: const IconThemeData(color: FQColors.muted),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: FQColors.surface,
          labelStyle: const TextStyle(color: FQColors.muted),
          hintStyle: TextStyle(color: FQColors.muted.withOpacity(0.6)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: FQColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: FQColors.cyan, width: 1.5),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        cardTheme: CardThemeData(
          color: FQColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: FQColors.border),
          ),
          margin: EdgeInsets.zero,
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? FQColors.cyan : Colors.transparent),
          checkColor: WidgetStateProperty.all(Colors.black),
          side: const BorderSide(color: FQColors.muted),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: FQColors.cyan,
          foregroundColor: Colors.black,
        ),
        dividerTheme: const DividerThemeData(color: FQColors.border, space: 1),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: FQColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: FQColors.card,
          contentTextStyle: TextStyle(color: Colors.white),
        ),
      ),
      home: const AuthGateScreen(),
    );
  }
}
