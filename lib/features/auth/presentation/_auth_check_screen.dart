import 'package:flutter/material.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../main_screen.dart';
import 'login_page.dart';
import 'widgets/auth_widgets.dart';

class AuthCheckScreen extends StatefulWidget {
  final Function toggleTheme;
  final Function setThemeMode;
  final String currentThemeMode;

  const AuthCheckScreen({
    super.key,
    required this.toggleTheme,
    required this.setThemeMode,
    required this.currentThemeMode,
  });

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final isLoggedIn = await _authService.isLoggedIn();

      if (!mounted) return;

      if (isLoggedIn) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (context) => MainScreen(
                    toggleTheme: widget.toggleTheme,
                    setThemeMode: widget.setThemeMode,
                    currentThemeMode: widget.currentThemeMode,
                  )),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
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

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.dark;

    return AuthBackground(
      child: Center(
        child: _isLoading
            ? CircularProgressIndicator(
                color: colors.foreground,
              )
            : Text(
                'Checking authentication...',
                style: TextStyle(
                  color: colors.foreground,
                  fontSize: 18,
                ),
              ),
      ),
    );
  }
}
