import 'package:flutter/material.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../widgets/auth/auth_widgets.dart';
import 'login_page.dart';
import 'email_verification_page.dart';
import 'package:logger/logger.dart';
import '../../../core/services/firestore/firestore_data_service.dart';
import '../../../core/models/user_model.dart';

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
  final FirestoreDataService _firestoreService = FirestoreDataService();
  
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
      
      // Call sign up without storing the return value
      await _authService.signUpWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
        name: name, // Pass name if provided
      );
      
      // Save additional user data to Firestore
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final userId = currentUser is String ? currentUser : currentUser.uid;
        final userEmail = _emailController.text.trim();
        
        // Create user model
        final userModel = UserModel(
          uid: userId,
          email: userEmail,
          name: name,
          createdAt: DateTime.now(),
          isEmailVerified: _authService.isEmailVerified(),
        );
        
        // Save to Firestore
        await _firestoreService.createOrUpdateUser(userModel);
      }
      
      if (!mounted) return;
      
      final email = _emailController.text.trim();
      
      // Clear form data for security
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      
      // Show different dialog content based on whether email verification is needed
      final bool needsVerification = !_authService.isUsingWindowsAuth();
      
      // Show success dialog with appropriate information
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
                if (needsVerification) ...[
                  Text('Email xác minh đã được gửi đến ${_maskEmail(email)}'),
                  const SizedBox(height: 12),
                  const Text('Lưu ý:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Text('• Vui lòng kiểm tra cả thư mục SPAM hoặc Junk Mail'),
                  const Text('• Email có thể mất vài phút để đến'),
                  const Text('• Liên kết xác minh có hiệu lực trong 24 giờ'),
                ] else ...[
                  Text('Tài khoản ${_maskEmail(email)} đã được tạo thành công'),
                  const SizedBox(height: 12),
                  const Text('Bạn có thể đăng nhập ngay bây giờ'),
                ],
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
              if (needsVerification)
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
            content: Text('Lỗi kết nối mạng. Vui lòng kiểm tra kết nối internet của bạn.'),
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
        child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    const Icon(
                      Icons.account_circle_outlined,
                      size: 80,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Tạo tài khoản mới',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    
                    // Name field (optional)
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Tên (tùy chọn)',
                        prefixIcon: const Icon(Icons.person),
                        errorText: _nameError,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Email field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email),
                        errorText: _emailError,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: _onEmailChanged,
                    ),
                    const SizedBox(height: 16),
                    
                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        prefixIcon: const Icon(Icons.lock),
                        errorText: _passwordError,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: _onPasswordChanged,
                    ),
                    const SizedBox(height: 8),
                    
                    // Password strength indicator
                    if (_passwordStrength.isNotEmpty)
                      Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AuthValidators.getPasswordStrengthColor(_passwordStrength),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Độ mạnh: $_passwordStrength',
                            style: TextStyle(
                              color: AuthValidators.getPasswordStrengthColor(_passwordStrength),
                            ),
                          ),
                        ],
                      ),
                    
                    if (_passwordStrength.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _getPasswordTip(_passwordStrength),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Confirm password field
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Xác nhận mật khẩu',
                        prefixIcon: const Icon(Icons.lock_outline),
                        errorText: _confirmPasswordError,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: _onConfirmPasswordChanged,
                    ),
                    const SizedBox(height: 30),
                    
                    // Sign up button
                    ElevatedButton(
                      onPressed: _signUp,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Đăng ký',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Already have account button
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginPage()),
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
        return 'Mật khẩu mạnh, đáp ứng các yêu cầu bảo mật';
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