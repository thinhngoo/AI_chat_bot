import 'package:logger/logger.dart';
import 'dart:async';
import 'providers/jarvis_auth_provider.dart';

class AuthService {
  final Logger _logger = Logger();
  final JarvisAuthProvider _auth = JarvisAuthProvider();
  bool _isInitialized = false;
  bool _isInitializing = false;
  
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  
  AuthService._internal() {
    _logger.i('AuthService created with Jarvis Auth Provider');
  }
  
  // Initialize the authentication service
  Future<void> initializeService() async {
    if (_isInitialized || _isInitializing) return;
    
    _isInitializing = true;
    _logger.i('Initializing AuthService with Jarvis API');
    
    try {
      await _auth.initialize();
      _isInitialized = true;
      _logger.i('AuthService initialized successfully');
    } catch (e) {
      _logger.e('Error initializing AuthService: $e');
    } finally {
      _isInitializing = false;
    }
  }
  
  // Get current user
  dynamic get currentUser => _auth.currentUser;
  
  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await _auth.isLoggedIn();
  }
  
  // Sign in with email and password
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email, password);
    } catch (e) {
      _logger.e('Error signing in with email and password: $e');
      throw e.toString();
    }
  }
  
  // Sign up with email and password
  Future<String> signUpWithEmailAndPassword(String email, String password, {String? name}) async {
    try {
      await _auth.signUpWithEmailAndPassword(email, password, name: name);
      return 'Account created successfully!';
    } catch (e) {
      _logger.e('Error signing up with email and password: $e');
      throw e.toString();
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      _logger.e('Error signing out: $e');
      throw e.toString();
    }
  }
  
  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email);
    } catch (e) {
      _logger.e('Error sending password reset email: $e');
      throw e.toString();
    }
  }
  
  // Confirm password reset
  Future<void> confirmPasswordReset(String code, String newPassword) async {
    try {
      await _auth.confirmPasswordReset(code, newPassword);
    } catch (e) {
      _logger.e('Error confirming password reset: $e');
      throw e.toString();
    }
  }
  
  // Update password
  Future<void> updatePassword(String currentPassword, String newPassword) async {
    try {
      await _auth.updatePassword(currentPassword, newPassword);
    } catch (e) {
      _logger.e('Error updating password: $e');
      throw e.toString();
    }
  }
  
  // Reload user
  Future<void> reloadUser() async {
    try {
      await _auth.reloadUser();
    } catch (e) {
      _logger.e('Error reloading user: $e');
      throw e.toString();
    }
  }
  
  // Check if email is verified
  bool isEmailVerified() {
    return _auth.isEmailVerified();
  }
  
  // Manual override for verification status
  Future<void> manuallySetEmailVerified() async {
    _logger.i('Manual override for email verification requested');
    await _auth.manuallySetEmailVerified();
  }
  
  // Resend verification email
  Future<void> resendVerificationEmail() async {
    try {
      await _auth.resendVerificationEmail();
    } catch (e) {
      _logger.e('Error resending verification email: $e');
      throw e.toString();
    }
  }
  
  // Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      await _auth.signInWithGoogle();
    } catch (e) {
      _logger.e('Error signing in with Google: $e');
      throw e.toString();
    }
  }
  
  // Check if using Firebase Auth
  bool isUsingFirebaseAuth() {
    return false; // Always return false since we're using Jarvis API now
  }
  
  // Get auth state changes stream
  Stream<dynamic> authStateChanges() {
    return _auth.authStateChanges();
  }
}