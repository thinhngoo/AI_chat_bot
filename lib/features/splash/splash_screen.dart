import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../core/services/auth/auth_service.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/main_screen.dart';
import '../../core/constants/app_colors.dart';
import '../auth/presentation/widgets/auth_background.dart';
import '../../features/bot/services/bot_service_wrapper.dart';
import '../../features/subscription/services/subscription_service_wrapper.dart';

class SplashScreen extends StatefulWidget {
  final Function toggleTheme;
  final Function setThemeMode;
  final String currentThemeMode;

  const SplashScreen({
    super.key, 
    required this.toggleTheme,
    required this.setThemeMode,
    required this.currentThemeMode,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final BotServiceWrapper _botService = BotServiceWrapper();
  final SubscriptionServiceWrapper _subscriptionService = SubscriptionServiceWrapper();
  final Logger _logger = Logger();

  late AnimationController _animationController;
  late Animation<double> _animation;
  
  // bool _isCheckingAuth = true;
  bool _dataPreloaded = false;
  
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
    // Prefetch data in background for faster app startup
  Future<void> _prefetchData() async {
    if (!mounted) return;
    try {
      // Only prefetch if user is logged in
      final isLoggedIn = await _authService.isLoggedIn();
      if (!isLoggedIn) return;
      
      _logger.i('Prefetching data in background...');
      
      // Prefetch both bots and subscription data in parallel
      Future.wait([
        _prefetchBots(),
        _prefetchSubscription(),
      ]).then((_) {
        if (mounted) {
          setState(() {
            _dataPreloaded = true;
          });
        }
      }).catchError((e) {
        _logger.e('Error in prefetch operations: $e');
      });
    } catch (e) {
      _logger.e('Error during prefetch: $e');
    }
  }
  
  Future<void> _prefetchBots() async {
    try {
      final bots = await _botService.getBots();
      _logger.i('Successfully prefetched ${bots.length} bots');
      return;
    } catch (e) {
      _logger.e('Error prefetching bots: $e');
      // Don't rethrow - we want to continue even if this fails
    }
  }
  
  Future<void> _prefetchSubscription() async {
    try {
      await _subscriptionService.getCurrentSubscription();
      _logger.i('Successfully prefetched subscription data');
      return;
    } catch (e) {
      _logger.e('Error prefetching subscription: $e');
      // Don't rethrow - we want to continue even if this fails
    }
  }
    // Khởi tạo AuthService trong nền không chặn UI
  Future<void> _initializeAuthService() async {
    try {
      await _authService.initializeService();
      _logger.i('Auth service initialized successfully');
      
      // Start prefetching data once auth service is initialized
      _prefetchData();
    } catch (e) {
      _logger.e('Error initializing auth service: $e');
    }
  }
  
  // Chuyển màn hình sau 2 giây hoặc khi kiểm tra xác thực xong và animation logo đã hoàn thành
  Future<void> _checkAuthAndNavigate() async {
    try {
      // Đảm bảo hiển thị Splash ít nhất 2 giây
      await Future.delayed(const Duration(milliseconds: 2000));
      
      if (!mounted) return;
      
      // Đây là phần chính - kiểm tra xác thực
      bool isLoggedIn = await _authService.isLoggedIn();
      
      if (!mounted) return;
      
      // Wait a bit more if user is logged in but data isn't preloaded yet
      // This ensures a smoother experience when the app opens
      if (isLoggedIn && !_dataPreloaded) {
        // Give a little more time for prefetching to complete, but don't wait forever
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      // Chuyển hướng đến màn hình thích hợp dựa trên trạng thái đăng nhập
      if (isLoggedIn) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MainScreen(
              toggleTheme: widget.toggleTheme,
              setThemeMode: widget.setThemeMode,
              currentThemeMode: widget.currentThemeMode,
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
    
    return AuthBackground(
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
                  Icons.auto_awesome,
                  size: 200,
                  color: colors.foreground,
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // App title
            FadeTransition(
              opacity: _animation,
              child: Text(
                'AI Chat Bot',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: colors.foreground,
                  fontFamily: 'Geist',
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            FadeTransition(
              opacity: _animation,
              child: Text(
                'Your intelligent companion',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w300,
                  color: colors.muted,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}