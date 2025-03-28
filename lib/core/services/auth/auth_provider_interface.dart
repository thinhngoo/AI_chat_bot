import 'dart:async';
import '../../models/user_model.dart';

/// Interface for authentication providers
abstract class AuthProviderInterface {
  /// Initialize the auth provider
  Future<void> initialize();
  
  /// Get the current authenticated user
  UserModel? get currentUser;
  
  /// Check if user is logged in
  Future<bool> isLoggedIn();
  
  /// Check if email is verified
  bool isEmailVerified();
  
  /// Sign in with email and password
  Future<UserModel> signInWithEmailAndPassword(String email, String password);
  
  /// Sign up with email and password
  Future<UserModel> signUpWithEmailAndPassword(String email, String password, {String? name});
  
  /// Sign out the current user
  Future<void> signOut();
  
  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email);
  
  /// Refresh the auth tokens
  Future<bool> refreshToken();
  
  /// Refresh the user information
  Future<void> reloadUser();
  
  /// Confirm password reset
  Future<void> confirmPasswordReset(String code, String newPassword);
  
  /// Manually verify email
  Future<bool> manuallySetEmailVerified();
  
  /// Update user profile
  Future<bool> updateUserProfile(Map<String, dynamic> userData);
}