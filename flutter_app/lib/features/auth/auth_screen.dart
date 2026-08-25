import 'package:flutter/material.dart';
import '../../models/models.dart';

class AuthScreen extends StatefulWidget {
  final Function(UserProfileModel) onAuthSuccess;

  const AuthScreen({Key? key, required this.onAuthSuccess}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _emailController = TextEditingController(text: 'student@cosmyra.edu');
  final _passwordController = TextEditingController(text: 'password123');
  final _fullNameController = TextEditingController(text: 'Rahul Sharma');
  String _targetExam = 'NEET';
  String _selectedRole = 'student';
  bool _isLoading = false;

  void _handleSubmit() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));

    final profile = UserProfileModel(
      id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
      email: _emailController.text.trim(),
      fullName: _isLogin ? (_selectedRole == 'admin' ? 'Dr. Sharma (Admin)' : 'Rahul Sharma') : _fullNameController.text.trim(),
      targetExam: _targetExam,
      targetYear: 2026,
      role: _selectedRole,
      studyStreak: 12,
      questionsAttempted: 480,
      totalCorrect: 395,
      accuracy: 82.3,
      rank: 14,
    );

    setState(() => _isLoading = false);
    widget.onAuthSuccess(profile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App Logo Header
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.school_rounded, color: Colors.white, size: 36),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Cosmyra Edu Platform',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 24),
                ),
                const SizedBox(height: 4),
                Text(
                  _isLogin ? 'Sign in to continue your NEET/JEE preparation' : 'Create an account to start practicing',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 24),

                // Role Toggle (Demo Feature)
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Student Mode')),
                        selected: _selectedRole == 'student',
                        onSelected: (val) => setState(() => _selectedRole = 'student'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Admin Panel')),
                        selected: _selectedRole == 'admin',
                        selectedColor: Colors.redAccent.withOpacity(0.2),
                        onSelected: (val) => setState(() => _selectedRole = 'admin'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (!_isLogin) ...[
                  TextField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _targetExam,
                    decoration: const InputDecoration(
                      labelText: 'Target Competitive Exam',
                      prefixIcon: Icon(Icons.stars_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'NEET', child: Text('NEET UG (Medical)')),
                      DropdownMenuItem(value: 'JEE_MAIN', child: Text('JEE Main (Engineering)')),
                      DropdownMenuItem(value: 'JEE_ADV', child: Text('JEE Advanced (IIT)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _targetExam = val);
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _selectedRole == 'admin' ? Colors.redAccent : Theme.of(context).primaryColor,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _isLogin ? 'Sign In' : 'Create Account',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),

                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(
                    _isLogin ? "Don't have an account? Sign Up" : 'Already registered? Sign In',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
