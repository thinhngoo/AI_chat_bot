import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../core/utils/validators/password_validator.dart';
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
  String? _errorMessage;
  String _passwordStrength = '';

  @override
  void initState() {
    super.initState();
    _passwordStrength = PasswordValidator.getPasswordStrength('');
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
      _errorMessage = null;
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
      
      String errorMsg;
      
      // Convert error message to user-friendly text
      if (e.toString().contains('Email đã được sử dụng') ||
          e.toString().contains('already exists')) {
        errorMsg = 'Email đã được sử dụng. Vui lòng sử dụng email khác.';
      } else if (e.toString().contains('weak-password')) {
        errorMsg = 'Mật khẩu quá yếu. Vui lòng chọn mật khẩu mạnh hơn.';
      } else if (e.toString().contains('network')) {
        errorMsg = 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối internet của bạn.';
      } else {
        // Use a more user-friendly error message
        errorMsg = 'Lỗi đăng ký: ${e.toString()}';
      }
      
      setState(() {
        _errorMessage = errorMsg;
        _isLoading = false;
      });
    }
  }

  bool _validateForm() {
    setState(() {
      _errorMessage = null;
    });
    
    // Validate name
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập tên của bạn';
      });
      return false;
    }
    
    // Validate email
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập email';
      });
      return false;
    }
    
    if (!PasswordValidator.isValidEmail(_emailController.text.trim())) {
      setState(() {
        _errorMessage = 'Email không hợp lệ';
      });
      return false;
    }
    
    // Validate password
    if (_passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập mật khẩu';
      });
      return false;
    }
    
    if (!PasswordValidator.isValidPassword(_passwordController.text)) {
      setState(() {
        _errorMessage = 'Mật khẩu không đáp ứng các yêu cầu bảo mật';
      });
      return false;
    }
    
    // Validate confirm password
    if (_confirmPasswordController.text != _passwordController.text) {
      setState(() {
        _errorMessage = 'Mật khẩu xác nhận không khớp';
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
              decoration: const InputDecoration(
                labelText: 'Họ và tên',
                hintText: 'Nhập họ và tên của bạn',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() => _errorMessage = null),
            ),
            const SizedBox(height: 16),
            EmailField(
              controller: _emailController,
              onChanged: (_) => setState(() => _errorMessage = null),
            ),
            const SizedBox(height: 16),
            PasswordField(
              controller: _passwordController,
              labelText: 'Mật khẩu',
              onChanged: (value) {
                setState(() {
                  _passwordStrength = PasswordValidator.getPasswordStrength(value);
                  _errorMessage = null;
                });
              },
            ),
            Text(
              'Độ mạnh: $_passwordStrength',
              style: TextStyle(
                color: PasswordValidator.getPasswordStrengthColor(_passwordStrength),
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
              errorText: _errorMessage,
              onChanged: (_) => setState(() => _errorMessage = null),
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
              child: const Text('Đăng nhập ngay'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
              ),
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