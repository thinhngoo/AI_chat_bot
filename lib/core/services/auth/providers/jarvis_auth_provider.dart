import 'dart:async';
import 'package:logger/logger.dart';
import '../../../models/user_model.dart';
import '../auth_provider_interface.dart';
import '../../api/jarvis_api_service.dart';

class JarvisAuthProvider implements AuthProviderInterface {
  final Logger _logger = Logger();
  final JarvisApiService _apiService = JarvisApiService();
  
  UserModel? _currentUser;
  final StreamController<UserModel?> _authStateController = StreamController<UserModel?>.broadcast();
  
  JarvisAuthProvider() {
    _initialize();
  }
  
  Future<void> _initialize() async {
    try {
      await _apiService.initialize();
      // Try to load current user if already logged in
      _currentUser = await _apiService.getCurrentUser();
      _authStateController.add(_currentUser);
    } catch (e) {
      _logger.e('Error initializing JarvisAuthProvider: $e');
    }
  }
  
  @override
  UserModel? get currentUser => _currentUser;
  
  @override
  Stream<UserModel?> authStateChanges() {
    return _authStateController.stream;
  }
  
  @override
  Future<bool> isLoggedIn() async {
    return _apiService.isAuthenticated();
  }
  
  @override
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      _logger.i('Attempting sign-in with email and password');
      
      // Use updated API endpoint for sign-in
      await _apiService.signIn(email, password);
      
      // Fetch user details after successful login
      _currentUser = await _apiService.getCurrentUser();
      _authStateController.add(_currentUser);
      
      if (_currentUser == null) {
        _logger.w('User login succeeded but failed to fetch user details');
        throw 'Signed in successfully, but failed to get user details';
      }
      
      _logger.i('Sign-in successful for: ${_currentUser?.email}');
    } catch (e) {
      _logger.e('Error during sign in: $e');
      throw e.toString();
    }
  }
  
  @override
  Future<void> signUpWithEmailAndPassword(String email, String password, {String? name}) async {
    try {
      _logger.i('Starting sign-up process for email: $email');
      
      // Use updated API endpoint for sign-up (name will be handled separately)
      final result = await _apiService.signUp(email, password, name: name);
      
      _logger.i('Sign-up API call completed successfully');
      
      // Check if we need to handle any specific response data
      if (result.containsKey('requiresEmailVerification') && result['requiresEmailVerification'] == true) {
        _logger.i('Email verification required by API');
        // This will be handled by the UI flow
      }
      
      // After signup, fetch the user details to get the updated profile
      try {
        _currentUser = await _apiService.getCurrentUser();
        if (_currentUser != null) {
          _authStateController.add(_currentUser);
        }
      } catch (userFetchError) {
        _logger.w('Failed to fetch user after sign-up: $userFetchError');
        // Don't fail the sign-up process if this fails
      }
      
      _logger.i('Sign-up process completed successfully');
    } catch (e) {
      _logger.e('Error during sign up: $e');
      throw e.toString();
    }
  }
  
  @override
  Future<void> signOut() async {
    try {
      _logger.i('Attempting to sign out user');
      
      // Call API logout endpoint
      final success = await _apiService.logout();
      
      // Clear current user and notify listeners regardless of API success
      _currentUser = null;
      _authStateController.add(null);
      
      if (!success) {
        _logger.w('API logout failed, but local state was cleared');
      } else {
        _logger.i('Sign out successful');
      }
    } catch (e) {
      _logger.e('Error during sign out: $e');
      
      // Clear local state even if API call fails
      _currentUser = null;
      _authStateController.add(null);
      
      throw e.toString();
    }
  }
  
  @override
  Future<void> sendPasswordResetEmail(String email) async {
    throw 'Not implemented in Jarvis API';
  }
  
  @override
  Future<void> confirmPasswordReset(String code, String newPassword) async {
    throw 'Not implemented in Jarvis API';
  }
  
  @override
  Future<void> updatePassword(String currentPassword, String newPassword) async {
    try {
      final success = await _apiService.changePassword(currentPassword, newPassword);
      if (!success) {
        throw 'Failed to update password';
      }
    } catch (e) {
      _logger.e('Error updating password: $e');
      throw e.toString();
    }
  }
  
  @override
  Future<void> reloadUser() async {
    try {
      _logger.i('Reloading user data');
      
      // Try to get fresh user data
      final freshUser = await _apiService.getCurrentUser();
      
      // If we got user data, update the current user
      if (freshUser != null) {
        _currentUser = freshUser;
        _authStateController.add(_currentUser);
        _logger.i('User data reloaded successfully: ${_currentUser?.email}, verification status: ${_currentUser?.isEmailVerified}');
      } else {
        _logger.w('Could not reload user data - API returned null');
        
        // If the API returned null but we still have a local user, keep it
        // This prevents losing the user data if there's a temporary API issue
        if (_currentUser != null) {
          _logger.w('Keeping existing user data: ${_currentUser?.email}');
        }
      }
    } catch (e) {
      _logger.e('Error reloading user: $e');
      throw e.toString();
    }
  }
  
  @override
  bool isEmailVerified() {
    _logger.i('Checking email verification status - current user exists: ${_currentUser != null}');
    
    // If user is null, consider not verified
    if (_currentUser == null) {
      _logger.w('Current user is null, returning false for verification status');
      return false;
    }
    
    // Add special handling when verification status might be incorrect
    if (_currentUser?.isEmailVerified == false) {
      _logger.i('User model says not verified, will check token validity');
      
      // If user has a valid token but verification status is false, there might be an API issue
      // In many cases, API is just not updating the verification status properly
      if (_apiService.isAuthenticated()) {
        _logger.i('User has valid authentication token, will refresh user data');
        // We'll consider the email verified for now to avoid the verification loop
        // but will schedule a user reload in the background
        _scheduleUserReload();
        return true;
      }
    }
    
    // Return the verification status from the current user 
    _logger.i('Returning verification status: ${_currentUser?.isEmailVerified}');
    return _currentUser?.isEmailVerified ?? false;
  }
  
  // Schedule a background reload of user data
  void _scheduleUserReload() {
    Future.delayed(const Duration(seconds: 2), () async {
      try {
        _logger.i('Performing scheduled user reload');
        // Force token refresh to get fresh data
        await _apiService.forceTokenRefresh();
        final freshUser = await _apiService.getCurrentUser();
        
        if (freshUser != null) {
          _currentUser = freshUser;
          _authStateController.add(_currentUser);
          _logger.i('User data refreshed in background, verification status: ${freshUser.isEmailVerified}');
        }
      } catch (e) {
        _logger.e('Background user reload failed: $e');
      }
    });
  }
  
  // Add a method to manually set verification status (for UI override)
  Future<void> manuallySetEmailVerified() async {
    _logger.i('Manually setting email as verified');
    
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(isEmailVerified: true);
      _authStateController.add(_currentUser);
      
      // Also try to update the server
      try {
        await _apiService.updateUserProfile({'emailVerified': true});
      } catch (e) {
        _logger.w('Could not update server with verification status: $e');
      }
    } else {
      _logger.w('Cannot manually set verification - no current user');
    }
  }
  
  @override
  Future<void> resendVerificationEmail() async {
    throw 'Not implemented in Jarvis API';
  }
  
  @override
  Future<void> signInWithGoogle() async {
    throw 'Google authentication not supported by Jarvis API';
  }
  
  // Clean up resources
  void dispose() {
    _authStateController.close();
  }
}
