import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Add import for SharedPreferences
import 'dart:async';
import 'firebase_options.dart';
import 'core/services/auth/auth_service.dart';
import 'core/services/platform/platform_service_helper.dart';
import 'core/utils/firebase/firebase_checker.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/chat/presentation/home_page.dart';
import 'core/services/firestore/firestore_data_service.dart';
import 'core/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'core/utils/diagnostics/platform_checker.dart';
import 'core/utils/diagnostics/config_checker.dart';

final Logger _logger = Logger();

// Global state to track initialization
bool _isFirebaseInitialized = false;

// Changed to async to wait for initialization
void main() async {
  // This ensures Flutter is initialized before we do anything else
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: '.env');
  
  // Check platform compatibility
  final platformDetails = PlatformChecker.getPlatformDetails();
  _logger.i('Running on platform: ${platformDetails['operatingSystem'] ?? 'web'}');
  
  // Validate configuration (without printing details)
  final configStatus = await ConfigChecker.validateGoogleAuthConfig();
  
  // Fix nullable expression errors with proper null checks
  if (configStatus['configValid'] == false && platformDetails['isWindows'] == true) {
    // Show configuration warning dialog for Windows users
    Logger().w('Invalid configuration detected on Windows platform');
    
    // Load environment variables anyway to prevent crashes
    await dotenv.load(fileName: '.env');
    
    // Initialize with fallback configuration
    await initializeWithFallbackConfig();
    
    // Set flag to show configuration notice on startup
    await SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('showConfigNotice', true);
    });
  } else {
    // Normal initialization path
    await dotenv.load(fileName: '.env');
    await initializeApp();
  }
  
  // Show configuration warning if needed (only in debug mode)
  if (configStatus['configValid'] == false && platformDetails['isWindows'] == true) {
    _logger.w('⚠️ Warning: Google authentication configuration is incomplete.');
    _logger.w('Please check your .env file and ensure GOOGLE_DESKTOP_CLIENT_ID and GOOGLE_CLIENT_SECRET are set.');
  }
  
  // Wait for core initialization to complete before running the app
  await _initializeCore();
  
  // Run app after initialization is complete
  runApp(const MyApp());
}

// Define the missing functions
Future<void> initializeWithFallbackConfig() async {
  _logger.i('Initializing with fallback configuration');
  try {
    // Initialize Firebase with default options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _isFirebaseInitialized = true;
    _logger.i('Firebase initialized with fallback config');
  } catch (e) {
    _logger.e('Error initializing Firebase with fallback config: $e');
    _isFirebaseInitialized = false;
  }
  
  // Initialize auth service with fallback settings
  final authService = AuthService();
  authService.setFirebaseInitialized(_isFirebaseInitialized);
  await authService.initializeService();
}

Future<void> initializeApp() async {
  _logger.i('Initializing app with standard configuration');
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _isFirebaseInitialized = true;
    _logger.i('Firebase initialized successfully');
  } catch (e) {
    _logger.e('Error initializing Firebase: $e');
    _isFirebaseInitialized = false;
  }
  
  // Initialize auth service
  final authService = AuthService();
  authService.setFirebaseInitialized(_isFirebaseInitialized);
  await authService.initializeService();
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
        _logger.i('Firebase not initialized (using local auth check instead)');
      }
      
      // Check authentication state directly
      final isUserLoggedIn = await _authService.isLoggedIn();
      
      if (isUserLoggedIn) {
        _logger.i('User is logged in');
        
        // Fix for the nullable expression error:
        final currentUser = _authService.currentUser;
        if (currentUser != null) {  // Proper null check
          // If using Firebase, try to load user profile data from Firestore
          if (firebaseInitialized) {
            await _loadUserProfileData();
          }
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