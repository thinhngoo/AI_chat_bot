import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../core/services/auth/auth_service.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/main_screen.dart';
import '../../core/constants/app_colors.dart';
import '../auth/presentation/widgets/auth_background.dart';
import '../../features/bot/services/bot_service.dart';

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
  final BotService _botService = BotService();
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
      
      // Fetch bot list in background
      _botService.getBots().then((bots) {
        _logger.i('Successfully prefetched ${bots.length} bots');
        if (mounted) {
          setState(() {
            _dataPreloaded = true;
          });
        }
      }).catchError((e) {
        _logger.e('Error prefetching bots: $e');
      });
    } catch (e) {
      _logger.e('Error during prefetch: $e');
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
      child: FutureBuilder<bool>(
        future: _authService.isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'AI Chat Bot',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: colors.foreground,
                      fontFamily: 'Geist',
                    ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasData && snapshot.data == true) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => MainScreen(
                    toggleTheme: widget.toggleTheme,
                    setThemeMode: widget.setThemeMode,
                    currentThemeMode: widget.currentThemeMode,
                  ),
                ),
              );
            });
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const LoginPage(),
                ),
              );
            });
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}