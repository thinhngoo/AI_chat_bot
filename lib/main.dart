import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'dart:async';
import 'config/firebase_options.dart';
import 'core/services/auth/auth_service.dart';
import 'core/services/platform/platform_service_helper.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/chat/presentation/home_page.dart';

final Logger _logger = Logger();

// Global state to track initialization
bool _isFirebaseInitialized = false;

void main() {
  // This ensures Flutter is initialized before we do anything else
  WidgetsFlutterBinding.ensureInitialized();
  
  // Start app immediately without waiting for initialization
  runApp(const MyApp());
  
  // Run initialization in background
  _initializeAppInBackground();
}

// Run all initialization in background to avoid UI freezing
Future<void> _initializeAppInBackground() async {
  try {
    // Get platform info (should be fast with new optimizations)
    final platformInfo = PlatformServiceHelper.getPlatformInfo();
    _logger.i('Platform detected: ${platformInfo['platform']}');
    
    // Start loading environment variables and Firebase in parallel
    final envFuture = _loadEnvironmentVariables();
    final firebaseFuture = _initializeFirebaseIfSupported(platformInfo);
    
    // Wait for both to complete
    await Future.wait([
      envFuture.timeout(const Duration(seconds: 3), onTimeout: () {
        _logger.w('Environment loading timed out, continuing with defaults');
        return;
      }),
      firebaseFuture.timeout(const Duration(seconds: 5), onTimeout: () {
        _logger.w('Firebase initialization timed out');
        _isFirebaseInitialized = false;
        return false;
      })
    ]);
    
  } catch (e) {
    _logger.e('Error during background initialization: $e');
  }
}

Future<void> _loadEnvironmentVariables() async {
  try {
    await dotenv.load(fileName: ".env");
    _logger.i('Environment variables loaded successfully');
    
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'your_gemini_api_key_here') {
      _logger.w('GEMINI_API_KEY is missing or invalid');
      dotenv.env['GEMINI_API_KEY'] = 'demo_api_key_please_configure';
    } else {
      _logger.i('GEMINI_API_KEY found and appears valid');
    }
  } catch (e) {
    _logger.w('Failed to load .env file: $e');
    dotenv.env['GEMINI_API_KEY'] = 'demo_api_key_please_configure';
  }
}

Future<bool> _initializeFirebaseIfSupported(Map<String, dynamic> platformInfo) async {
  // Skip Firebase initialization if platform doesn't support it
  if (!platformInfo['supportsFirebase']) {
    _logger.i('Firebase not supported on this platform. Using fallback.');
    AuthService().setFirebaseInitialized(false);
    return false;
  }
  
  _logger.i('Initializing Firebase for ${platformInfo['platform']}');
  
  try {
    // Quick validation of Firebase options
    if (!_validateFirebaseOptions()) {
      _logger.w('Firebase configuration appears invalid');
      AuthService().setFirebaseInitialized(false);
      return false;
    }
    
    // Initialize Firebase with a timeout
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Quick check if Firebase is initialized
    _isFirebaseInitialized = Firebase.apps.isNotEmpty;
    
    _logger.i('Firebase initialized: $_isFirebaseInitialized');
    
    // Update AuthService with initialization status
    AuthService().setFirebaseInitialized(_isFirebaseInitialized);
    
    // Skip detailed validation to prevent freezing
    return _isFirebaseInitialized;
  } catch (e) {
    _logger.e('Firebase initialization error: $e');
    AuthService().setFirebaseInitialized(false);
    return false;
  }
}

bool _validateFirebaseOptions() {
  try {
    // Minimal validation to avoid heavy processing
    final options = DefaultFirebaseOptions.currentPlatform;
    return options.apiKey.isNotEmpty;
  } catch (e) {
    return false;
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Use a timer to periodically update the UI when initialization completes
  Timer? _checkInitTimer;

  @override
  void initState() {
    super.initState();
    // Start a timer that periodically checks if initialization is complete
    _checkInitTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _checkInitTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI của Vinh',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // Optimize theme for performance
        useMaterial3: false, // Using Material 2 for better performance
      ),
      home: StreamBuilder<dynamic>(
        stream: AuthService().authStateChanges(),
        builder: (context, snapshot) {
          // Cancel timer once auth state is available (not waiting)
          if (snapshot.connectionState != ConnectionState.waiting) {
            _checkInitTimer?.cancel();
          }
          
          // Show loading only briefly, then show login anyway
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text("Đang khởi động...")
                  ],
                ),
              ),
            );
          } else if (snapshot.hasData && snapshot.data != null) {
            return const HomePage();
          } else {
            return const LoginPage();
          }
        },
      ),
    );
  }
}