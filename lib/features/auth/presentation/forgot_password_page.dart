import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../core/utils/errors/error_utils.dart';
import '../../../widgets/auth/auth_widgets.dart';
import 'login_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ForgotPasswordPageState createState() => ForgotPasswordPageState();
}

class ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  final Logger _logger = Logger();
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _resetEmailSent = false;

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    
    // Basic validation
    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập địa chỉ email';
      });
      return;
    }
    
    if (!_isValidEmail(email)) {
      setState(() {
        _errorMessage = 'Vui lòng nhập địa chỉ email hợp lệ';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      await _authService.sendPasswordResetEmail(email);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _resetEmailSent = true;
        });
      }
      
      _logger.i('Password reset email sent to $email');
    } catch (e) {
      final error = ErrorUtils.getAuthErrorInfo(e.toString());
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = error.message;
        });
      }
      
      _logger.e('Failed to send password reset email: $e');
    }
  }

  bool _isValidEmail(String email) {
    final emailRegExp = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
    return emailRegExp.hasMatch(email);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quên mật khẩu'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
              child: _resetEmailSent ? _buildSuccessContent() : _buildResetForm(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResetForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Đặt lại mật khẩu',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'Nhập địa chỉ email của bạn để nhận liên kết đặt lại mật khẩu',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email),
          ),
          onChanged: (_) {
            if (_errorMessage != null) {
              setState(() {
                _errorMessage = null;
              });
            }
          },
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
        
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _resetPassword,
            child: _isLoading 
              ? const CircularProgressIndicator()
              : const Text('Gửi liên kết đặt lại'),
          ),
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
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            child: const Text('Quay lại đăng nhập'),
          ),
        ),
      ],
    );
  }
}
