import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Add import for dotenv
import '../../../core/services/auth/auth_service.dart';
import '../../../widgets/auth/auth_widgets.dart';
import '../../../features/chat/presentation/home_page.dart';
import 'signup_page.dart';
import 'email_verification_page.dart';
import 'package:logger/logger.dart';
import '../../../core/utils/errors/error_utils.dart';
import '../../../core/services/platform/platform_service_helper.dart';
import 'google_auth_handler_page.dart';

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
  String? _generalErrorMessage;
  
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
    
    // Log that login page was reached
    _logger.i('LoginPage initialized');
    
    // Check if Firebase is properly initialized
    Future.delayed(Duration.zero, () {
      _checkFirebaseStatus();
    });
  }
  
  void _checkFirebaseStatus() async {
    final firebaseInitialized = _authService.isFirebaseInitialized();
    
    if (!firebaseInitialized) {
      _logger.w('Firebase is not properly initialized. Some features may not work.');
      
      // Only show warning on Windows platform since that's where we expect Firebase
      if (PlatformServiceHelper.isDesktopWindows) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Firebase không được khởi tạo đúng cách. Một số tính năng có thể không hoạt động.'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  bool _validateForm() {
    bool isValid = true;
    
    setState(() {
      _generalErrorMessage = null; // Clear any general error message
      
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
    // Clear any previous general error
    setState(() {
      _generalErrorMessage = null;
    });
    
    // Check for rate limiting
    if (_failedAttempts >= 5) {
      setState(() {
        _generalErrorMessage = 'Quá nhiều lần đăng nhập thất bại. Vui lòng thử lại sau.';
      });
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
      
      // Use our utility class to get a friendly error message
      final errorInfo = ErrorUtils.getAuthErrorInfo(e.toString());
      
      setState(() {
        _generalErrorMessage = errorInfo.message;
        
        // If the error is related to a specific field, set that field's error
        if (errorInfo.field == 'email') {
          _emailError = errorInfo.message;
        } else if (errorInfo.field == 'password') {
          _passwordError = errorInfo.message;
        }
      });
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
      // First check if we're on Windows and log the platform information
      _logger.i('Current platform info: ${PlatformServiceHelper.getPlatformInfo()}');
      
      // On Windows, we need special handling for Google Sign-In
      if (PlatformServiceHelper.isDesktopWindows) {
        // Display instructions before launching browser
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Launching automatic Google Sign-In...'),
            duration: Duration(seconds: 2),
          ),
        );
        
        // Check if Firebase is properly configured
        _validateFirebaseConfig();
        
        // For Windows, we'll use our automated OAuth handler
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const GoogleAuthHandlerPage(
              initialAuthUrl: "Automatic authentication will begin shortly...",
              autoStartAuth: true,
            ),
          ),
        );
        return;
      } 
      
      // For non-Windows platforms, use the regular flow
      try {
        await _authService.signInWithGoogle();
        
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } catch (e) {
        _logger.i('Caught error in Google Sign-In: ${e.toString()}');
        
        // Important: Check for plugin_not_supported with exact string comparison
        if (e.toString() == 'plugin_not_supported') {
          _logger.i('Google Sign-In plugin not available, using fallback auth flow');
          
          // Use our custom authentication flow
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const GoogleAuthHandlerPage(
                  initialAuthUrl: "Automatic authentication will begin shortly...",
                  autoStartAuth: true,
                ),
              ),
            );
          }
          return; // Add explicit return to prevent executing error handling code
        }
        
        // Re-throw for other errors to be handled by the outer catch block
        rethrow;
      }
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
      } else if (e.toString().contains('MissingPluginException')) {
        errorMessage = 'Google Sign-In không được hỗ trợ trên thiết bị này. Đang chuyển sang phương thức thay thế...';
        
        // Store context before async gap
        if (mounted) {
          final BuildContext currentContext = context;
          
          // Schedule navigation after current build is complete
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.push(
                currentContext,
                MaterialPageRoute(
                  builder: (context) => const GoogleAuthHandlerPage(
                    initialAuthUrl: "Automatic authentication will begin shortly...",
                    autoStartAuth: true,
                  ),
                ),
              );
            }
          });
        }
        return;
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
  
  // Add method to validate Firebase configuration
  void _validateFirebaseConfig() {
    // Check for required environment variables
    final desktopClientId = dotenv.env['GOOGLE_DESKTOP_CLIENT_ID'];
    if (desktopClientId == null || desktopClientId.isEmpty) {
      _logger.w('GOOGLE_DESKTOP_CLIENT_ID is missing in .env file. '
          'Google Sign-In might not work correctly on Windows.');
    }
    
    final clientSecret = dotenv.env['GOOGLE_CLIENT_SECRET']; 
    if (clientSecret == null || clientSecret.isEmpty) {
      _logger.w('GOOGLE_CLIENT_SECRET is missing in .env file. '
          'Google Sign-In might not work correctly on Windows.');
    }
    
    _logger.i('Reminder: For Firebase to accept the Google Sign-In credential, '
        'the desktop client ID must be added to Firebase Console > Authentication > '
        'Sign-in method > Google > Web SDK configuration');
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
                    
                    // Show general error message if there is one
                    if (_generalErrorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _generalErrorMessage!,
                                style: TextStyle(color: Colors.red.shade800),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
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