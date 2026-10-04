import 'package:flutter/material.dart';
import '../../models/models.dart';
import 'auth_screen.dart';

class SignUpScreen extends StatelessWidget {
  final VoidCallback? onLoginTap;
  final Function(UserProfileModel)? onSignUpSuccess;

  const SignUpScreen({
    Key? key,
    this.onLoginTap,
    this.onSignUpSuccess,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AuthScreen(
      initialIsLogin: false,
      onAuthSuccess: onSignUpSuccess,
    );
  }
}
