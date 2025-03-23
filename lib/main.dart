import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'dart:async';
import 'firebase_options.dart';
import 'core/services/auth/auth_service.dart';
import 'core/services/platform/platform_service_helper.dart';
import 'core/utils/firebase/firebase_checker.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/chat/presentation/home_page.dart';

final Logger _logger = Logger();

// Global state to track initialization
bool _isFirebaseInitialized = false;

// Changed to async to wait for initialization
void main() async {
  // This ensures Flutter is initialized before we do anything else
  WidgetsFlutterBinding.ensureInitialized();
  
  // Wait for core initialization to complete before running the app
  await _initializeCore();
  
  // Run app after initialization is complete
  runApp(const MyApp());
}

/// Initialize core app services: environment variables, Firebase, AuthService
Future<void> _initializeCore() async {
  try {
    // First load environment variables
    _logger.i('Loading environment variables...');
    await dotenv.load();
    
    // Check if we're on a platform that supports Firebase
    final platformInfo = PlatformServiceHelper.getPlatformInfo();
    _logger.i('Platform detected: ${platformInfo['platform']} (Firebase support: ${platformInfo['supportsFirebase']})');
    
    // Initialize Firebase if supported on this platform
    if (platformInfo['supportsFirebase']) {
      _logger.i('Initializing Firebase...');
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        _isFirebaseInitialized = true;
        _logger.i('Firebase initialization successful');
      } catch (e) {
        _logger.e('Firebase initialization error: $e');
        _isFirebaseInitialized = false;
        // Continue execution even if Firebase fails - we'll use fallback auth
      }
    } else {
      _logger.w('Firebase not supported on this platform, using fallback services');
    }
    
    // Initialize auth service after Firebase is ready
    final authService = AuthService();
    authService.setFirebaseInitialized(_isFirebaseInitialized);
    await authService.initializeService();
    
    _logger.i('Core initialization complete');
  } catch (e) {
    _logger.e('Error during core initialization: $e');
    // Allow app to continue with reduced functionality
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AuthService _authService = AuthService();
  bool _isAuthReady = false;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      // Check Firebase status first to determine which path to take
      final firebaseInitialized = await FirebaseChecker.checkFirebaseInitialization();
      
      if (firebaseInitialized) {
        _logger.i('Firebase is initialized, checking auth state');
      } else {
        // This is normal for platforms without Firebase support or when Firebase fails to initialize
        // Change the log level from warning to info since this is expected in some scenarios
        _logger.i('Firebase not initialized (using local auth check instead)');
      }
      
      // Use the same code path regardless of Firebase status
      // AuthService will handle the appropriate authentication method internally
      final isLoggedIn = await _authService.isLoggedIn();
      
      if (mounted) {
        setState(() {
          _isLoggedIn = isLoggedIn;
          _isAuthReady = true;
        });
      }
    } catch (e) {
      _logger.e('Error checking auth state: $e');
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _isAuthReady = true; // Still mark as ready to show login screen
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Chat Bot',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      home: _isAuthReady
          ? (_isLoggedIn ? const HomePage() : const LoginPage())
          : const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
    );
  }
}