import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../core/services/auth/auth_service.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/main_screen.dart';
import '../../core/constants/app_colors.dart';
import '../auth/presentation/widgets/auth_background.dart';

class SplashScreen extends StatelessWidget {
  final Function toggleTheme;
  final Function setThemeMode;
  final String currentThemeMode;

  const SplashScreen({
    super.key, 
    required this.toggleTheme,
    required this.setThemeMode,
    required this.currentThemeMode,
  });

  Future<bool> _checkAuth() async {
    final AuthService authService = AuthService();
    final Logger logger = Logger();
    
    try {
      await authService.initializeService();
      logger.i('Auth service initialized successfully');
      return await authService.isLoggedIn();
    } catch (e) {
      logger.e('Error during auth check: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.dark;

    return AuthBackground(
      child: FutureBuilder<bool>(
        future: _checkAuth(),
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
                    toggleTheme: toggleTheme,
                    setThemeMode: setThemeMode,
                    currentThemeMode: currentThemeMode,
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