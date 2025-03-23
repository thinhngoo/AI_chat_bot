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
import 'core/services/firestore/firestore_data_service.dart'; // Add import for FirestoreDataService
import 'core/models/user_model.dart'; // Add import for UserModel
import 'package:firebase_auth/firebase_auth.dart'; // Add import for User

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
  final Logger _logger = Logger(); // Add Logger instance

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
      
      // Check authentication state directly
      final isUserLoggedIn = await _authService.isLoggedIn();
      
      if (isUserLoggedIn) {
        _logger.i('User is logged in');
        
        // If using Firebase, try to load user profile data from Firestore
        if (firebaseInitialized) {
          await _loadUserProfileData();
        }
      } else {
        _logger.i('No user is currently logged in');
      }
      
      if (mounted) {
        setState(() {
          _isAuthReady = true;
          _isLoggedIn = isUserLoggedIn;
        });
      }
    } catch (e) {
      _logger.e('Error checking auth state: $e');
      if (mounted) {
        setState(() {
          _isAuthReady = true;
          _isLoggedIn = false;
        });
      }
    }
  }
  
  // Helper method to load user profile data from Firestore
  Future<void> _loadUserProfileData() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;
      
      final FirestoreDataService firestoreService = FirestoreDataService();
      
      // Get user ID based on auth provider type
      final userId = user is String ? user : user.uid;
      
      // Attempt to load user data from Firestore
      final userData = await firestoreService.getUserById(userId);
      
      if (userData != null) {
        _logger.i('User data loaded successfully from Firestore');
      } else {
        _logger.w('User exists in Authentication but not in Firestore');
        
        // Create basic user record if it doesn't exist
        if (!_authService.isUsingWindowsAuth()) {
          final String email = user is String ? user : (user.email ?? 'unknown');
          final String? name = user is User ? user.displayName : null;
          
          final userModel = UserModel(
            uid: userId,
            email: email,
            name: name,
            createdAt: DateTime.now(),
            isEmailVerified: _authService.isEmailVerified(),
          );
          
          await firestoreService.createOrUpdateUser(userModel);
          _logger.i('Created new user profile in Firestore');
        }
      }
    } catch (e) {
      _logger.e('Error loading user profile data: $e');
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