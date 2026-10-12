import 'package:flutter/material.dart';
import '../../models/models.dart';
import 'auth_screen.dart';

class LoginScreen extends StatelessWidget {
  final VoidCallback? onSignUpTap;
  final Function(UserProfileModel)? onLoginSuccess;

  const LoginScreen({
    Key? key,
    this.onSignUpTap,
    this.onLoginSuccess,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AuthScreen(
      initialIsLogin: true,
      onAuthSuccess: onLoginSuccess,
    );
  }
}
