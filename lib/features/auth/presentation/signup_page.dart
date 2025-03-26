import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../widgets/auth/auth_widgets.dart';
import '../../../core/utils/validators/password_validator.dart';
import '../../../widgets/auth/password_requirement_widget.dart';
import 'email_verification_page.dart';
import 'login_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  SignupPageState createState() => SignupPageState();
}

class SignupPageState extends State<SignupPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  final Logger _logger = Logger();
  
  bool _isLoading = false;
  String? _errorMessage;
  String? _confirmPasswordError;
  String _passwordStrength = '';
  double _passwordStrengthScore = 0.0;
  bool _acceptTerms = false;
  
  // Add the missing _passwordCriteria map
  Map<String, bool> _passwordCriteria = {
    'length': false,
    'uppercase': false,
    'lowercase': false,
    'number': false,
    'special': false,
  };
  
  @override
  void initState() {
    super.initState();
    _passwordStrength = 'Chưa nhập mật khẩu';
  }

  void _updatePasswordStrength(String password) {
    final strength = PasswordValidator.calculateStrength(password);
    setState(() {
      _passwordStrengthScore = strength;
      _passwordStrength = PasswordValidator.getStrengthText(strength);
      
      // Update password criteria
      _passwordCriteria = {
        'length': password.length >= 8,
        'uppercase': password.contains(RegExp(r'[A-Z]')),
        'lowercase': password.contains(RegExp(r'[a-z]')),
        'number': password.contains(RegExp(r'[0-9]')),
        'special': password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
      };
    });
  }
  
  bool _validateForm() {
    // Reset error messages
    setState(() {
      _errorMessage = null;
      _confirmPasswordError = null;
    });
    
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
    
    if (!PasswordValidator.meetsAllRequirements(_passwordController.text)) {
      final unmetRequirements = PasswordValidator.getUnmetRequirements(_passwordController.text);
      setState(() {
        _errorMessage = unmetRequirements.first;
      });
      return false;
    }
    
    // Validate password confirmation
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _confirmPasswordError = 'Mật khẩu xác nhận không khớp';
      });
      return false;
    }
    
    // Validate terms acceptance
    if (!_acceptTerms) {
      setState(() {
        _errorMessage = 'Vui lòng đồng ý với điều khoản dịch vụ';
      });
      return false;
    }
    
    return true;
  }

  Future<void> _signUp() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();
    
    // Validate form
    if (!_validateForm()) {
      return;
    }
    
    // Show loading indicator
    setState(() {
      _isLoading = true;
    });
    
    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      
      final result = await _authService.signUpWithEmailAndPassword(
        email, 
        password,
        name: name.isNotEmpty ? name : null,
      );
      
      if (!mounted) return;
      
      // Check if Firebase Auth is being used
      if (_authService.isUsingFirebaseAuth()) {
        // Navigate to email verification page
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => EmailVerificationPage(email: email),
          ),
        );
      } else {
        // For Windows auth, just show success and go back to login
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result)),
        );
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      String errorMessage = e.toString();
      if (errorMessage.contains('Email already exists')) {
        errorMessage = 'Email này đã được đăng ký';
      }
      
      setState(() {
        _errorMessage = errorMessage;
      });
      
      _logger.e('Signup error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký tài khoản'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: AuthCard(
            title: 'Tạo tài khoản mới',
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Họ tên (tùy chọn)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
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
                  _updatePasswordStrength(value);
                  setState(() => _errorMessage = null);
                },
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _passwordStrengthScore,
                backgroundColor: Colors.grey.shade200,
                color: PasswordValidator.getPasswordStrengthColor(_passwordStrength),
              ),
              const SizedBox(height: 4),
              Text(
                'Độ mạnh: $_passwordStrength',
                style: TextStyle(
                  color: PasswordValidator.getPasswordStrengthColor(_passwordStrength),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              PasswordField(
                controller: _confirmPasswordController,
                labelText: 'Xác nhận mật khẩu',
                errorText: _confirmPasswordError,
                onChanged: (_) => setState(() => _confirmPasswordError = null),
              ),
              const SizedBox(height: 16),
              
              // Password requirements widget
              PasswordRequirementWidget(
                password: _passwordController.text,
                showTitle: true,
                criteria: _passwordCriteria,
              ),
              
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _acceptTerms,
                    onChanged: (value) {
                      setState(() {
                        _acceptTerms = value ?? false;
                        if (_acceptTerms) {
                          _errorMessage = null;
                        }
                      });
                    },
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _acceptTerms = !_acceptTerms;
                        });
                      },
                      child: const Text(
                        'Tôi đồng ý với điều khoản dịch vụ và chính sách bảo mật',
                      ),
                    ),
                  ),
                ],
              ),
              
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
              
              const SizedBox(height: 24),
              SubmitButton(
                label: 'Đăng ký',
                onPressed: _signUp,
                isLoading: _isLoading,
              ),
              
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Đã có tài khoản?'),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Đăng nhập'),
                  ),
                ],
              ),
            ],
          ),
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