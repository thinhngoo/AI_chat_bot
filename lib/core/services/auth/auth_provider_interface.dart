import 'dart:async';

/// Interface that all auth providers must implement
abstract class AuthProviderInterface {
  /// Get the current user
  dynamic get currentUser;
  
  /// Get stream of auth state changes
  Stream<dynamic> authStateChanges();
  
  /// Check if a user is currently logged in
  Future<bool> isLoggedIn();
  
  /// Sign in with email and password
  Future<void> signInWithEmailAndPassword(String email, String password);
  
  /// Sign up with email and password
  Future<void> signUpWithEmailAndPassword(String email, String password, {String? name});
  
  /// Sign out the current user
  Future<void> signOut();
  
  /// Send a password reset email
  Future<void> sendPasswordResetEmail(String email);
  
  /// Confirm password reset with code and new password
  Future<void> confirmPasswordReset(String code, String newPassword);
  
  /// Update user password
  Future<void> updatePassword(String currentPassword, String newPassword);
  
  /// Reload the current user data
  Future<void> reloadUser();
  
  /// Check if the current user's email is verified
  bool isEmailVerified();
  
  /// Resend verification email to current user
  Future<void> resendVerificationEmail();
  
  /// Sign in with Google
  Future<void> signInWithGoogle();
}