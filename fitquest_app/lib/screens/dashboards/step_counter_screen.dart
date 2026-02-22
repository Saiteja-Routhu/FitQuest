import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../main.dart';
import '../../services/analytics_service.dart';

class StepCounterScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String password;

  const StepCounterScreen(
      {super.key, required this.userData, required this.password});

  @override
  State<StepCounterScreen> createState() => _StepCounterScreenState();
}

class _StepCounterScreenState extends State<StepCounterScreen> {
  // _backendSteps: steps stored in backend for today (loaded on init)
  // _pedometerBase: raw pedometer count at the moment we start listening (device-boot count)
  // _displaySteps: _backendSteps + (rawCount - _pedometerBase)
  int _backendSteps = 0;
  int _pedometerBase = -1; // -1 = not yet set
  int _rawCount = 0;
  int _goal = 8000;
  bool _loading = true;
  bool _permissionDenied = false;
  StreamSubscription<StepCount>? _stepSub;
  StreamSubscription<PedestrianStatus>? _statusSub;
  String _pedestrianStatus = 'stopped';
  int _lastSyncedDisplaySteps = 0;
  Timer? _heartbeatTimer;

  String get _username => widget.userData['username'] ?? '';

  int get _displaySteps {
    if (_pedometerBase < 0) return _backendSteps;
    final delta = (_rawCount - _pedometerBase).clamp(0, 999999);
    return _backendSteps + delta;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await AnalyticsService.fetchTodayActivity(
          _username, widget.password);
      setState(() {
        _backendSteps = data['steps'] ?? 0;
        _goal = data['step_goal'] ?? 8000;
        _lastSyncedDisplaySteps = _backendSteps;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
    await _requestPermissionAndInit();
  }

  Future<void> _requestPermissionAndInit() async {
    final permStatus = await Permission.activityRecognition.request();
    if (permStatus.isGranted) {
      _initPedometer();
      _startHeartbeat();
    } else if (permStatus.isPermanentlyDenied) {
      setState(() => _permissionDenied = true);
    } else {
      setState(() => _permissionDenied = true);
    }
  }

  void _initPedometer() {
    try {
      _stepSub = Pedometer.stepCountStream.listen(
        (event) {
          setState(() {
            if (_pedometerBase < 0) {
              // First event: anchor the base to today's backend value
              _pedometerBase = event.steps;
            }
            _rawCount = event.steps;
          });
          if (_displaySteps - _lastSyncedDisplaySteps >= 50) {
            _syncSteps();
          }
        },
        onError: (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Step counter error: $e'),
                backgroundColor: FQColors.red));
          }
        },
      );
      _statusSub = Pedometer.pedestrianStatusStream.listen(
        (event) => setState(() => _pedestrianStatus = event.status),
        onError: (_) {},
      );
    } catch (_) {}
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      final isWalking = _pedestrianStatus == 'walking';
      AnalyticsService.sendHeartbeat(
        _username,
        widget.password,
        isWalking ? 'walking' : 'idle',
        _displaySteps,
      );
    });
  }

  Future<void> _syncSteps() async {
    final toSync = _displaySteps;
    _lastSyncedDisplaySteps = toSync;
    try {
      await AnalyticsService.updateTodayActivity(
          _username, widget.password, steps: toSync);
    } catch (_) {}
  }

  @override
  void dispose() {
    _stepSub?.cancel();
    _statusSub?.cancel();
    _heartbeatTimer?.cancel();
    if (_displaySteps != _lastSyncedDisplaySteps) _syncSteps();
    super.dispose();
  }

  Future<void> _setGoalDialog() async {
    final ctrl = TextEditingController(text: '$_goal');
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: FQColors.surface,
        title: Text('Set Step Goal',
            style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 18)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
              hintText: 'steps',
              hintStyle: TextStyle(color: FQColors.muted)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL',
                  style: TextStyle(color: FQColors.muted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: FQColors.green,
                foregroundColor: Colors.black),
            onPressed: () async {
              final v = int.tryParse(ctrl.text);
              if (v != null && v > 0) {
                setState(() => _goal = v);
                await AnalyticsService.updateTodayActivity(
                    _username, widget.password, stepGoal: v);
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_permissionDenied) {
      return Scaffold(
        backgroundColor: FQColors.bg,
        appBar: AppBar(
          backgroundColor: FQColors.surface,
          foregroundColor: Colors.white,
          title: Text('STEP COUNTER',
              style: GoogleFonts.rajdhani(
                  fontWeight: FontWeight.bold, letterSpacing: 2)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.directions_walk_outlined,
                  color: FQColors.muted, size: 56),
              const SizedBox(height: 20),
              Text('Activity Permission Required',
                  style: GoogleFonts.rajdhani(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              const Text(
                'FitQuest needs Activity Recognition permission to count your steps.',
                style: TextStyle(color: FQColors.muted, fontSize: 13, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => openAppSettings(),
                icon: const Icon(Icons.settings),
                label: Text('OPEN SETTINGS',
                    style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FQColors.green,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                ),
              ),
            ]),
          ),
        ),
      );
    }

    final progress =
        _goal > 0 ? (_displaySteps / _goal).clamp(0.0, 1.0) : 0.0;
    final km = (_displaySteps * 0.0008).toStringAsFixed(2);
    final kcal = (_displaySteps * 0.04).toStringAsFixed(0);
    final isWalking = _pedestrianStatus == 'walking';

    return Scaffold(
      backgroundColor: FQColors.bg,
      appBar: AppBar(
        backgroundColor: FQColors.surface,
        foregroundColor: Colors.white,
        title: Text('STEP COUNTER',
            style: GoogleFonts.rajdhani(
                fontWeight: FontWeight.bold, letterSpacing: 2)),
        actions: [
          IconButton(
              icon: const Icon(Icons.track_changes_outlined,
                  color: FQColors.green),
              onPressed: _setGoalDialog,
              tooltip: 'Set Goal'),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: FQColors.green))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 220,
                        height: 220,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 14,
                          backgroundColor: FQColors.border,
                          color: FQColors.green,
                        ),
                      ),
                      Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(
                          isWalking
                              ? Icons.directions_walk
                              : Icons.accessibility_new,
                          color: FQColors.green,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text('$_displaySteps',
                            style: GoogleFonts.rajdhani(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.bold)),
                        Text('of $_goal steps',
                            style: const TextStyle(
                                color: FQColors.muted, fontSize: 13)),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: FQColors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: FQColors.green.withOpacity(0.4)),
                    ),
                    child: Text(
                        isWalking ? 'WALKING' : 'STANDING',
                        style: GoogleFonts.rajdhani(
                            color: FQColors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 2)),
                  ),
                  const SizedBox(height: 32),
                  Row(children: [
                    _statCard(Icons.straighten, '${km}km', 'DISTANCE'),
                    const SizedBox(width: 12),
                    _statCard(Icons.local_fire_department_outlined,
                        '${kcal}kcal', 'CALORIES'),
                    const SizedBox(width: 12),
                    _statCard(Icons.flag_outlined,
                        '${(progress * 100).toStringAsFixed(0)}%',
                        'GOAL'),
                  ]),
                  const SizedBox(height: 32),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                      const Text('Progress to goal',
                          style: TextStyle(
                              color: FQColors.muted, fontSize: 12)),
                      Text('$_displaySteps / $_goal',
                          style: const TextStyle(
                              color: FQColors.green, fontSize: 12)),
                    ]),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: FQColors.border,
                        color: FQColors.green,
                        minHeight: 8,
                      ),
                    ),
                  ]),
                ],
              ),
            ),
    );
  }

  Widget _statCard(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: FQColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FQColors.border),
        ),
        child: Column(children: [
          Icon(icon, color: FQColors.green, size: 18),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.rajdhani(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          Text(label,
              style: const TextStyle(color: FQColors.muted, fontSize: 10)),
        ]),
      ),
    );
  }
}
