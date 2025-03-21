import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/auth_widgets.dart';  // Keep this import
import 'login_page.dart';
import 'email_verification_page.dart';
import 'package:logger/logger.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  SignUpPageState createState() => SignUpPageState();
}

class SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(); // New name controller
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  final Logger _logger = Logger();
  
  bool _isLoading = false;
  String _passwordStrength = '';
  String? _nameError; // For name validation
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    _passwordStrength = AuthValidators.getPasswordStrength('');
  }

  bool _validateForm() {
    bool isValid = true;
    
    setState(() {
      // Validate name (optional)
      if (_nameController.text.isNotEmpty && _nameController.text.length < 2) {
        _nameError = 'Tên cần ít nhất 2 ký tự';
        isValid = false;
      } else {
        _nameError = null;
      }
      
      // Validate email
      if (!AuthValidators.isValidEmail(_emailController.text.trim())) {
        _emailError = 'Vui lòng nhập email hợp lệ';
        isValid = false;
      } else {
        _emailError = null;
      }
      
      // Validate password
      if (!AuthValidators.isValidPassword(_passwordController.text)) {
        _passwordError = 'Mật khẩu cần có ít nhất 8 ký tự, bao gồm chữ hoa, chữ thường, số và ký tự đặc biệt';
        isValid = false;
      } else {
        _passwordError = null;
      }
      
      // Validate confirm password
      if (_passwordController.text != _confirmPasswordController.text) {
        _confirmPasswordError = 'Mật khẩu không khớp';
        isValid = false;
      } else {
        _confirmPasswordError = null;
      }
    });
    
    return isValid;
  }

  Future<void> _signUp() async {
    if (!_validateForm()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final name = _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null;
      
      await _authService.signUpWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
        name: name, // Pass name if provided
      );
      
      if (!mounted) return;
      
      final email = _emailController.text.trim();
      
      // Clear form data for security
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      
      // Show success dialog with more information
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Đăng ký thành công!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fix the string interpolation issue by rewriting it
                Text("Email xác minh đã được gửi đến ${_maskEmail(email)}"),
                const SizedBox(height: 12),
                const Text('Lưu ý:', style: TextStyle(fontWeight: FontWeight.bold)),
                const Text('• Vui lòng kiểm tra cả thư mục SPAM hoặc Junk Mail'),
                const Text('• Email có thể mất vài phút để đến'),
                const Text('• Liên kết xác minh có hiệu lực trong 24 giờ'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                child: const Text('Đăng nhập'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => EmailVerificationPage(email: email)),
                  );
                },
                child: const Text('Đi đến trang xác minh'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      
      _logger.e('Signup error: $e');
      
      String errorMessage;
      if (e.toString().contains('Email already exists') || 
          e.toString().contains('email-already-in-use')) {
        errorMessage = 'Email đã được sử dụng bởi tài khoản khác';
      } else if (e.toString().contains('weak-password')) {
        errorMessage = 'Mật khẩu quá yếu. Vui lòng chọn mật khẩu mạnh hơn';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'Email không hợp lệ';
      } else if (e.toString().contains('network-request-failed')) {
        errorMessage = 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối internet';
        // Show retry button for network errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            action: SnackBarAction(
              label: 'Thử lại',
              onPressed: _signUp,
            ),
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      } else {
        errorMessage = 'Đã xảy ra lỗi khi đăng ký. Vui lòng thử lại.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _passwordStrength = '';
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
    setState(() {
      _passwordStrength = AuthValidators.getPasswordStrength(value);
      
      if (_passwordError != null) {
        if (AuthValidators.isValidPassword(value)) {
          _passwordError = null;
        } else {
          _passwordError = 'Mật khẩu cần có ít nhất 8 ký tự, bao gồm chữ hoa, chữ thường, số và ký tự đặc biệt';
        }
      }
      
      // Also update confirm password error if needed
      if (_confirmPasswordError != null && _confirmPasswordController.text == value) {
        _confirmPasswordError = null;
      }
    });
  }
  
  void _onConfirmPasswordChanged(String value) {
    if (_confirmPasswordError != null || value == _passwordController.text) {
      setState(() {
        if (value == _passwordController.text) {
          _confirmPasswordError = null;
        } else {
          _confirmPasswordError = 'Mật khẩu không khớp';
        }
      });
    }
  }
  
  // Helper method to mask email for privacy
  String _maskEmail(String email) {
    if (email.isEmpty || !email.contains('@')) return email;
    
    final atIndex = email.indexOf('@');
    final name = email.substring(0, atIndex);
    final domain = email.substring(atIndex);
    
    if (name.length <= 2) return email;
    
    return '${name.substring(0, 2)}${'*' * (name.length - 2)}$domain';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký')),
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
                    const SizedBox(height: 20),
                    const Text(
                      'Tạo Tài Khoản Mới',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    
                    // Add name field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Họ tên (không bắt buộc)',
                        hintText: 'Nhập tên của bạn',
                        errorText: _nameError,
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    EmailField(
                      controller: _emailController,
                      errorText: _emailError,
                      onChanged: _onEmailChanged,
                    ),
                    const SizedBox(height: 16),
                    PasswordField(
                      controller: _passwordController,
                      errorText: _passwordError,
                      onChanged: _onPasswordChanged,
                    ),
                    
                    // Password strength indicator
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Độ mạnh mật khẩu: ',
                                style: TextStyle(fontSize: 12),
                              ),
                              Text(
                                _passwordStrength,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AuthValidators.getPasswordStrengthColor(_passwordStrength),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: AuthValidators.getPasswordStrengthRatio(_passwordStrength),
                            color: AuthValidators.getPasswordStrengthColor(_passwordStrength),
                          ),
                          // Password tips
                          if (_passwordStrength != 'Mạnh' && _passwordStrength != 'Trống') ...[
                            const SizedBox(height: 5),
                            Text(
                              _getPasswordTip(_passwordStrength),
                              style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                            ),
                          ]
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    PasswordField(
                      controller: _confirmPasswordController,
                      labelText: 'Xác nhận mật khẩu',
                      errorText: _confirmPasswordError,
                      onChanged: _onConfirmPasswordChanged,
                    ),
                    const SizedBox(height: 24),
                    // Fix the callback type issue by using a synchronous function
                    SubmitButton(
                      label: 'Đăng ký',
                      onPressed: () => _signUp(),
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginPage())
                        );
                      },
                      child: const Text('Đã có tài khoản? Đăng nhập ngay'),
                    ),
                  ],
                ),
              ),
        ),
      ),
    );
  }
  
  String _getPasswordTip(String strength) {
    switch (strength) {
      case 'Rất yếu':
        return 'Mật khẩu nên có ít nhất 8 ký tự với chữ hoa, chữ thường, số và ký tự đặc biệt';
      case 'Yếu':
        return 'Mật khẩu cần dài hơn (ít nhất 8 ký tự)';
      case 'Trung bình (thêm chữ hoa)':
        return 'Thêm ít nhất một chữ hoa (A-Z)';
      case 'Trung bình (thêm chữ thường)':
        return 'Thêm ít nhất một chữ thường (a-z)';
      case 'Trung bình (thêm số)':
        return 'Thêm ít nhất một chữ số (0-9)';
      case 'Khá (thêm ký tự đặc biệt)':
        return r'Thêm ít nhất một ký tự đặc biệt (!@#$%^&*...)';
      default:
        return '';
    }
  }
  
  @override
  void dispose() {
    // Clear sensitive data
    _nameController.dispose(); // Dispose the new controller
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}