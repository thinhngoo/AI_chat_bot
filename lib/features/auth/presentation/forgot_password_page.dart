import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../core/utils/validators/password_validator.dart';
import '../../../widgets/auth/auth_widgets.dart';
import 'login_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  final Logger _logger = Logger();
  
  bool _isLoading = false;
  bool _isSuccess = false;
  String? _errorMessage;

  Future<void> _resetPassword() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();
    
    // Validate email
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập email';
      });
      return;
    }
    
    if (!PasswordValidator.isValidEmail(_emailController.text.trim())) {
      setState(() {
        _errorMessage = 'Email không hợp lệ';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      _logger.i('Sending password reset email to: ${_emailController.text}');
      
      // Call auth service to send password reset email
      await _authService.sendPasswordResetEmail(_emailController.text.trim());
      
      if (!mounted) return;
      
      _logger.i('Password reset email sent successfully');
      
      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });
    } catch (e) {
      _logger.e('Error sending password reset email: $e');
      
      if (!mounted) return;
      
      String errorMsg;
      
      // Check for common API errors
      if (e.toString().contains('user not found') || 
          e.toString().contains('not found') ||
          e.toString().contains('no user')) {
        errorMsg = 'Không tìm thấy tài khoản với email này. Vui lòng kiểm tra lại email.';
      } else if (e.toString().contains('network') || e.toString().contains('connect')) {
        errorMsg = 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối internet của bạn.';
      } else if (e.toString().contains('Not implemented')) {
        errorMsg = 'Tính năng này hiện không khả dụng với Jarvis API. Vui lòng liên hệ quản trị viên để được hỗ trợ.';
      } else {
        // Use a more user-friendly error message
        errorMsg = 'Đã xảy ra lỗi: ${e.toString()}';
      }
      
      setState(() {
        _errorMessage = errorMsg;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quên mật khẩu'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: _isSuccess ? _buildSuccessContent() : _buildRequestContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Khôi phục mật khẩu',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Nhập địa chỉ email của bạn để nhận liên kết đặt lại mật khẩu',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        
        EmailField(
          controller: _emailController,
          onChanged: (_) => setState(() => _errorMessage = null),
        ),
        
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ],
        
        const SizedBox(height: 24),
        
        SubmitButton(
          label: 'Gửi liên kết đặt lại',
          onPressed: _resetPassword,
          isLoading: _isLoading,
        ),
        
        const SizedBox(height: 16),
        
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Quay lại đăng nhập'),
        ),
      ],
    );
  }

  Widget _buildSuccessContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.check_circle_outline,
          size: 80,
          color: Colors.green,
        ),
        const SizedBox(height: 24),
        const Text(
          'Email đặt lại mật khẩu đã được gửi!',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Chúng tôi đã gửi liên kết đặt lại mật khẩu tới ${_emailController.text}. '
          'Vui lòng kiểm tra hộp thư đến của bạn và làm theo hướng dẫn.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Nếu bạn không nhận được email, vui lòng kiểm tra hộp thư rác hoặc thử lại.',
          textAlign: TextAlign.center,
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
        
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Quay lại đăng nhập'),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
