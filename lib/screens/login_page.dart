import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/auth_widgets.dart';
import 'home_page.dart';
import 'signup_page.dart';
import 'email_verification_page.dart';
import 'package:logger/logger.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final Logger _logger = Logger();
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;
  int _failedAttempts = 0;
  
  @override
  void initState() {
    super.initState();
    // Reset failed attempts count after 30 minutes
    Future.delayed(const Duration(minutes: 30), () {
      if (mounted) {
        setState(() {
          _failedAttempts = 0;
        });
      }
    });
  }

  bool _validateForm() {
    bool isValid = true;
    
    setState(() {
      // Validate email
      if (!AuthValidators.isValidEmail(_emailController.text.trim())) {
        _emailError = 'Vui lòng nhập email hợp lệ';
        isValid = false;
      } else {
        _emailError = null;
      }
      
      // Validate password (simple check for emptiness)
      if (_passwordController.text.isEmpty) {
        _passwordError = 'Vui lòng nhập mật khẩu';
        isValid = false;
      } else {
        _passwordError = null;
      }
    });
    
    return isValid;
  }

  Future<void> _signIn() async {
    // Check for rate limiting
    if (_failedAttempts >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quá nhiều lần đăng nhập thất bại. Vui lòng thử lại sau.')),
      );
      return;
    }
    
    if (!_validateForm()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      if (!mounted) return;
      
      // Reset failed attempts on success
      setState(() {
        _failedAttempts = 0;
      });
      
      // Check if email is verified
      if (_authService.isEmailVerified()) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        // Navigate to verification page with email
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EmailVerificationPage(
              email: _emailController.text.trim(),
            ),
          ),
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng xác minh email của bạn trước khi đăng nhập')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      // Increment failed attempts
      setState(() {
        _failedAttempts++;
      });
      
      _logger.e('Login error: $e');
      
      // Provide friendly error messages based on error type
      String errorMessage = 'Đăng nhập thất bại';
      
      if (e.toString().contains('user-not-found') || 
          e.toString().contains('Tài khoản không tồn tại')) {
        errorMessage = 'Email không tồn tại trong hệ thống';
      } else if (e.toString().contains('wrong-password') || 
                e.toString().contains('Mật khẩu không đúng')) {
        errorMessage = 'Mật khẩu không chính xác';
      } else if (e.toString().contains('too-many-requests')) {
        errorMessage = 'Quá nhiều yêu cầu. Vui lòng thử lại sau';
      } else if (e.toString().contains('network-request-failed')) {
        errorMessage = 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối internet';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          action: e.toString().contains('network-request-failed') 
              ? SnackBarAction(
                  label: 'Thử lại',
                  onPressed: _signIn,
                ) 
              : null,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập email để đặt lại mật khẩu')),
      );
      return;
    }
    
    if (!AuthValidators.isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email không hợp lệ')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _authService.sendPasswordResetEmail(email);
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Đặt lại mật khẩu'),
          content: Text('Link đặt lại mật khẩu đã được gửi đến $email'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      _logger.e('Password reset error: $e');
      
      String errorMessage = 'Không thể gửi email đặt lại mật khẩu';
      
      if (e.toString().contains('user-not-found')) {
        errorMessage = 'Không tìm thấy tài khoản với email này';
      } else if (e.toString().contains('network-request-failed')) {
        errorMessage = 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối internet';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _authService.signInWithGoogle();
      
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } catch (e) {
      if (!mounted) return;
      
      _logger.e('Google sign-in error: $e');
      
      String errorMessage = 'Đăng nhập với Google thất bại';
      
      if (e.toString().contains('không được hỗ trợ')) {
        errorMessage = 'Đăng nhập với Google không được hỗ trợ trên thiết bị này';
      } else if (e.toString().contains('network-request-failed')) {
        errorMessage = 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối internet';
      } else if (e.toString().contains('sign_in_canceled')) {
        errorMessage = 'Đăng nhập đã bị hủy';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _onEmailChanged(String value) {
    if (_emailError != null) {
      setState(() {
        if (AuthValidators.isValidEmail(value.trim())) {
          _emailError = null;
        } else {
          _emailError = 'Vui lòng nhập email hợp lệ';
        }
      });
    }
  }
  
  void _onPasswordChanged(String value) {
    if (_passwordError != null) {
      setState(() {
        if (value.isNotEmpty) {
          _passwordError = null;
        } else {
          _passwordError = 'Vui lòng nhập mật khẩu';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập')),
      body: AbsorbPointer(
        absorbing: _isLoading,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    const SizedBox(height: 30),
                    const Icon(
                      Icons.account_circle,
                      size: 80,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Chào mừng trở lại!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    EmailField(
                      controller: _emailController,
                      errorText: _emailError,
                      onChanged: _onEmailChanged,
                    ),
                    const SizedBox(height: 10),
                    PasswordField(
                      controller: _passwordController,
                      errorText: _passwordError,
                      onChanged: _onPasswordChanged,
                    ),
                    const SizedBox(height: 20),
                    SubmitButton(
                      label: 'Đăng nhập',
                      onPressed: _signIn,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _resetPassword,
                      child: const Text('Quên mật khẩu?'),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Hoặc',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GoogleSignInButton(onPressed: _signInWithGoogle),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SignUpPage()),
                        );
                      },
                      child: const Text('Chưa có tài khoản? Đăng ký ngay'),
                    ),
                  ],
                ),
              ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}