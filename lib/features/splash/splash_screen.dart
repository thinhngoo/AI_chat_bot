import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../core/services/auth/auth_service.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/main_screen.dart';
import '../../core/constants/app_colors.dart';

class SplashScreen extends StatefulWidget {
  final Function toggleTheme;

  const SplashScreen({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final Logger _logger = Logger();

  late AnimationController _animationController;
  late Animation<double> _animation;
  
  bool _isCheckingAuth = true;
  
  @override
  void initState() {
    super.initState();
    
    // Thiết lập animation logo
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _animationController.forward();
    
    // Khởi tạo dịch vụ xác thực trong nền
    _initializeAuthService();
    
    // Chuyển màn hình sau khi hoàn thành kiểm tra xác thực
    _checkAuthAndNavigate();
  }
  
  // Khởi tạo AuthService trong nền không chặn UI
  Future<void> _initializeAuthService() async {
    try {
      await _authService.initializeService();
      _logger.i('Auth service initialized successfully');
    } catch (e) {
      _logger.e('Error initializing auth service: $e');
    }
  }
  
  // Chuyển màn hình sau 1.5 giây hoặc khi kiểm tra xác thực xong
  Future<void> _checkAuthAndNavigate() async {
    try {
      // Đảm bảo hiển thị Splash ít nhất 1.5 giây
      await Future.delayed(const Duration(milliseconds: 1500));
      
      if (!mounted) return;
      
      // Đây là phần chính - kiểm tra xác thực
      bool isLoggedIn = await _authService.isLoggedIn();
      
      if (!mounted) return;
      
      setState(() {
        _isCheckingAuth = false;
      });
      
      // Chuyển hướng đến màn hình thích hợp dựa trên trạng thái đăng nhập
      if (isLoggedIn) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MainScreen(
              toggleTheme: widget.toggleTheme,
            ),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ),
        );
      }
    } catch (e) {
      _logger.e('Error during auth check: $e');
      
      if (!mounted) return;
      
      // Nếu có lỗi, chuyển đến màn hình đăng nhập
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
      );
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.dark;
    
    return Scaffold(
      backgroundColor: colors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.background,
              Color.fromARGB(255, 20, 20, 22),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo animation
              FadeTransition(
                opacity: _animation,
                child: ScaleTransition(
                  scale: _animation,
                  child: Icon(
                    Icons.smart_toy_outlined,
                    size: 100,
                    color: colors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // App title
              FadeTransition(
                opacity: _animation,
                child: Text(
                  'AI Chat Bot',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: colors.foreground,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Tagline
              FadeTransition(
                opacity: _animation,
                child: Text(
                  'Your intelligent companion',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                    color: colors.muted,
                  ),
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Loading indicator
              if (_isCheckingAuth)
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                  strokeWidth: 3,
                ),
            ],
          ),
        ),
      ),
    );
  }
}