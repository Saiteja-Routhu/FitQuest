import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';

class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();

  // Recruit Fields
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String _activityLevel = 'Sedentary';
  String _goal = 'Weight Loss';

  // Coach Field
  final _accessKeyController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _rememberMe = false; // ✅ NEW: Remember Me State

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void _submitAuth() async {
    setState(() => _isLoading = true);

    String role = 'RECRUIT';
    if (_tabController.index == 1) role = 'GUILD_MASTER';
    if (_tabController.index == 2) role = 'HIGH_COUNCIL';

    try {
      if (_isLogin) {
        await ApiService.loginUser(
          _usernameController.text,
          _passwordController.text,
          role,
        );
        // ✅ NOTE: Here we would save the token if _rememberMe is true
        // ✅ CHANGED: Pass data to Dashboard
        if (mounted) {
           // The login response contains: { "message": "...", "role": "...", "user": {...} }
           final responseData = await ApiService.loginUser(
              _usernameController.text,
              _passwordController.text,
              role
           );

           Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DashboardScreen(
              userData: responseData['user'], // Pass the user details
              role: responseData['role'],     // Pass the role
              password: _passwordController.text, // Pass password for Admin actions
            ))
          );
        }
      } else {
        // Registration Logic (Same as before)
        final Map<String, dynamic> data = {
          "username": _usernameController.text,
          "password": _passwordController.text,
          "email": _emailController.text,
          "role": role,
        };

        if (role == 'RECRUIT') {
          data["height"] = double.tryParse(_heightController.text) ?? 170.0;
          data["weight"] = double.tryParse(_weightController.text) ?? 70.0;
          data["activity_level"] = _activityLevel;
          data["goal"] = _goal;
        } else if (role == 'GUILD_MASTER') {
          data["access_key"] = _accessKeyController.text;
        }

        await ApiService.registerUser(data);

        setState(() {
          _isLogin = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Registration Successful! Please Login.")),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString().replaceAll('Exception: ', '')}"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage("https://i.pinimg.com/736x/8a/75/3d/8a753d0aa23594892bc6916a243c32b5.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.7)),

          Center(
            child: SingleChildScrollView(
              child: Card(
                margin: const EdgeInsets.all(20),
                color: Colors.black.withOpacity(0.8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("FITQUEST", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueAccent, letterSpacing: 2)),
                      const SizedBox(height: 20),

                      TabBar(
                        controller: _tabController,
                        indicatorColor: Colors.blueAccent,
                        labelColor: Colors.blueAccent,
                        unselectedLabelColor: Colors.white54,
                        tabs: const [
                          Tab(icon: Icon(Icons.person), text: "Recruit"),
                          Tab(icon: Icon(Icons.shield), text: "Guild Master"),
                          Tab(icon: Icon(Icons.admin_panel_settings), text: "High Council"),
                        ],
                        onTap: (index) => setState(() {}),
                      ),
                      const SizedBox(height: 20),

                      TextField(controller: _usernameController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Username", prefixIcon: Icon(Icons.person, color: Colors.white70))),
                      const SizedBox(height: 10),
                      TextField(controller: _passwordController, obscureText: true, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Password", prefixIcon: Icon(Icons.lock, color: Colors.white70))),

                      if (!_isLogin) ...[
                        const SizedBox(height: 10),
                        TextField(controller: _emailController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email, color: Colors.white70))),
                        if (_tabController.index == 0) ...[
                          const SizedBox(height: 10),
                          Row(children: [
                            Expanded(child: TextField(controller: _heightController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Height (cm)"))),
                            const SizedBox(width: 10),
                            Expanded(child: TextField(controller: _weightController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Weight (kg)"))),
                          ]),
                        ],
                        if (_tabController.index == 1) ...[
                          const SizedBox(height: 10),
                          TextField(controller: _accessKeyController, style: const TextStyle(color: Colors.amber), decoration: const InputDecoration(labelText: "Guild Access Key", prefixIcon: Icon(Icons.vpn_key, color: Colors.amber))),
                        ]
                      ],

                      const SizedBox(height: 10),

                      // ✅ "REMEMBER ME" BUTTON ADDED HERE
                      if (_isLogin)
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (val) => setState(() => _rememberMe = val!),
                              activeColor: Colors.blueAccent,
                              side: const BorderSide(color: Colors.white70),
                            ),
                            const Text("Remember Me", style: TextStyle(color: Colors.white70)),
                          ],
                        ),

                      const SizedBox(height: 10),

                      _isLoading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(vertical: 15)),
                            onPressed: _submitAuth,
                            child: Text(_isLogin ? "ENTER THE GUILD" : "SIGN CONTRACT", style: const TextStyle(fontSize: 16, color: Colors.white)),
                          ),
                        ),

                      if (_tabController.index != 2)
                        TextButton(
                          onPressed: () => setState(() => _isLogin = !_isLogin),
                          child: Text(_isLogin ? "New Recruit? Register here." : "Already have an account? Login.", style: const TextStyle(color: Colors.white70)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}