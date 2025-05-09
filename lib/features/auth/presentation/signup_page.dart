import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../core/utils/validators/input_validator.dart';
import 'widgets/auth_widgets.dart';
import 'login_page.dart';
import '../../../widgets/text_field.dart';
import 'dart:async';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final AuthService _authService = AuthService();
  final Logger _logger = Logger();

  bool _isLoading = false;
  bool _isSuccess = false;

  // Add separate error messages for each field
  String? _nameErrorMessage;
  String? _emailErrorMessage;
  String? _passwordErrorMessage;
  String? _confirmPasswordErrorMessage;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _signup() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    // Validate form
    if (!_validateForm()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _clearAllErrors();
    });

    try {
      _logger.i('Attempting to sign up user: ${_emailController.text}');

      // Call auth service to sign up
      await _authService.signUpWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
        name: _nameController.text.trim(),
      );

      if (!mounted) return;

      _logger.i('Signup successful');

      // Show success state
      setState(() {
        _isSuccess = true;
        _isLoading = false;
      });
    } catch (e) {
      _logger.e('Signup error: $e');

      if (!mounted) return;

      String errorMsg = e.toString();

      // Convert error message to user-friendly text and assign to appropriate field
      if (errorMsg.contains('Email is already in use') ||
          errorMsg.contains('already exists') ||
          errorMsg.contains('email')) {
        setState(() {
          _emailErrorMessage =
              'Email is already in use. Please use a different email.';
          _isLoading = false;
        });
      } else if (errorMsg.contains('weak-password') ||
          errorMsg.contains('mật khẩu')) {
        setState(() {
          _passwordErrorMessage =
              'Password is too weak. Please choose a stronger password.';
          _isLoading = false;
        });
      } else if (errorMsg.contains('network')) {
        setState(() {
          _confirmPasswordErrorMessage =
              'Network connection error. Please check your internet connection.';
          _isLoading = false;
        });
      } else {
        // Use a more user-friendly error message
        setState(() {
          _confirmPasswordErrorMessage = 'Registration error: $errorMsg';
          _isLoading = false;
        });
      }
    }
  }

  void _clearAllErrors() {
    _nameErrorMessage = null;
    _emailErrorMessage = null;
    _passwordErrorMessage = null;
    _confirmPasswordErrorMessage = null;
  }

  bool _validateForm() {
    setState(() {
      _clearAllErrors();
    });

    // Validate name
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _nameErrorMessage = 'Please enter your name';
      });
      return false;
    }

    // Validate email
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _emailErrorMessage = 'Please enter your email';
      });
      return false;
    }

    if (!InputValidator.isValidEmail(_emailController.text.trim())) {
      setState(() {
        _emailErrorMessage = 'Invalid email format';
      });
      return false;
    }

    // Validate password
    if (_passwordController.text.isEmpty) {
      setState(() {
        _passwordErrorMessage = 'Please enter your password';
      });
      return false;
    }

    if (!InputValidator.isValidPassword(_passwordController.text)) {
      setState(() {
        _passwordErrorMessage = 'Password does not meet security requirements';
      });
      return false;
    }

    // Validate confirm password
    if (_confirmPasswordController.text != _passwordController.text) {
      setState(() {
        _confirmPasswordErrorMessage = 'Passwords do not match';
      });
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      child: SafeArea(
        child: _isSuccess
            ? Center(child: _buildSuccessCard())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24.0, 40.0, 24.0, 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppTitleWithDescription(
                      title: 'AI Chat Bot',
                      description: 'Start your journey',
                    ),
                    const SizedBox(height: 40),
                    _buildSignupForm(),
                    const SizedBox(height: 20),
                    AuthLinkWidget(
                      questionText: 'Already have an account?',
                      linkText: 'Login now',
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                    TermsAndPrivacyLinks(
                      introText: 'By signing up, you agree to our',
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSignupForm() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CustomTextField(
            controller: _nameController,
            label: 'Full Name',
            hintText: 'Enter your full name',
            errorText: _nameErrorMessage,
            prefixIcon: Icons.person_outline,
            onChanged: (_) => setState(() => _nameErrorMessage = null),
            darkMode: true,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _emailController,
            label: 'Email',
            hintText: 'Enter your email',
            errorText: _emailErrorMessage,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => setState(() => _emailErrorMessage = null),
            darkMode: true,
          ),
          const SizedBox(height: 16),
          CustomPasswordField(
            controller: _passwordController,
            label: 'Password',
            hintText: 'Enter your password',
            errorText: _passwordErrorMessage,
            onChanged: (value) {
              setState(() {
                _passwordErrorMessage = null;
              });
            },
            darkMode: true,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: _PasswordStrengthBar(
              password: _passwordController.text,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: _PasswordRequirementWidget(
              password: _passwordController.text,
              showTitle: true,
            ),
          ),
          const SizedBox(height: 16),
          CustomPasswordField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            hintText: 'Re-enter your password',
            errorText: _confirmPasswordErrorMessage,
            onChanged: (_) =>
                setState(() => _confirmPasswordErrorMessage = null),
            onSubmitted: (_) => _signup(),
            darkMode: true,
          ),
          const SizedBox(height: 24),
          SubmitButton(
            label: 'Sign Up',
            onPressed: _signup,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard() {
    final theme = Theme.of(context);
    final AppColors colors = AppColors.dark;

    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: colors.success,
          ),
          const SizedBox(height: 16),
          Text(
            'Welcome!',
            style: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.foreground,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Account ${_emailController.text.isEmpty ? '@thinhNgo deptrai' : _emailController.text} has been created successfully.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.muted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SubmitButton(
            label: 'Login Now',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}

/// Password strength indicator bar
class _PasswordStrengthBar extends StatelessWidget {
  final String password;

  const _PasswordStrengthBar({
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate strength score from 0 to 100
    final int strengthScore = _calculateStrengthScore(password);
    final String strengthText = _getStrengthText(strengthScore);
    final Color strengthColor = _getStrengthColor(strengthScore);

    final theme = Theme.of(context);
    final AppColors colors = AppColors.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: strengthScore / 100,
              backgroundColor: colors.border,
              valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
              minHeight: 4,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 2.0),
          child: Row(
            children: [
              Text(
                'Strength: ',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.muted,
                ),
              ),
              Text(
                strengthText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: strengthColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        // Strength bar
      ],
    );
  }

  // Calculate password strength as a score from 0 to 100
  int _calculateStrengthScore(String password) {
    if (password.isEmpty) return 0;

    int score = 0;

    // Length contribution - up to 25 points
    score += password.length * 2;
    if (score > 25) score = 25;

    // Character variety - up to 75 additional points
    if (password.contains(RegExp(r'[A-Z]'))) score += 15; // Uppercase
    if (password.contains(RegExp(r'[a-z]'))) score += 15; // Lowercase
    if (password.contains(RegExp(r'[0-9]'))) score += 15; // Digits
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      score += 20; // Special chars
    }

    // Bonus for combination of character types - up to 10 additional points
    int typesCount = 0;
    if (password.contains(RegExp(r'[A-Z]'))) typesCount++;
    if (password.contains(RegExp(r'[a-z]'))) typesCount++;
    if (password.contains(RegExp(r'[0-9]'))) typesCount++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) typesCount++;

    if (typesCount >= 3) score += 10;

    return score > 100 ? 100 : score;
  }

  String _getStrengthText(int score) {
    if (score == 0) return 'Empty';
    if (score < 30) return 'Very weak';
    if (score < 50) return 'Weak';
    if (score < 70) return 'Medium';
    if (score < 90) return 'Strong';
    return 'Very strong';
  }

  Color _getStrengthColor(int score) {
    final AppColors colors = AppColors.dark;
    if (score == 0) return colors.muted;
    if (score < 30) return Colors.redAccent;
    if (score < 50) return Colors.orangeAccent;
    if (score < 70) return Colors.yellowAccent;
    if (score < 90) return Colors.lightGreenAccent;
    return Colors.greenAccent;
  }
}

/// Password requirement checker widget
class _PasswordRequirementWidget extends StatelessWidget {
  final String password;
  final bool showTitle;

  const _PasswordRequirementWidget({
    required this.password,
    this.showTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final AppColors colors = AppColors.dark;

    final requirements = [
      {
        'text': 'At least 8 characters',
        'isMet': password.length >= 8,
      },
      {
        'text': 'At least 1 uppercase letter',
        'isMet': password.contains(RegExp(r'[A-Z]')),
      },
      {
        'text': 'At least 1 lowercase letter',
        'isMet': password.contains(RegExp(r'[a-z]')),
      },
      {
        'text': 'At least 1 number',
        'isMet': password.contains(RegExp(r'[0-9]')),
      },
      {
        'text': 'At least 1 special character',
        'isMet': password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
      },
    ];

    // Split requirements into two columns
    final firstColumnReqs = requirements.sublist(0, 3);
    final secondColumnReqs = requirements.sublist(3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Text(
            'Password Requirements:',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.muted,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: firstColumnReqs
                    .map((req) => _buildRequirement(
                          req['text'] as String,
                          req['isMet'] as bool,
                          colors,
                          theme,
                        ))
                    .toList(),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: secondColumnReqs
                    .map((req) => _buildRequirement(
                          req['text'] as String,
                          req['isMet'] as bool,
                          colors,
                          theme,
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRequirement(
      String text, bool isMet, AppColors colors, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            color: isMet ? colors.success : colors.muted,
            size: 16,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isMet ? colors.success : colors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
