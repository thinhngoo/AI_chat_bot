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
      debugShowCheckedModeBanner: false,
      theme: _isDarkMode ? 
        ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          primaryColor: Colors.teal,
          colorScheme: ColorScheme.dark(
            primary: Colors.teal,
            secondary: Colors.tealAccent,
            surface: const Color(0xFF1E1E1E),
            background: const Color(0xFF121212),
            surfaceContainerHighest: Colors.black.withOpacity(0.12),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1D1D1D),
            elevation: 0,
            centerTitle: false,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          cardTheme: CardTheme(
            color: const Color(0xFF2D2D2D),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade700),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.teal, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade800.withOpacity(0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.teal),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Colors.teal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            ),
          ),
          dialogTheme: DialogTheme(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: const Color(0xFF2D2D2D),
          ),
          chipTheme: ChipThemeData(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          snackBarTheme: const SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ) : 
        ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          primaryColor: Colors.teal,
          colorScheme: ColorScheme.light(
            primary: Colors.teal,
            secondary: Colors.tealAccent,
            surface: Colors.white,
            surfaceContainerHighest: Colors.grey.withOpacity(0.08),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: false,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          cardTheme: CardTheme(
            color: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.teal, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.teal),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Colors.teal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            ),
          ),
          dialogTheme: DialogTheme(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.white,
          ),
          chipTheme: ChipThemeData(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          snackBarTheme: const SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
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