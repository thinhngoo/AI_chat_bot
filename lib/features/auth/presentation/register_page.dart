import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../core/utils/validators/password_validator.dart';
import '../../../widgets/auth/auth_widgets.dart';
import '../../../widgets/auth/password_requirement_widget.dart';
import 'email_verification_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final AuthService _authService = AuthService();
  final Logger _logger = Logger();
  
  bool _isLoading = false;
  String? _errorMessage;
  String _passwordStrength = '';
  double _passwordStrengthScore = 0.0;
  bool _acceptTerms = false;
  
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
    });
  }
  
  bool _validateForm() {
    // Reset error messages
    setState(() {
      _errorMessage = null;
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
        _errorMessage = 'Mật khẩu xác nhận không khớp';
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

  Future<void> _register() async {
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
      _logger.i('Attempting to register user: ${_emailController.text}');
      
      // Get name if entered
      final name = _nameController.text.trim();
      
      // Call auth service to register
      await _authService.signUpWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
        name: name.isNotEmpty ? name : null
      );
      
      if (!mounted) return;
      
      _logger.i('Registration successful, proceeding to verification screen');
      
      // Navigate to email verification page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => EmailVerificationPage(
            email: _emailController.text.trim(),
          ),
        ),
      );
    } catch (e) {
      _logger.e('Registration error: $e');
      
      if (!mounted) return;
      
      String errorMsg;
      
      // Check for common API errors
      if (e.toString().contains('already exists') || 
          e.toString().contains('already in use') ||
          e.toString().toLowerCase().contains('already registered')) {
        errorMsg = 'Email đã được đăng ký. Vui lòng sử dụng email khác hoặc đăng nhập.';
      } else if (e.toString().contains('network') || e.toString().contains('connect')) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký tài khoản'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
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
                onChanged: (_) => setState(() => _errorMessage = null),
              ),
              const SizedBox(height: 16),
              
              // Password requirements widget
              PasswordRequirementWidget(
                password: _passwordController.text,
                showTitle: true,
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
                onPressed: _register,
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
