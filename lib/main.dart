import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'firebase_options.dart'; // Import the generated options file
import 'services/auth_service.dart';
import 'services/platform_service_helper.dart';
import 'screens/login_page.dart';
import 'screens/home_page.dart';

final Logger _logger = Logger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables with error handling
  try {
    await dotenv.load(fileName: ".env");
    _logger.i('Environment variables loaded successfully');
    
    // Validate API key even if .env loaded successfully
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'your_gemini_api_key_here') {
      _logger.w('GEMINI_API_KEY is missing or invalid in .env file');
      // Create default environment variable with more descriptive value
      dotenv.env['GEMINI_API_KEY'] = 'demo_api_key_please_configure';
    } else {
      _logger.i('GEMINI_API_KEY found and appears valid');
    }
  } catch (e) {
    _logger.w('Failed to load .env file: $e');
    // Create default environment variables
    dotenv.env['GEMINI_API_KEY'] = 'demo_api_key_please_configure';
    
    // Add error handling hint
    _logger.i('Please create a .env file in your project root with GEMINI_API_KEY=your_api_key');
  }
  
  // Initialize Firebase only on supported platforms
  if (PlatformServiceHelper.supportsFirebaseAuth) {
    try {
      // Use the generated Firebase options from flutterfire configure
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _logger.i('Firebase initialized successfully with project: vinh-aff13');
      
      // Log Firestore initialization
      _logger.i('Firestore is now available for storing user data');
    } catch (e) {
      _logger.e('Failed to initialize Firebase: $e');
      _logger.i('Application will use fallback authentication mechanism');
    }
  } else {
    _logger.w('Firebase Auth not supported on this platform. Using fallback implementation.');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI của Vinh',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: StreamBuilder<dynamic>(
        // Use stream for real-time auth state changes instead of future
        stream: AuthService().authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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