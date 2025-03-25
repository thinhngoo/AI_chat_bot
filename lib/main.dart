import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'dart:async';
import 'firebase_options.dart';
import 'core/services/auth/auth_service.dart';
import 'core/utils/firebase/firebase_checker.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/chat/presentation/home_page.dart';
import 'core/services/firestore/firestore_data_service.dart';
import 'core/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

final Logger _logger = Logger();

// Global state to track initialization
bool _isFirebaseInitialized = false;

// Changed to async to wait for initialization
void main() async {
  // This ensures Flutter is initialized before we do anything else
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load .env file with better error handling
  try {
    await dotenv.load(fileName: ".env");
    _logger.i('.env file loaded successfully');
  } catch (e) {
    _logger.e('Failed to load .env file: $e');
    _logger.i('Creating a default .env file with placeholder values...');
    
    // Continue without .env file - the app will use fallback values
    dotenv.testLoad(fileInput: '''
      # Default environment variables
      GEMINI_API_KEY=demo_api_key
      GOOGLE_DESKTOP_CLIENT_ID=placeholder_client_id
      GOOGLE_CLIENT_SECRET=placeholder_client_secret
    ''');
  }
  
  // Initialize Firebase with error handling
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _isFirebaseInitialized = true;
    FirebaseChecker.setInitialized(true);
    _logger.i('Firebase initialized successfully');
  } catch (e) {
    _isFirebaseInitialized = false;
    FirebaseChecker.setInitialized(false);
    _logger.e('Firebase initialization error: $e');
  }

  // Initialize auth service (non-blocking way)
  final authService = AuthService();
  // Don't wait for this to complete - will be handled asynchronously
  authService.initializeService();
  
  // Run app immediately
  runApp(MyApp(firebaseInitialized: _isFirebaseInitialized));
}

// Fix: Change MyApp to StatefulWidget to match with MyAppState
class MyApp extends StatefulWidget {
  final bool firebaseInitialized;
  
  const MyApp({
    super.key,
    required this.firebaseInitialized,
  });

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  final AuthService _authService = AuthService();
  bool _isAuthReady = false;
  bool _isLoggedIn = false;
  final Logger _logger = Logger(); 

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
        
        final currentUser = _authService.currentUser;
        if (currentUser != null) {
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
      // Start with the SplashScreen which will handle navigation
      home: SplashScreen(firebaseInitialized: widget.firebaseInitialized),
    );
  }
}

class SplashScreen extends StatefulWidget {
  final bool firebaseInitialized;

  const SplashScreen({
    super.key,
    required this.firebaseInitialized,
  });

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    
    // Navigate to login page after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FlutterLogo(size: 100),
            const SizedBox(height: 24),
            const Text(
              'AI Chat Bot',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            if (!widget.firebaseInitialized)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Firebase initialization failed. Some features may be limited.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.orange),
                ),
              ),
          ],
        ),
      ),
    );
  }
}