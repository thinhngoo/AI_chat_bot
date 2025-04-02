import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../core/utils/validators/input_validator.dart';
import '../../../widgets/auth/auth_widgets.dart';
import '../../../widgets/auth/password_requirement_widget.dart';
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
  final TextEditingController _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  final Logger _logger = Logger();
  
  bool _isLoading = false;
  bool _isSuccess = false;
  
  // Add separate error messages for each field
  String? _nameErrorMessage;
  String? _emailErrorMessage;
  String? _passwordErrorMessage;
  String? _confirmPasswordErrorMessage;
  
  String _passwordStrength = '';

  @override
  void initState() {
    super.initState();
    _passwordStrength = InputValidator.getPasswordStrength('');
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
          _emailErrorMessage = 'Email đã được sử dụng. Vui lòng sử dụng email khác.';
          _isLoading = false;
        });
      } else if (errorMsg.contains('weak-password') || 
                 errorMsg.contains('mật khẩu')) {
        setState(() {
          _passwordErrorMessage = 'Mật khẩu quá yếu. Vui lòng chọn mật khẩu mạnh hơn.';
          _isLoading = false;
        });
      } else if (errorMsg.contains('network')) {
        setState(() {
          _confirmPasswordErrorMessage = 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối internet của bạn.';
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'AI Chat Bot',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                _isSuccess 
                    ? _buildSuccessCard()
                    : _buildSignupCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignupCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Đăng ký tài khoản',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Họ và tên',
                hintText: 'Nhập họ và tên của bạn',
                prefixIcon: const Icon(Icons.person),
                border: const OutlineInputBorder(),
                errorText: _nameErrorMessage,
              ),
              onChanged: (_) => setState(() => _nameErrorMessage = null),
            ),
            const SizedBox(height: 16),
            EmailField(
              controller: _emailController,
              errorText: _emailErrorMessage,
              onChanged: (_) => setState(() => _emailErrorMessage = null),
            ),
            const SizedBox(height: 16),
            PasswordField(
              controller: _passwordController,
              labelText: 'Mật khẩu',
              errorText: _passwordErrorMessage,
              onChanged: (value) {
                setState(() {
                  _passwordStrength = InputValidator.getPasswordStrength(value);
                  _passwordErrorMessage = null;
                });
              },
            ),
            Text(
              'Độ mạnh: $_passwordStrength',
              style: TextStyle(
                color: InputValidator.getPasswordStrengthColor(_passwordStrength),
              ),
            ),
            const SizedBox(height: 8),
            PasswordRequirementWidget(
              password: _passwordController.text,
              showTitle: true,
            ),
            const SizedBox(height: 16),
            PasswordField(
              controller: _confirmPasswordController,
              labelText: 'Xác nhận mật khẩu',
              errorText: _confirmPasswordErrorMessage,
              onChanged: (_) => setState(() => _confirmPasswordErrorMessage = null),
              onSubmit: _signup,
            ),
            const SizedBox(height: 24),
            SubmitButton(
              label: 'Đăng ký',
              onPressed: _signup,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Đã có tài khoản?'),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
                  child: const Text('Đăng nhập ngay'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
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
            const Text(
              'Đăng ký thành công!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Tài khoản ${_emailController.text} đã được tạo thành công.',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
              ),
              child: const Text('Đăng nhập ngay'),
            ),
          ],
        ),
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