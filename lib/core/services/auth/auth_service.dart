import 'package:logger/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async'; // Add missing import for Timer and StreamController
import '../platform/platform_service_helper.dart';
import 'platform/desktop/windows_auth_service.dart';
import 'providers/firebase_auth_provider.dart';
import 'auth_provider_interface.dart';
import 'package:firebase_core/firebase_core.dart';

class AuthService {
  final Logger _logger = Logger();
  // Changed from late final to regular field to allow reassignment
  AuthProviderInterface _auth;
  bool _firebaseInitialized = false;
  bool _isInitialized = false;
  bool _isInitializing = false;
  
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  
  // Initialize with WindowsAuthService as the default
  AuthService._internal() : _auth = WindowsAuthService() {
    _logger.i('AuthService created with safe default provider (WindowsAuthService)');
  }
  
  // This will be called explicitly after Firebase is initialized
  Future<void> initializeService() async {
    // Prevent multiple simultaneous initialization attempts
    if (_isInitializing) {
      _logger.i('AuthService initialization already in progress');
      return;
    }
    
    if (_isInitialized) {
      _logger.i('AuthService already initialized');
      return;
    }
    
    _isInitializing = true;
    
    try {
      await _initializeAuth();
      _isInitialized = true;
      _isInitializing = false;
      
      // Provide more detailed logging about the selected provider
      if (_auth is WindowsAuthService) {
        _logger.i('AuthService initialized with WindowsAuthService (local authentication)');
      } else {
        _logger.i('AuthService initialized with FirebaseAuthProvider (Firebase authentication)');
      }
    } catch (e) {
      _isInitializing = false;
      _logger.e('Error initializing AuthService: $e');
      
      // Use is! instead of !(_auth is WindowsAuthService)
      if (_auth is! WindowsAuthService) {
        _logger.w('Failed to initialize with Firebase, using WindowsAuthService as fallback');
        _auth = WindowsAuthService();
        // Mark as initialized anyway to prevent the app from freezing
        _isInitialized = true;
      }
    }
  }
  
  // Modified to properly detect Windows platform and handle Firebase initialization
  Future<void> _initializeAuth() async {
    try {
      // First check if we're on Windows
      if (!kIsWeb && PlatformServiceHelper.isDesktopWindows) {
        _logger.i('Detected Windows platform, using WindowsAuthService');
        // We're already using WindowsAuthService from the constructor
        _firebaseInitialized = false;
        return;
      }
      
      // For all other platforms, check if Firebase is initialized
      bool isFirebaseReady = false;
      
      try {
        // Use a shorter timeout to avoid blocking
        isFirebaseReady = await Future.value(Firebase.apps.isNotEmpty)
            .timeout(const Duration(milliseconds: 500), onTimeout: () => false);
        _logger.i('Firebase initialization check: ${isFirebaseReady ? 'Ready' : 'Not ready'}');
      } catch (e) {
        _logger.w('Error checking Firebase initialization: $e');
        isFirebaseReady = false;
      }
      
      if (!isFirebaseReady) {
        _logger.w('Firebase not initialized yet, using fallback auth provider');
        // We're already using the default provider (WindowsAuthService)
        _firebaseInitialized = false;
        return;
      }
      
      // Firebase is ready, try to use FirebaseAuthProvider
      _logger.i('Using Firebase authentication provider');
      
      try {
        // Check if we can access FirebaseAuth before creating the provider
        FirebaseAuth.instance;
        
        // Only create a new instance if this check passes
        final firebaseAuth = FirebaseAuthProvider();
        _firebaseInitialized = true;
        _auth = firebaseAuth;
        _logger.i('Firebase Auth provider initialized successfully');
      } catch (e) {
        _firebaseInitialized = false;
        _logger.w('Firebase Auth not available: $e');
        // Stick with WindowsAuthService as fallback
      }
    } catch (e) {
      // Only use WindowsAuthService as fallback if Firebase fails
      _logger.w('Firebase provider creation failed, using fallback: $e');
      // No need to reassign _auth, we're already using WindowsAuthService
      _firebaseInitialized = false;
    }
  }

  // Set Firebase initialization status
  void setFirebaseInitialized(bool status) {
    _firebaseInitialized = status;
    
    // If status changed to true and we're not already initialized, re-initialize
    if (status && !_isInitialized && !_isInitializing) {
      _logger.i('Firebase became available, re-initializing AuthService');
      initializeService();
      return;
    }
    
    // Only switch to fallback if we're using Firebase but it failed
    // and we're not already using WindowsAuthService
    if (!status && _auth is FirebaseAuthProvider && !PlatformServiceHelper.isDesktopWindows) {
      _logger.w('Firebase not initialized properly. Switching to fallback authentication.');
      try {
        _auth = WindowsAuthService();
      } catch (e) {
        _logger.e('Failed to initialize Windows auth service: $e');
      }
    } else if (status) {
      _logger.i('Firebase initialized successfully');
    }
  }

  // Method to get currently logged in user
  dynamic get currentUser => _auth.currentUser;
  
