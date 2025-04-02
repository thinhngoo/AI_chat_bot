import 'package:flutter/material.dart';
import 'core/services/auth/auth_service.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/chat/presentation/chat_screen.dart';
import 'features/bot/presentation/bot_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the auth service
  await AuthService().initializeService();
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  void toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Chat Bot',
      theme: _isDarkMode ? 
        ThemeData.dark(useMaterial3: true).copyWith(
          primaryColor: Colors.teal,
          colorScheme: const ColorScheme.dark(
            primary: Colors.teal,
            secondary: Colors.tealAccent,
            surface: Color(0xFF1E1E1E),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1E1E1E),
            elevation: 0,
          ),
          cardTheme: const CardTheme(
            color: Color(0xFF2D2D2D),
          ),
        ) : 
        ThemeData.light(useMaterial3: true).copyWith(
          primaryColor: Colors.teal,
          colorScheme: const ColorScheme.light(
            primary: Colors.teal,
            secondary: Colors.tealAccent,
            surface: Colors.white,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
          ),
          cardTheme: const CardTheme(
            color: Colors.white,
          ),
        ),
      initialRoute: '/',
      routes: {
        '/': (context) => AuthCheckPage(toggleTheme: toggleTheme, isDarkMode: _isDarkMode),
        '/bots': (context) => const BotListScreen(),
      },
    );
  }
}

class AuthCheckPage extends StatefulWidget {
  final Function toggleTheme;
  final bool isDarkMode;
  
  const AuthCheckPage({
    super.key, 
    required this.toggleTheme,
    required this.isDarkMode
  });

  @override
  State<AuthCheckPage> createState() => _AuthCheckPageState();
}

class _AuthCheckPageState extends State<AuthCheckPage> {
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
          MaterialPageRoute(builder: (context) => ChatScreen(
            toggleTheme: widget.toggleTheme,
            isDarkMode: widget.isDarkMode,
          )),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
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
    return Scaffold(
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : const Text('Checking authentication status...'),
      ),
    );
  }
}