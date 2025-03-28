import 'package:logger/logger.dart';
import 'auth_provider_interface.dart';
import 'providers/jarvis_auth_provider.dart';
import '../../models/user_model.dart';

/// Authentication service that delegates to the configured auth provider
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  
  final Logger _logger = Logger();
  late AuthProviderInterface _provider;
  bool _isInitialized = false;
  
  AuthService._internal() {
    // Use Jarvis Auth Provider by default
    _provider = JarvisAuthProvider();
  }
  
  /// Initialize the auth service
  Future<void> initializeService() async {
    if (_isInitialized) return;
    
    try {
      _logger.i('Initializing Auth Service');
      
      // Initialize the provider
      await _provider.initialize();
      
      _isInitialized = true;
      _logger.i('Auth Service initialized successfully');
    } catch (e) {
      _logger.e('Error initializing Auth Service: $e');
      throw Exception('Failed to initialize Auth Service: $e');
    }
  }
  
  /// Get the current authenticated user
  UserModel? get currentUser => _provider.currentUser;
  
  /// Check if user is logged in with valid token
  Future<bool> isLoggedIn() async {
    if (!_isInitialized) await initializeService();
    
    try {
      // First check if logged in via provider
      final isLoggedIn = await _provider.isLoggedIn();
      if (!isLoggedIn) {
        return false;
      }
      
      // Then verify if Jarvis API token is valid
      // This cast is needed since we're using JarvisAuthProvider as the implementation
      final jarvisProvider = _provider as JarvisAuthProvider;
      final isTokenValid = await jarvisProvider.isTokenValid();
      
      if (!isTokenValid) {
        _logger.w('Token is invalid, trying to refresh');
        return await _provider.refreshToken();
      }
      
      return true;
    } catch (e) {
      _logger.e('Error checking login status: $e');
      return false;
    }
  }
  
  /// Check if email is verified
  bool isEmailVerified() {
    if (!_isInitialized) {
      _logger.w('Auth Service not initialized, returning false for isEmailVerified');
      return false;
    }
    return _provider.isEmailVerified();
  }
  
  /// Sign in with email and password
  Future<UserModel> signInWithEmailAndPassword(String email, String password) async {
    if (!_isInitialized) await initializeService();
    
    try {
      _logger.i('Sign in request for email: $email');
      return await _provider.signInWithEmailAndPassword(email, password);
    } catch (e) {
      _logger.e('Sign in error: $e');
      throw e.toString();
    }
  }
  
  /// Sign up with email and password
  Future<UserModel> signUpWithEmailAndPassword(String email, String password, {String? name}) async {
    if (!_isInitialized) await initializeService();
    
    try {
      _logger.i('Sign up request for email: $email');
      return await _provider.signUpWithEmailAndPassword(email, password, name: name);
    } catch (e) {
      _logger.e('Sign up error: $e');
      throw e.toString();
    }
  }
  
  /// Sign out the current user
  Future<void> signOut() async {
    if (!_isInitialized) await initializeService();
    
    try {
      _logger.i('Sign out request');
      await _provider.signOut();
    } catch (e) {
      _logger.e('Sign out error: $e');
      throw e.toString();
    }
  }
  
  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    if (!_isInitialized) await initializeService();
    
    try {
      _logger.i('Password reset request for email: $email');
      await _provider.sendPasswordResetEmail(email);
    } catch (e) {
      _logger.e('Password reset error: $e');
      throw e.toString();
    }
  }
  
  /// Refresh the auth tokens
  Future<bool> refreshToken() async {
    if (!_isInitialized) await initializeService();
    
    try {
      _logger.i('Token refresh request');
      return await _provider.refreshToken();
    } catch (e) {
      _logger.e('Token refresh error: $e');
      return false;
    }
  }
  
  /// Refresh the user information
  Future<void> reloadUser() async {
    if (!_isInitialized) await initializeService();
    
    try {
      _logger.i('Reload user request');
      await _provider.reloadUser();
    } catch (e) {
      _logger.e('Reload user error: $e');
      throw e.toString();
    }
  }
  
  /// Confirm password reset
  Future<void> confirmPasswordReset(String code, String newPassword) async {
    if (!_isInitialized) await initializeService();
    
    try {
      _logger.i('Confirm password reset request');
      await _provider.confirmPasswordReset(code, newPassword);
    } catch (e) {
      _logger.e('Confirm password reset error: $e');
      throw e.toString();
    }
  }
  
  /// Manually verify email - only for testing/development!
  Future<bool> manuallySetEmailVerified() async {
    if (!_isInitialized) await initializeService();
    
    try {
      _logger.i('Manual email verification request');
      return await _provider.manuallySetEmailVerified();
    } catch (e) {
      _logger.e('Manual email verification error: $e');
      return false;
    }
  }
  
  /// Update user profile
  Future<bool> updateUserProfile(Map<String, dynamic> userData) async {
    if (!_isInitialized) await initializeService();
    
    try {
      _logger.i('Update user profile request');
      return await _provider.updateUserProfile(userData);
    } catch (e) {
      _logger.e('Update user profile error: $e');
      return false;
    }
  }
}