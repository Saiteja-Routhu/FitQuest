import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../main.dart';
import 'dashboard_screen.dart';
import 'assessment_wizard_screen.dart';

// Role-index ↔ backend string
const _roleStrings = ['RECRUIT', 'GUILD_MASTER', 'SUPER_COACH', 'HIGH_COUNCIL'];

class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _usernameCtrl  = TextEditingController();
  final _passwordCtrl  = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _heightCtrl    = TextEditingController();
  final _weightCtrl    = TextEditingController();
  final _accessKeyCtrl = TextEditingController();

  String _activityLevel  = 'Sedentary';
  String _goal           = 'Weight Loss';
  bool   _isLogin        = true;
  bool   _isLoading      = false;
  bool   _obscurePass    = true;
  bool   _rememberMe     = false;
  bool   _isAutoLogging  = true; // shows splash while checking saved session

  static const _goals = [
    'Weight Loss', 'Muscle Gain', 'Bulk', 'Cut', 'Maintain', 'Endurance',
  ];
  static const _activityLevels = [
    'Sedentary', 'Lightly Active', 'Active', 'Very Active',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _usernameCtrl.clear();
        _passwordCtrl.clear();
        _emailCtrl.clear();
        _heightCtrl.clear();
        _weightCtrl.clear();
        _accessKeyCtrl.clear();
        setState(() {
          _isLogin = true;
          _activityLevel = 'Sedentary';
          _goal = 'Weight Loss';
        });
      } else {
        setState(() {});
      }
    });
    _tryAutoLogin();
  }

  // ── Auto-login from saved session ──────────────────────────────────────────
  void _tryAutoLogin() async {
    final session = await ApiService.loadSession();
    if (session == null) {
      setState(() => _isAutoLogging = false);
      return;
    }
    // Pre-fill fields so the form looks correct if auto-login fails
    _usernameCtrl.text = session['username'];
    _passwordCtrl.text = session['password'];
    final roleIdx = session['roleIndex'] as int;
    _tabController.index = roleIdx;
    setState(() => _rememberMe = true);

    try {
      final resp = await ApiService.loginUser(
        session['username'], session['password'], _roleStrings[roleIdx]);
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => DashboardScreen(
            userData: resp['user'],
            role:     resp['role'],
            password: session['password'],
          ),
        ));
      }
    } catch (_) {
      // Server unreachable or credentials changed — clear session, show form
      await ApiService.clearSession();
      if (mounted) setState(() { _isAutoLogging = false; _rememberMe = false; });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usernameCtrl.dispose(); _passwordCtrl.dispose();
    _emailCtrl.dispose(); _heightCtrl.dispose();
    _weightCtrl.dispose(); _accessKeyCtrl.dispose();
    super.dispose();
  }

  String get _role {
    if (_tabController.index == 1) return 'GUILD_MASTER';
    if (_tabController.index == 2) return 'SUPER_COACH';
    if (_tabController.index == 3) return 'HIGH_COUNCIL';
    return 'RECRUIT';
  }

  void _submit() async {
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        final resp = await ApiService.loginUser(
          _usernameCtrl.text, _passwordCtrl.text, _role);
        if (_rememberMe) {
          await ApiService.saveSession(
              _usernameCtrl.text, _passwordCtrl.text, _tabController.index);
        } else {
          await ApiService.clearSession(); // remove any old saved session
        }
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (_) => DashboardScreen(
              userData: resp['user'],
              role: resp['role'],
              password: _passwordCtrl.text,
            ),
          ));
        }
      } else {
        final data = <String, dynamic>{
          'username': _usernameCtrl.text,
          'password': _passwordCtrl.text,
          'email':    _emailCtrl.text,
          'role':     _role,
        };
        if (_role == 'RECRUIT') {
          data['height']         = double.tryParse(_heightCtrl.text)  ?? 170.0;
          data['weight']         = double.tryParse(_weightCtrl.text)  ?? 70.0;
          data['activity_level'] = _activityLevel;
          data['goal']           = _goal;
        } else if (_role == 'GUILD_MASTER' || _role == 'SUPER_COACH') {
          data['access_key'] = _accessKeyCtrl.text;
        }
        await ApiService.registerUser(data);
        if (mounted) {
          // Recruits go through the assessment wizard first
          if (_role == 'RECRUIT') {
            Navigator.pushReplacement(context, MaterialPageRoute(
              builder: (_) => AssessmentWizardScreen(
                username: _usernameCtrl.text,
                password: _passwordCtrl.text,
                roleIndex: _tabController.index,
              ),
            ));
          } else {
            setState(() => _isLogin = true);
            _usernameCtrl.clear(); _passwordCtrl.clear(); _emailCtrl.clear();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Account created! You can now log in.'),
              backgroundColor: FQColors.green,
            ));
          }
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceAll('Exception: ', '')),
        backgroundColor: FQColors.red,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a minimal splash while checking saved credentials
    if (_isAutoLogging) {
      return Scaffold(
        backgroundColor: FQColors.bg,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.bolt, color: FQColors.cyan, size: 48),
            const SizedBox(height: 20),
            Text('FITQUEST', style: GoogleFonts.rajdhani(
              color: Colors.white, fontSize: 28,
              fontWeight: FontWeight.w900, letterSpacing: 6)),
            const SizedBox(height: 32),
            const SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(
                  color: FQColors.cyan, strokeWidth: 2),
            ),
          ]),
        ),
      );
    }

    return Scaffold(
      backgroundColor: FQColors.bg,
      body: Stack(
        children: [
          // Subtle grid background
          CustomPaint(painter: _GridPainter(), size: Size.infinite),
          // Radial glow at top
          Container(decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.7),
              radius: 1.0,
              colors: [FQColors.cyan.withOpacity(0.07), Colors.transparent],
            ),
          )),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLogo(),
                    const SizedBox(height: 32),
                    _buildCard(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Column(children: [
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: FQColors.cyan.withOpacity(0.1),
          border: Border.all(color: FQColors.cyan.withOpacity(0.4), width: 2),
        ),
        child: const Icon(Icons.bolt, color: FQColors.cyan, size: 32),
      ),
      const SizedBox(height: 12),
      Text('FITQUEST', style: GoogleFonts.rajdhani(
        fontSize: 36, fontWeight: FontWeight.w900,
        color: Colors.white, letterSpacing: 6,
      )),
      Text('LEVEL UP YOUR LIFE', style: GoogleFonts.rajdhani(
        fontSize: 11, color: FQColors.muted, letterSpacing: 5,
      )),
    ]);
  }

  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        color: FQColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FQColors.border),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTabs(),
          const SizedBox(height: 24),
          _buildFields(),
          const SizedBox(height: 24),
          _buildSubmitButton(),
          if (_tabController.index != 3) ...[
            const SizedBox(height: 8),
            _buildToggle(),
          ],
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        color: FQColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FQColors.border),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: FQColors.cyan.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: FQColors.cyan.withOpacity(0.4)),
        ),
        labelColor: FQColors.cyan,
        unselectedLabelColor: FQColors.muted,
        labelStyle: GoogleFonts.rajdhani(
            fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
        tabs: const [
          Tab(icon: Icon(Icons.person_outline, size: 16),
              text: 'ATHLETE', height: 52, iconMargin: EdgeInsets.only(bottom: 2)),
          Tab(icon: Icon(Icons.shield_outlined, size: 16),
              text: 'COACH', height: 52, iconMargin: EdgeInsets.only(bottom: 2)),
          Tab(icon: Icon(Icons.supervisor_account_outlined, size: 16),
              text: 'SUPER', height: 52, iconMargin: EdgeInsets.only(bottom: 2)),
          Tab(icon: Icon(Icons.admin_panel_settings_outlined, size: 16),
              text: 'ADMIN', height: 52, iconMargin: EdgeInsets.only(bottom: 2)),
        ],
      ),
    );
  }

  Widget _buildFields() {
    return Column(children: [
      _field(_usernameCtrl, 'Username', Icons.person_outline),
      const SizedBox(height: 12),
      _passwordField(),
      if (_isLogin) ...[
        const SizedBox(height: 8),
        _rememberMeRow(),
      ],
      if (!_isLogin) ...[
        const SizedBox(height: 12),
        _field(_emailCtrl, 'Email', Icons.email_outlined),
        if (_tabController.index == 0) ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _field(_heightCtrl, 'Height (cm)', Icons.height, isNumber: true)),
            const SizedBox(width: 10),
            Expanded(child: _field(_weightCtrl, 'Weight (kg)', Icons.monitor_weight_outlined, isNumber: true)),
          ]),
          const SizedBox(height: 12),
          _dropdown(_goal, _goals, 'Goal',
              Icons.flag_outlined, (v) => setState(() => _goal = v!)),
          const SizedBox(height: 12),
          _dropdown(_activityLevel, _activityLevels, 'Activity Level',
              Icons.directions_run_outlined, (v) => setState(() => _activityLevel = v!)),
        ],
        if (_tabController.index == 1 || _tabController.index == 2) ...[
          const SizedBox(height: 12),
          _field(
            _accessKeyCtrl,
            _tabController.index == 2 ? 'Super Coach Access Key' : 'Coach Access Key',
            Icons.vpn_key_outlined,
            accentColor: _tabController.index == 2 ? FQColors.purple : FQColors.gold,
          ),
        ],
      ],
    ]);
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {bool isNumber = false, Color? accentColor}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: accentColor ?? Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: accentColor?.withOpacity(0.8) ?? FQColors.muted),
        prefixIcon: Icon(icon, color: accentColor ?? FQColors.muted, size: 18),
      ),
    );
  }

  Widget _rememberMeRow() {
    return GestureDetector(
      onTap: () => setState(() => _rememberMe = !_rememberMe),
      child: Row(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 20, height: 20,
          decoration: BoxDecoration(
            color: _rememberMe ? FQColors.cyan : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: _rememberMe ? FQColors.cyan : FQColors.muted,
              width: 1.5,
            ),
          ),
          child: _rememberMe
              ? const Icon(Icons.check, color: Colors.black, size: 14)
              : null,
        ),
        const SizedBox(width: 10),
        Text('Remember me',
            style: TextStyle(
                color: _rememberMe ? FQColors.cyan : FQColors.muted,
                fontSize: 13)),
      ]),
    );
  }

  Widget _passwordField() {
    return TextField(
      controller: _passwordCtrl,
      obscureText: _obscurePass,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock_outline, color: FQColors.muted, size: 18),
        suffixIcon: IconButton(
          icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility,
              color: FQColors.muted, size: 18),
          onPressed: () => setState(() => _obscurePass = !_obscurePass),
        ),
      ),
    );
  }

  Widget _dropdown(String value, List<String> items, String label,
      IconData icon, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: FQColors.card,
      style: const TextStyle(color: Colors.white),
      iconEnabledColor: FQColors.muted,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: FQColors.muted, size: 18),
      ),
      items: items.map((g) => DropdownMenuItem(
        value: g,
        child: Text(g, style: const TextStyle(color: Colors.white, fontSize: 15)),
      )).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildSubmitButton() {
    final text = _isLogin ? 'ENTER THE ARENA' : 'JOIN THE LEAGUE';
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: FQColors.cyan))
          : ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: FQColors.cyan,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Text(text, style: GoogleFonts.rajdhani(
                fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 2,
              )),
            ),
    );
  }

  Widget _buildToggle() {
    return TextButton(
      onPressed: () => setState(() => _isLogin = !_isLogin),
      child: Text(
        _isLogin ? 'New here? Create an account' : 'Already registered? Log in',
        style: const TextStyle(color: FQColors.muted, fontSize: 13),
      ),
    );
  }
}

// Subtle dot-grid background
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E2D40).withOpacity(0.45)
      ..strokeWidth = 0.5;
    const step = 36.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
