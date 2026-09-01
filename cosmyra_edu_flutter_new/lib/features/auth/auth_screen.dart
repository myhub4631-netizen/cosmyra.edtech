import 'package:flutter/material.dart';
import '../../models/models.dart';
import 'signup_screen.dart';
import 'login_screen.dart';

class AuthScreen extends StatefulWidget {
  final Function(UserProfileModel) onAuthSuccess;
  final bool initialIsLogin;

  const AuthScreen({
    Key? key,
    required this.onAuthSuccess,
    this.initialIsLogin = false,
  }) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late bool _isLogin;

  @override
  void initState() {
    super.initState();
    _isLogin = widget.initialIsLogin;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLogin) {
      return LoginScreen(
        onSignUpTap: () => setState(() => _isLogin = false),
        onLoginSuccess: (profile) => widget.onAuthSuccess(profile),
      );
    } else {
      return SignUpScreen(
        onLoginTap: () => setState(() => _isLogin = true),
        onSignUpSuccess: (profile) => widget.onAuthSuccess(profile),
      );
    }
  }
}
