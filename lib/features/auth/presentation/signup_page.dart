import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../core/utils/validators/input_validator.dart';
import '../../../widgets/auth/auth_widgets.dart';
import '../../../widgets/auth/password_requirement_widget.dart';
import '../../../widgets/auth/password_strength_bar.dart';
import 'login_page.dart';

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
      if (errorMsg.contains('Email đã được sử dụng') ||
          errorMsg.contains('already exists') ||
          errorMsg.contains('email')) {
        setState(() {
          _emailErrorMessage =
              'Email đã được sử dụng. Vui lòng sử dụng email khác.';
          _isLoading = false;
        });
      } else if (errorMsg.contains('weak-password') ||
          errorMsg.contains('mật khẩu')) {
        setState(() {
          _passwordErrorMessage =
              'Mật khẩu quá yếu. Vui lòng chọn mật khẩu mạnh hơn.';
          _isLoading = false;
        });
      } else if (errorMsg.contains('network')) {
        setState(() {
          _confirmPasswordErrorMessage =
              'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối internet của bạn.';
          _isLoading = false;
        });
      } else {
        // Use a more user-friendly error message
        setState(() {
          _confirmPasswordErrorMessage = 'Lỗi đăng ký: $errorMsg';
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
        _nameErrorMessage = 'Vui lòng nhập tên của bạn';
      });
      return false;
    }

    // Validate email
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _emailErrorMessage = 'Vui lòng nhập email';
      });
      return false;
    }

    if (!InputValidator.isValidEmail(_emailController.text.trim())) {
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

    if (!InputValidator.isValidPassword(_passwordController.text)) {
      setState(() {
        _passwordErrorMessage = 'Mật khẩu không đáp ứng các yêu cầu bảo mật';
      });
      return false;
    }

    // Validate confirm password
    if (_confirmPasswordController.text != _passwordController.text) {
      setState(() {
        _confirmPasswordErrorMessage = 'Mật khẩu xác nhận không khớp';
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
                ..scale(1.2, 1.2)
                ..translate(0.0, -260.0),
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
              padding: const EdgeInsets.fromLTRB(24.0, 40.0, 24.0, 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App title
                  Text(
                    'AI Chat Bot',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppColors.foreground,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _isSuccess ? _buildSuccessCard() : _buildSignupForm(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Đăng ký tài khoản',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.foreground,
          ),
        ),
        const SizedBox(height: 24),
        CustomFormField(
          controller: _nameController,
          label: 'Họ và tên',
          hintText: 'Nhập họ và tên của bạn',
          errorText: _nameErrorMessage,
          prefixIcon: Icons.person_outline,
          onChanged: (_) => setState(() => _nameErrorMessage = null),
          darkMode: true,
        ),
        const SizedBox(height: 16),
        CustomFormField(
          controller: _emailController,
          label: 'Email',
          hintText: 'Nhập email của bạn',
          errorText: _emailErrorMessage,
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) => setState(() => _emailErrorMessage = null),
          darkMode: true,
        ),
        const SizedBox(height: 16),
        CustomFormField(
          controller: _passwordController,
          label: 'Mật khẩu',
          hintText: 'Nhập mật khẩu của bạn',
          errorText: _passwordErrorMessage,
          prefixIcon: Icons.lock_outline,
          obscureText: true,
          onChanged: (value) {
            setState(() {
              _passwordErrorMessage = null;
            });
          },
          darkMode: true,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: PasswordStrengthBar(
            password: _passwordController.text,
            darkMode: true,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: PasswordRequirementWidget(
            password: _passwordController.text,
            showTitle: true,
            darkMode: true,
          ),
        ),
        const SizedBox(height: 16),
        CustomFormField(
          controller: _confirmPasswordController,
          label: 'Xác nhận mật khẩu',
          hintText: 'Nhập lại mật khẩu của bạn',
          errorText: _confirmPasswordErrorMessage,
          prefixIcon: Icons.lock_outline,
          obscureText: true,
          onChanged: (_) => setState(() => _confirmPasswordErrorMessage = null),
          onSubmit: _signup,
          darkMode: true,
        ),
        const SizedBox(height: 24),
        SubmitButton(
          label: 'Đăng ký',
          onPressed: _signup,
          isLoading: _isLoading,
          darkMode: true,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Đã có tài khoản?',
              style: TextStyle(
                color: AppColors.muted,
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginPage(),
                  ),
                );
              },
              child: Text(
                'Đăng nhập ngay',
                style: TextStyle(
                  color: AppColors.foreground,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        Text(
          'Bằng cách đăng ký, bạn đồng ý với',
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
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
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
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
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
    );
  }

  Widget _buildSuccessCard() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppColors.input,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.green,
          ),
          const SizedBox(height: 24),
          Text(
            'Đăng ký thành công!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Tài khoản ${_emailController.text} đã được tạo thành công.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.muted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SubmitButton(
            label: 'Đăng nhập ngay',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginPage(),
                ),
              );
            },
            darkMode: true,
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
