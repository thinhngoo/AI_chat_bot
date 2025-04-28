import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../core/utils/validators/input_validator.dart';
import '../../../widgets/auth/auth_widgets.dart';
import 'signup_page.dart';
import 'dart:async';

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
  String? _emailErrorMessage;
  String? _passwordErrorMessage;
  bool _showCursor = true;
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
        errorMsg = 'Email hoặc mật khẩu không đúng. Vui lòng thử lại.';
        setState(() {
          _passwordErrorMessage = errorMsg;
          _isLoading = false;
        });
        return;
      } else if (e.toString().contains('network') ||
          e.toString().contains('connect')) {
        errorMsg =
            'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối internet của bạn.';
      } else if (e.toString().toLowerCase().contains('scope') ||
          e.toString().toLowerCase().contains('permission')) {
        errorMsg =
            'Không thể đăng nhập với đầy đủ quyền truy cập. Vui lòng thử lại.';
      } else {
        // Use a more user-friendly error message
        errorMsg = 'Lỗi đăng nhập: ${e.toString()}';
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
        _emailErrorMessage = 'Vui lòng nhập email';
      });
      return false;
    }

    if (!InputValidator.isValidEmail(_emailController.text.trim())) {
      // Updated class name
      setState(() {
        _emailErrorMessage = 'Email không hợp lệ';
      });
      return false;
    }

    // Validate password
    if (_passwordController.text.isEmpty) {
      setState(() {
        _passwordErrorMessage = 'Vui lòng nhập mật khẩu';
      });
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background grid image
          Positioned.fill(
            child: Transform(
              transform: Matrix4.identity()
                ..scale(1.2, 1.2) // Scale up the image a bit
                ..translate(
                    0.0, -260.0), // Move it up by adjusting this Y value
              alignment: Alignment.center,
              child: Image.asset(
                'assets/images/synthwave.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Overlay with slight transparency
          Positioned.fill(
            child: Container(
              color: AppColors.background.withAlpha(191),
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24.0, 60.0, 24.0, 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App title
                  Text(
                    'AI Chat Bot',
                    style: TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                      color: AppColors.foreground,
                    ),
                  ),
                  // Description
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Trải nghiệm ngay',
                        style: TextStyle(
                          fontSize: 24,
                          color: AppColors.muted,
                          fontFamily: 'monospace',
                        ),
                      ),
                      SizedBox(
                        width: 15,
                        child: Text(
                          _showCursor ? '_' : ' ',
                          style: TextStyle(
                            fontSize: 24,
                            color: AppColors.muted,
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
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Đăng nhập',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.foreground,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildEmailField(),
                        const SizedBox(height: 16),
                        _buildPasswordField(),
                        const SizedBox(height: 24),
                        _buildLoginButton(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Chưa có tài khoản?',
                        style: TextStyle(
                          color: AppColors.muted,
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding:
                              EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignupPage(),
                            ),
                          );
                        },
                        child: Text(
                          'Đăng ký ngay',
                          style: TextStyle(
                            color: AppColors.foreground,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Terms and Privacy Policy
                  Text(
                    'Bằng cách đăng nhập, bạn đồng ý với',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 14,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding:
                              EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Điều khoản',
                          style: TextStyle(
                            color: AppColors.muted,
                            decoration: TextDecoration.underline,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        'và',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding:
                              EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Chính sách bảo mật',
                          style: TextStyle(
                            color: AppColors.muted,
                            decoration: TextDecoration.underline,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return CustomFormField(
      controller: _emailController,
      label: 'Email',
      hintText: 'Nhập email của bạn',
      errorText: _emailErrorMessage,
      prefixIcon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      onChanged: (_) => setState(() => _emailErrorMessage = null),
      darkMode: true,
    );
  }

  Widget _buildPasswordField() {
    return CustomFormField(
      controller: _passwordController,
      label: 'Mật khẩu',
      hintText: 'Nhập mật khẩu của bạn',
      errorText: _passwordErrorMessage,
      prefixIcon: Icons.lock_outline,
      obscureText: true,
      onChanged: (_) => setState(() => _passwordErrorMessage = null),
      onSubmit: _login,
      darkMode: true,
    );
  }

  Widget _buildLoginButton() {
    return SubmitButton(
      label: 'Đăng nhập',
      onPressed: _login,
      isLoading: _isLoading,
      darkMode: true,
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
