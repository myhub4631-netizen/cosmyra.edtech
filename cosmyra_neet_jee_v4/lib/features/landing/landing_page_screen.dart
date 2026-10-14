import 'package:flutter/material.dart';
import '../auth/auth_screen.dart';

class LandingPageScreen extends StatelessWidget {
  final VoidCallback? onStartPracticing;
  final VoidCallback? onExploreTests;
  final VoidCallback? onSignUp;
  final VoidCallback? onLogIn;
  final bool isLoginRoute;

  const LandingPageScreen({
    Key? key,
    this.onStartPracticing,
    this.onExploreTests,
    this.onSignUp,
    this.onLogIn,
    this.isLoginRoute = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const AuthScreen(initialIsLogin: true);
  }
}