  // Method to get auth state changes with error handling and timeout
  Stream<dynamic> authStateChanges() {
    try {
      _logger.i('authStateChanges() called on provider: ${_auth.runtimeType}');
      
      // Get the stream from the auth provider
      final authStream = _auth.authStateChanges();
      
      // Create a controller to handle the stream with timeout
      final controller = StreamController<dynamic>.broadcast();
      
      // Set up a timeout to emit a value if the stream doesn't emit within 3 seconds
      Timer? timeoutTimer;
      
      // Listen to the stream from the auth provider
      final subscription = authStream.listen(
        (user) {
          _logger.i('AuthService: Got auth state: ${user ?? "null"}');
          timeoutTimer?.cancel();
          controller.add(user);
        },
        onError: (error) {
          _logger.e('Error in auth stream: $error');
          timeoutTimer?.cancel();
          controller.addError(error);
        }
      );
      
      // Set up timeout
      timeoutTimer = Timer(const Duration(seconds: 3), () {
        _logger.w('Auth stream timeout reached, forcing null value');
        if (!controller.isClosed) {
          controller.add(null);
        }
      });
      
      // Close the controller and cancel subscription when the stream is done
      controller.onCancel = () {
        timeoutTimer?.cancel();
        subscription.cancel();
        _logger.i('Auth stream listener canceled');
      };
      
      return controller.stream;
    } catch (e) {
      _logger.e('Error getting auth state changes stream: $e');
      // Return an empty stream so the app doesn't crash
      return Stream.value(null);
    }
  }

  // Check if service is properly initialized
  bool isInitialized() {
    return _isInitialized;
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await _auth.isLoggedIn();
  }

  // Sign in with email and password
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email, password);
      _logger.i('Đăng nhập thành công');
    } catch (e) {
      _logger.e('Lỗi đăng nhập: $e');
      throw e.toString();
    }
  }

  // Sign up with email and password - updated to support name and provide correct message
  Future<String> signUpWithEmailAndPassword(String email, String password, {String? name}) async {
    try {
      await _auth.signUpWithEmailAndPassword(email, password, name: name);
      
      // Provide different success messages based on authentication provider
      if (_auth is WindowsAuthService) {
        _logger.i('Đăng ký thành công trên Windows (không cần xác minh email)');
        return 'Đăng ký thành công';
      } else {
        _logger.i('Đăng ký thành công, email xác minh đã được gửi');
        return 'Đăng ký thành công, email xác minh đã được gửi';
      }
    } catch (e) {
      _logger.e('Lỗi đăng ký: $e');
      if (e.toString().contains('email-already-in-use') || 
          e.toString().contains('Email already exists')) {
        throw 'Email already exists';
      } else {
        throw e.toString();
      }
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    _logger.i('Đăng xuất thành công');
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email);
      _logger.i('Email đặt lại mật khẩu đã được gửi');
    } catch (e) {
      _logger.e('Lỗi gửi email đặt lại mật khẩu: $e');
      throw e.toString();
    }
  }

  // Check if email is verified
  bool isEmailVerified() {
    return _auth.isEmailVerified();
  }

  // Reload user to check if email has been verified
  Future<void> reloadUser() async {
    await _auth.reloadUser();
  }

  // Sign in with Google - improved error handling
  Future<void> signInWithGoogle() async {
    try {
      _logger.i('Starting Google sign-in process with provider: ${_auth.runtimeType}');
      await _auth.signInWithGoogle();
    } catch (e) {
      _logger.e('Lỗi đăng nhập Google: $e');
      
      // Important: Preserve the special plugin_not_supported error exactly
      if (e.toString() == 'plugin_not_supported') {
        // If we're on Windows and somehow still using FirebaseAuthProvider
        if (PlatformServiceHelper.isDesktopWindows && _auth is FirebaseAuthProvider) {
          _logger.w('Attempted to use FirebaseAuthProvider on Windows. Switching to WindowsAuthService.');
          _auth = WindowsAuthService();
          // Try again with the correct provider
          return signInWithGoogle();
        }
        throw 'plugin_not_supported';
      } else {
        throw e.toString();
      }
    }
  }

  // Resend verification email
  Future<void> resendVerificationEmail() async {
    try {
      // Check if a user is logged in before attempting to resend verification
      if (_auth.currentUser == null) {
        _logger.w('No user logged in when trying to resend verification email');
        throw 'Người dùng chưa đăng nhập, không thể gửi lại email xác minh';
      }
      
      await _auth.resendVerificationEmail();
      _logger.i('Email xác minh đã được gửi lại');
    } catch (e) {
      _logger.e('Error resending verification email: $e');
      // Convert general errors to user-friendly messages
      if (e.toString().contains('too-many-requests')) {
        throw 'Đã gửi quá nhiều email. Vui lòng thử lại sau ít phút.';
      } else if (e.toString().contains('network-request-failed')) {
        throw 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối internet và thử lại.';
      } else {
        throw e.toString();
      }
    }
  }

  // Add this method to check if Firebase is initialized properly
  bool isUsingFirebaseAuth() {
    return _auth is FirebaseAuthProvider;
  }

  // Add a method to check if we're using Windows auth
  bool isUsingWindowsAuth() {
    return _auth is WindowsAuthService;
  }

  // Add this method to check Firebase initialization status
  bool isFirebaseInitialized() {
    return _firebaseInitialized;
  }
}