import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../core/utils/validators/input_validator.dart';
import '../../../widgets/auth/auth_widgets.dart';
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
    final AppColors colors = AppColors.dark;

    return AuthBackground(
      darkMode: true,
      child: SafeArea(
        child: _isSuccess
            ? Center(child: _buildSuccessCard())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24.0, 40.0, 24.0, 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App title
                    Text(
                      'AI Chat Bot',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: colors.foreground,
                      ),
                    ),

                    const SizedBox(height: 40),

                    _buildSignupForm(),

                    const SizedBox(height: 20),

                    AuthLinkWidget(
                      questionText: 'Đã có tài khoản?',
                      linkText: 'Đăng nhập ngay',
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
                    const SizedBox(height: 30),
                    TermsAndPrivacyLinks(
                      introText: 'Bằng cách đăng ký, bạn đồng ý với',
                      darkMode: true,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSignupForm() {
    final AppColors colors = AppColors.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Đăng ký tài khoản',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colors.foreground,
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
          child: _PasswordStrengthBar(
            password: _passwordController.text,
            darkMode: true,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: _PasswordRequirementWidget(
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
      ],
    );
  }

  Widget _buildSuccessCard() {
    final AppColors colors = AppColors.dark;

    return Container(
      padding: const EdgeInsets.all(24.0),
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
              color: colors.foreground,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Tài khoản ${_emailController.text} đã được tạo thành công.',
            style: TextStyle(
              fontSize: 16,
              color: colors.muted,
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

/// Password strength indicator bar
class _PasswordStrengthBar extends StatelessWidget {
  final String password;
  final bool darkMode;

  const _PasswordStrengthBar({
    required this.password,
    this.darkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate strength score from 0 to 100
    final int strengthScore = _calculateStrengthScore(password);
    final String strengthText = _getStrengthText(strengthScore);
    final Color strengthColor = _getStrengthColor(strengthScore);
    final AppColors colors = darkMode ? AppColors.dark : AppColors.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: strengthScore / 100,
              backgroundColor: darkMode ? colors.border : Colors.grey[300],
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
                'Độ mạnh: ',
                style: TextStyle(
                  color: darkMode ? colors.muted : Colors.grey[700],
                  fontSize: 12,
                ),
              ),
              Text(
                strengthText,
                style: TextStyle(
                  color: strengthColor,
                  fontSize: 12,
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
    if (score == 0) return 'Chưa nhập';
    if (score < 30) return 'Rất yếu';
    if (score < 50) return 'Yếu';
    if (score < 70) return 'Trung bình';
    if (score < 90) return 'Mạnh';
    return 'Rất mạnh';
  }

  Color _getStrengthColor(int score) {
    final AppColors colors = darkMode ? AppColors.dark : AppColors.light;
    if (score == 0) return darkMode ? colors.muted : Colors.grey;
    if (score < 30) return Colors.red;
    if (score < 50) return Colors.orange;
    if (score < 70) return Colors.yellow;
    if (score < 90) return Colors.lightGreen;
    return Colors.green;
  }
}

/// Password requirement checker widget
class _PasswordRequirementWidget extends StatelessWidget {
  final String password;
  final bool showTitle;
  final bool darkMode;

  const _PasswordRequirementWidget({
    required this.password,
    this.showTitle = false,
    this.darkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors colors = darkMode ? AppColors.dark : AppColors.light;

    final requirements = [
      {
        'text': 'Ít nhất 8 ký tự',
        'isMet': password.length >= 8,
      },
      {
        'text': 'Ít nhất 1 chữ hoa',
        'isMet': password.contains(RegExp(r'[A-Z]')),
      },
      {
        'text': 'Ít nhất 1 chữ thường',
        'isMet': password.contains(RegExp(r'[a-z]')),
      },
      {
        'text': 'Ít nhất 1 chữ số',
        'isMet': password.contains(RegExp(r'[0-9]')),
      },
      {
        'text': 'Ít nhất 1 ký tự đặc biệt',
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
            'Yêu cầu mật khẩu:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: darkMode ? colors.muted : Colors.grey[800],
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
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRequirement(String text, bool isMet, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            color: isMet
                ? Colors.green
                : darkMode
                    ? colors.muted
                    : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: isMet
                    ? Colors.green
                    : darkMode
                        ? colors.muted
                        : Colors.grey[700],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
