import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../core/utils/validators/input_validator.dart';
import 'widgets/auth_widgets.dart';
import 'signup_page.dart';
import 'dart:async';
import '../../../widgets/text_field.dart';
import './widgets/custom_password_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final Logger _logger = Logger();

  bool _isLoading = false;
  bool _showCursor = true;
  String? _emailErrorMessage;
  String? _passwordErrorMessage;
  late Timer _cursorTimer;

  @override
  void initState() {
    super.initState();
    // Start blinking cursor timer
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      setState(() {
        _showCursor = !_showCursor;
      });
    });
  }

  Future<void> _login() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    // Validate form
    if (!_validateForm()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _emailErrorMessage = null;
      _passwordErrorMessage = null;
    });

    try {
      _logger.i('Attempting to log in user: ${_emailController.text}');

      // Call auth service to log in with standard authentication
      await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      _logger.i('Login successful, verifying token validity');

      // Verify token validity after login
      final isTokenValid = await _authService.isLoggedIn();

      if (!isTokenValid) {
        _logger.w(
            'Token validation failed after login, forcing auth state update');

        // Force auth state update if token validation fails
        final updateSuccess = await _authService.forceAuthStateUpdate();

        if (!updateSuccess) {
          _logger.e('Auth state update failed, showing error');
          throw 'Authentication failed. Please try again.';
        }
      }

      _logger.i('Authentication verified, navigating to welcome screen');

      // Navigate back to auth check which will redirect to welcome screen
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      _logger.e('Login error: $e');

      if (!mounted) return;

      // Already formatted error messages from JarvisApiService
      if (e.toString().contains('Email hoặc mật khẩu không đúng')) {
        setState(() {
          _passwordErrorMessage = e.toString();
          _isLoading = false;
        });
        return;
      }

      // Handle other errors
      String errorMsg;
      if (e.toString().contains('invalid_credentials') ||
          e.toString().contains('wrong password') ||
          e.toString().contains('user not found') ||
          e.toString().contains('EMAIL_PASSWORD_MISMATCH') ||
          e.toString().contains('Wrong e-mail or password')) {
        errorMsg = 'Incorrect email or password. Please try again.';
        setState(() {
          _passwordErrorMessage = errorMsg;
          _isLoading = false;
        });
        return;
      } else if (e.toString().contains('network') ||
          e.toString().contains('connect')) {
        errorMsg =
            'Network connection error. Please check your internet connection.';
      } else if (e.toString().toLowerCase().contains('scope') ||
          e.toString().toLowerCase().contains('permission')) {
        errorMsg =
            'Unable to login with full access permissions. Please try again.';
      } else {
        // Use a more user-friendly error message
        errorMsg = 'Login error: ${e.toString()}';
      }

      setState(() {
        _passwordErrorMessage = errorMsg;
        _isLoading = false;
      });
    }
  }

  bool _validateForm() {
    setState(() {
      _emailErrorMessage = null;
      _passwordErrorMessage = null;
    });

    // Validate email
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _emailErrorMessage = 'Please enter your email';
      });
      return false;
    }

    if (!InputValidator.isValidEmail(_emailController.text.trim())) {
      // Updated class name
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

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.dark;

    return AuthBackground(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24.0, 120.0, 24.0, 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App title
            Text(
              'AI Chat Bot',
              style: TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.bold,
                color: colors.foreground,
              ),
            ),

            // Description
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Understand the universe',
                  style: TextStyle(
                    fontSize: 24,
                    color: colors.muted,
                    fontFamily: 'monospace',
                  ),
                ),
                SizedBox(
                  width: 15,
                  child: Text(
                    _showCursor ? '_' : ' ',
                    style: TextStyle(
                      fontSize: 24,
                      color: colors.muted,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 60),

            // Login Form
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildEmailField(),
                  const SizedBox(height: 16),
                  _buildPasswordField(),
                  const SizedBox(height: 24),
                  _buildLoginButton(),
                ],
              ),
            ),

            const SizedBox(height: 20),

            AuthLinkWidget(
              questionText: 'Don\'t have an account?',
              linkText: 'Sign up now',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SignupPage(),
                  ),
                );
              },
            ),

            const SizedBox(height: 30),

            TermsAndPrivacyLinks(
              introText: 'By logging in, you agree to our',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return CustomTextField(
      controller: _emailController,
      label: 'Email',
      hintText: 'Enter your email',
      errorText: _emailErrorMessage,
      prefixIcon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      onChanged: (_) => setState(() => _emailErrorMessage = null),
      darkMode: true,
    );
  }

  Widget _buildPasswordField() {
    return CustomPasswordField(
      controller: _passwordController,
      label: 'Password',
      hintText: 'Enter your password',
      errorText: _passwordErrorMessage,
      onChanged: (_) => setState(() => _passwordErrorMessage = null),
      onSubmitted: (_) => _login(),
      darkMode: true,
    );
  }

  Widget _buildLoginButton() {
    return SubmitButton(
      label: 'Login',
      onPressed: _login,
      isLoading: _isLoading,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _cursorTimer.cancel();
    super.dispose();
  }
}
