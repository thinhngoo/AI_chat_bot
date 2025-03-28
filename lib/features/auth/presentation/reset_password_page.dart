import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../core/utils/validators/password_validator.dart';
import '../../../widgets/auth/auth_widgets.dart';
import '../../../widgets/auth/password_requirement_widget.dart';
import 'login_page.dart';

class ResetPasswordPage extends StatefulWidget {
  final String code;
  
  const ResetPasswordPage({
    super.key,
    required this.code,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
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

  Future<void> _resetPassword() async {
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
      _logger.i('Attempting to reset password with code: ${widget.code}');
      
      // Call auth service to confirm password reset
      await _authService.confirmPasswordReset(
        widget.code,
        _passwordController.text,
      );
      
      if (!mounted) return;
      
      _logger.i('Password reset successful');
      
      setState(() {
        _isSuccess = true;
        _isLoading = false;
      });
    } catch (e) {
      _logger.e('Password reset error: $e');
      
      if (!mounted) return;
      
      String errorMsg;
      
      // Check for common API errors
      if (e.toString().contains('expired-action-code')) {
        errorMsg = 'Liên kết đặt lại mật khẩu đã hết hạn';
      } else if (e.toString().contains('invalid-action-code')) {
        errorMsg = 'Liên kết đặt lại mật khẩu không hợp lệ';
      } else if (e.toString().contains('network')) {
        errorMsg = 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối internet của bạn.';
      } else {
        // Use a more user-friendly error message
        errorMsg = 'Không thể đặt lại mật khẩu: ${e.toString()}';
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
    
    // Validate password
    if (_passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập mật khẩu mới';
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
      appBar: AppBar(
        title: const Text('Đặt lại mật khẩu'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isSuccess ? _buildSuccessContent() : _buildResetContent(),
      ),
    );
  }

  Widget _buildResetContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Tạo mật khẩu mới',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Mật khẩu mới phải khác với mật khẩu cũ và đáp ứng các yêu cầu bảo mật.',
          style: TextStyle(
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 24),
        PasswordField(
          controller: _passwordController,
          labelText: 'Mật khẩu mới',
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
          labelText: 'Xác nhận mật khẩu mới',
          errorText: _errorMessage,
          onChanged: (_) => setState(() => _errorMessage = null),
          onSubmit: _resetPassword,
        ),
        const SizedBox(height: 24),
        SubmitButton(
          label: 'Đặt lại mật khẩu',
          onPressed: _resetPassword,
          isLoading: _isLoading,
        ),
      ],
    );
  }

  Widget _buildSuccessContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.check_circle_outline,
          size: 72,
          color: Colors.green,
        ),
        const SizedBox(height: 24),
        const Text(
          'Đặt lại mật khẩu thành công',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          'Mật khẩu của bạn đã được đặt lại thành công. Bạn có thể đăng nhập bằng mật khẩu mới.',
          style: TextStyle(
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginPage(),
              ),
              (route) => false,
            );
          },
          child: const Text('Đăng nhập ngay'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
