import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../core/utils/errors/error_utils.dart';
import '../../../core/utils/validators/password_validator.dart'; // Import the validator
import 'login_page.dart';
import '../../../widgets/auth/password_requirement_widget.dart'; // Import the widget

class ResetPasswordPage extends StatefulWidget {
  final String resetCode;
  final String email;
  
  const ResetPasswordPage({
    super.key,
    required this.resetCode,
    required this.email,
  });

  @override
  State<ResetPasswordPage> createState() => ResetPasswordPageState();
}

class ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  final Logger _logger = Logger();
  
  bool _isLoading = false;
  String? _errorMessage;
  String _passwordStrength = '';
  bool _passwordsMatch = true;

  @override
  void initState() {
    super.initState();
    _logger.i('Reset password page initialized with code: ${widget.resetCode.substring(0, 5)}...');
  }

  void _updatePasswordCriteria(String password) {
    setState(() {
      _passwordStrength = PasswordValidator.getPasswordStrength(password);
    });
  }

  void _updatePasswordMatch() {
    setState(() {
      _passwordsMatch = _passwordController.text == _confirmPasswordController.text;
    });
  }

  Future<void> _resetPassword() async {
    // Clear any previous error
    setState(() {
      _errorMessage = null;
    });

    // First check if form is valid
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Mật khẩu nhập lại không khớp';
      });
      return;
    }

    // Validate password strength
    if (!PasswordValidator.isValidPassword(_passwordController.text)) {
      setState(() {
        _errorMessage = 'Mật khẩu không đủ mạnh. Vui lòng đảm bảo đáp ứng tất cả các yêu cầu.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Confirm the password reset
      await _authService.confirmPasswordReset(
        widget.resetCode, 
        _passwordController.text
      );

      if (!mounted) return;

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Đặt lại mật khẩu thành công'),
          content: const Text('Mật khẩu của bạn đã được cập nhật. Bạn có thể đăng nhập bằng mật khẩu mới.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to login page
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              },
              child: const Text('Đăng nhập ngay'),
            ),
          ],
        ),
      );
    } catch (e) {
      _logger.e('Error resetting password: $e');
      
      if (!mounted) return;
      
      // Get friendly error message
      final errorInfo = ErrorUtils.getAuthErrorInfo(e.toString());
      
      setState(() {
        _errorMessage = errorInfo.message;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt lại mật khẩu'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 4.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Tạo mật khẩu mới',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Đặt lại mật khẩu cho ${widget.email}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Mật khẩu mới',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mật khẩu mới';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        _updatePasswordCriteria(value);
                        _updatePasswordMatch();
                      },
                    ),
                    
                    const SizedBox(height: 8),
                    
                    if (_passwordController.text.isNotEmpty) ...[
                      Row(
                        children: [
                          const Text('Độ mạnh: '),
                          Text(
                            _passwordStrength,
                            style: TextStyle(
                              color: PasswordValidator.getPasswordStrengthColor(_passwordStrength),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Xác nhận mật khẩu',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline),
                        errorText: !_passwordsMatch && _confirmPasswordController.text.isNotEmpty
                            ? 'Mật khẩu không khớp'
                            : null,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng xác nhận mật khẩu';
                        }
                        if (value != _passwordController.text) {
                          return 'Mật khẩu không khớp';
                        }
                        return null;
                      },
                      onChanged: (_) => _updatePasswordMatch(),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    PasswordRequirementWidget(
                      password: _passwordController.text,
                      showTitle: true,
                    ),
                    
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _resetPassword,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : const Text('Đặt lại mật khẩu', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => const LoginPage()),
                        );
                      },
                      child: const Text('Quay lại đăng nhập'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
