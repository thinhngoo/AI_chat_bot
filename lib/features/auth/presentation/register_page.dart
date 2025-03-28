import 'package:flutter/material.dart';
import 'signup_page.dart';

/// This is an alias for SignupPage to maintain backward compatibility
class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SignupPage();
  }
}
