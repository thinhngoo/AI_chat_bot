import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'core/services/auth/auth_service.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/chat/presentation/home_page.dart';
import 'core/constants/api_constants.dart';  // Import constants

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final logger = Logger();
  
  // We still load environment variables for other settings like API keys
  try {
    await dotenv.load(fileName: '.env');
    logger.i('Environment variables loaded');
  } catch (e) {
    logger.w('Failed to load .env file: $e');
    logger.i('Using default constants for API configuration');
  }
  
  // Log that we're using hardcoded constants for Stack Auth
  logger.i('Using Stack Project ID: ${ApiConstants.stackProjectId.substring(0, 8)}...');
  
  // Initialize the auth service (now using Jarvis)
  await AuthService().initializeService();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Chat Bot',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AuthCheckPage(),
      routes: {
        '/home': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
      },
    );
  }
}

// AuthCheckPage class remains unchanged...
class AuthCheckPage extends StatefulWidget {
  const AuthCheckPage({super.key});

  @override
  State<AuthCheckPage> createState() => _AuthCheckPageState();
}

class _AuthCheckPageState extends State<AuthCheckPage> {
  final AuthService _authService = AuthService();
  final Logger _logger = Logger();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      _logger.i('Checking authentication status...');
      final isLoggedIn = await _authService.isLoggedIn();
      
      if (!mounted) return;
      
      if (isLoggedIn) {
        _logger.i('User is logged in, navigating to home page');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        _logger.i('User is not logged in, navigating to login page');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (e) {
      _logger.e('Error checking auth status: $e');
      
      if (!mounted) return;
      
      // On error, default to login page
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