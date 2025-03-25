import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'firebase_options.dart';
import 'core/services/auth/auth_service.dart';
import 'features/auth/presentation/login_page.dart';
import 'core/utils/firebase/firebase_checker.dart';
import 'core/utils/diagnostics/platform_checker.dart';
import 'core/utils/diagnostics/config_checker.dart';

final logger = Logger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load .env file
  await dotenv.load(fileName: '.env');
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseChecker.setInitialized(true);
    logger.i('Firebase initialized successfully');
  } catch (e) {
    logger.e('Error initializing Firebase: $e');
    FirebaseChecker.setInitialized(false);
  }
  
  // Run platform checks in debug mode
  PlatformChecker.checkPlatform();
  await ConfigChecker.checkGoogleAuthConfig();
  
  // Initialize AuthService
  final authService = AuthService();
  await authService.initializeService();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Chat Bot',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}