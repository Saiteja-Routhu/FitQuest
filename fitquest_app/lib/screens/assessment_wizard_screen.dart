import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../services/api_service.dart';
import 'auth_gate_screen.dart';

class AssessmentWizardScreen extends StatefulWidget {
  final String username;
  final String password;
  final int roleIndex;

  const AssessmentWizardScreen({
    super.key,
    required this.username,
    required this.password,
    required this.roleIndex,
  });

  @override
  State<AssessmentWizardScreen> createState() => _AssessmentWizardScreenState();
}

class _AssessmentWizardScreenState extends State<AssessmentWizardScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  bool _submitting = false;

  // Step 1: Body Measurements
  final _waistCtrl = TextEditingController();
  final _chestCtrl = TextEditingController();
  final _bicepCtrl = TextEditingController();
  final _thighCtrl = TextEditingController();

  // Step 2: Medical History
  final _medHistCtrl = TextEditingController();
  final _injuriesCtrl = TextEditingController();

  // Step 3: Diet & Nutrition
  String _foodPref = 'Non-Veg';
  final _mealsCtrl = TextEditingController(text: '3');
  final _breakfastCtrl = TextEditingController();
  final _lunchCtrl = TextEditingController();
  final _dinnerCtrl = TextEditingController();
  final _snacksCtrl = TextEditingController();

  static const _foodPrefs = [
    'Vegan', 'Jain', 'Lacto-Veg', 'Ovo-Veg', 'Pescatarian', 'Non-Veg',
  ];

  // Step 4: Lifestyle Habits
  final _teaCoffeeCtrl = TextEditingController();
  final _alcoholCtrl = TextEditingController();
  final _allergiesCtrl = TextEditingController();

  // Step 5: Exercise Background
  final _exerciseExpCtrl = TextEditingController();
  final _prefExerciseCtrl = TextEditingController();
  final _daysAvailCtrl = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _waistCtrl.dispose(); _chestCtrl.dispose(); _bicepCtrl.dispose();
    _thighCtrl.dispose(); _medHistCtrl.dispose(); _injuriesCtrl.dispose();
    _mealsCtrl.dispose(); _breakfastCtrl.dispose(); _lunchCtrl.dispose();
    _dinnerCtrl.dispose(); _snacksCtrl.dispose(); _teaCoffeeCtrl.dispose();
    _alcoholCtrl.dispose(); _allergiesCtrl.dispose(); _exerciseExpCtrl.dispose();
    _prefExerciseCtrl.dispose(); _daysAvailCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentStep < 4) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep++);
    } else {
      _submit();
    }
  }

  void _back() {
    if (_currentStep > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep--);
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final data = {
        'waist_circumference': double.tryParse(_waistCtrl.text) ?? 0.0,
        'chest_size': double.tryParse(_chestCtrl.text),
        'bicep_size': double.tryParse(_bicepCtrl.text),
        'thigh_size': double.tryParse(_thighCtrl.text),
        'medical_history': _medHistCtrl.text,
        'injuries': _injuriesCtrl.text,
        'food_preference': _foodPref,
        'meals_per_day': int.tryParse(_mealsCtrl.text) ?? 3,
        'typical_breakfast': _breakfastCtrl.text,
        'typical_lunch': _lunchCtrl.text,
        'typical_dinner': _dinnerCtrl.text,
        'typical_snacks': _snacksCtrl.text,
        'tea_coffee_cups': _teaCoffeeCtrl.text,
        'alcohol_frequency': _alcoholCtrl.text,
        'food_allergies': _allergiesCtrl.text,
        'exercise_experience': _exerciseExpCtrl.text,
        'preferred_exercise': _prefExerciseCtrl.text,
        'days_available': _daysAvailCtrl.text,
      };

      await ApiService.postWithBasicAuth(
          '/users/assessment/', widget.username, widget.password, data);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AuthGateScreen()),
        );
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Assessment complete! You can now log in.'),
          backgroundColor: FQColors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'),
          backgroundColor: FQColors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      'Body Measurements',
      'Medical History',
      'Diet & Nutrition',
      'Lifestyle Habits',
      'Exercise Background',
    ];

    return Scaffold(
      backgroundColor: FQColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(steps),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                  _buildStep4(),
                  _buildStep5(),
                ],
              ),
            ),
            _buildNavButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(List<String> steps) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: FQColors.border))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.bolt, color: FQColors.cyan, size: 20),
          const SizedBox(width: 8),
          Text('FITQUEST', style: GoogleFonts.rajdhani(
              color: FQColors.cyan, fontSize: 14,
              fontWeight: FontWeight.bold, letterSpacing: 3)),
        ]),
        const SizedBox(height: 12),
        Text('ATHLETE ASSESSMENT', style: GoogleFonts.rajdhani(
            color: Colors.white, fontSize: 22,
            fontWeight: FontWeight.bold, letterSpacing: 1)),
        Text('Step ${_currentStep + 1} of 5 — ${steps[_currentStep]}',
            style: const TextStyle(color: FQColors.muted, fontSize: 12)),
        const SizedBox(height: 12),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 5,
            backgroundColor: FQColors.border,
            color: FQColors.cyan,
            minHeight: 5,
          ),
        ),
      ]),
    );
  }

  Widget _buildNavButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: FQColors.border))),
      child: Row(children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: _back,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: FQColors.border),
                foregroundColor: FQColors.muted,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('BACK', style: GoogleFonts.rajdhani(
                  fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _submitting ? null : _next,
            style: ElevatedButton.styleFrom(
              backgroundColor: FQColors.cyan,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.black, strokeWidth: 2))
                : Text(_currentStep == 4 ? 'SUBMIT' : 'NEXT',
                    style: GoogleFonts.rajdhani(
                        fontWeight: FontWeight.w800,
                        fontSize: 16, letterSpacing: 2)),
          ),
        ),
      ]),
    );
  }

  Widget _stepContainer(List<Widget> children) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 16),
        child: Text(text, style: GoogleFonts.rajdhani(
            color: FQColors.cyan, fontSize: 13,
            fontWeight: FontWeight.bold, letterSpacing: 1)),
      );

  Widget _tf(TextEditingController ctrl, String hint,
      {bool multiline = false, bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      maxLines: multiline ? 3 : 1,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: FQColors.muted, fontSize: 13),
      ),
    );
  }

  // ── Step 1: Body Measurements ──────────────────────────────────────────────
  Widget _buildStep1() {
    return _stepContainer([
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: FQColors.cyan.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FQColors.cyan.withOpacity(0.2)),
        ),
        child: Row(children: [
          const Icon(Icons.straighten, color: FQColors.cyan, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Enter your measurements in inches. These help your coach create a personalised plan.',
              style: const TextStyle(color: FQColors.muted, fontSize: 12),
            ),
          ),
        ]),
      ),
      _label('WAIST (inches) *'),
      _tf(_waistCtrl, 'e.g. 32', isNumber: true),
      _label('CHEST (inches)'),
      _tf(_chestCtrl, 'e.g. 40', isNumber: true),
      _label('BICEP (inches)'),
      _tf(_bicepCtrl, 'e.g. 13', isNumber: true),
      _label('THIGH (inches)'),
      _tf(_thighCtrl, 'e.g. 22', isNumber: true),
    ]);
  }

  // ── Step 2: Medical History ────────────────────────────────────────────────
  Widget _buildStep2() {
    return _stepContainer([
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: FQColors.red.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FQColors.red.withOpacity(0.2)),
        ),
        child: Row(children: [
          const Icon(Icons.medical_services_outlined,
              color: FQColors.red, size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'This information is confidential and shared only with your coach.',
              style: TextStyle(color: FQColors.muted, fontSize: 12),
            ),
          ),
        ]),
      ),
      _label('MEDICAL HISTORY'),
      _tf(_medHistCtrl,
          'Past or present conditions (diabetes, hypertension...)',
          multiline: true),
      _label('INJURIES'),
      _tf(_injuriesCtrl, 'Fractures, chronic pain, joint issues...',
          multiline: true),
    ]);
  }

  // ── Step 3: Diet & Nutrition ───────────────────────────────────────────────
  Widget _buildStep3() {
    return _stepContainer([
      _label('FOOD PREFERENCE'),
      DropdownButtonFormField<String>(
        value: _foodPref,
        dropdownColor: FQColors.card,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.restaurant_outlined,
              color: FQColors.muted, size: 18),
        ),
        items: _foodPrefs.map((p) => DropdownMenuItem(
              value: p,
              child: Text(p, style: const TextStyle(color: Colors.white)),
            )).toList(),
        onChanged: (v) => setState(() => _foodPref = v ?? _foodPref),
      ),
      _label('MEALS PER DAY'),
      _tf(_mealsCtrl, 'e.g. 3', isNumber: true),
      _label('TYPICAL BREAKFAST'),
      _tf(_breakfastCtrl, 'What do you usually eat?', multiline: true),
      _label('TYPICAL LUNCH'),
      _tf(_lunchCtrl, 'What do you usually eat?', multiline: true),
      _label('TYPICAL DINNER'),
      _tf(_dinnerCtrl, 'What do you usually eat?', multiline: true),
      _label('SNACKS'),
      _tf(_snacksCtrl, 'Chips, fruits, protein bars...', multiline: true),
    ]);
  }

  // ── Step 4: Lifestyle Habits ───────────────────────────────────────────────
  Widget _buildStep4() {
    return _stepContainer([
      _label('TEA / COFFEE (cups per day)'),
      _tf(_teaCoffeeCtrl, 'e.g. 2'),
      _label('ALCOHOL FREQUENCY'),
      _tf(_alcoholCtrl, 'e.g. Rarely, Weekends, Daily'),
      _label('FOOD ALLERGIES'),
      _tf(_allergiesCtrl, 'Nuts, dairy, gluten...', multiline: true),
    ]);
  }

  // ── Step 5: Exercise Background ────────────────────────────────────────────
  Widget _buildStep5() {
    return _stepContainer([
      _label('EXERCISE EXPERIENCE'),
      _tf(_exerciseExpCtrl,
          'Years of training, gym history...', multiline: true),
      _label('PREFERRED EXERCISE TYPE'),
      _tf(_prefExerciseCtrl, 'e.g. Weightlifting, Running, HIIT'),
      _label('DAYS AVAILABLE PER WEEK'),
      _tf(_daysAvailCtrl, 'e.g. Mon, Wed, Fri or 3 days a week'),
    ]);
  }
}
