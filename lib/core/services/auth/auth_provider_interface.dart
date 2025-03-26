abstract class AuthProviderInterface {
  dynamic get currentUser;
  
  Stream<dynamic> authStateChanges();
  
  Future<bool> isLoggedIn();
  
  Future<void> signInWithEmailAndPassword(String email, String password);
  
  // Update to support additional user data
  Future<void> signUpWithEmailAndPassword(String email, String password, {String? name});
  
  Future<void> signOut();
  
  Future<void> sendPasswordResetEmail(String email);
  
  bool isEmailVerified();
  
  Future<void> reloadUser();
  
  Future<void> signInWithGoogle();
  
  Future<void> resendVerificationEmail();
  
  // Add method for confirming password reset
  Future<void> confirmPasswordReset(String code, String newPassword);
  
  // Add method for updating password
  Future<void> updatePassword(String currentPassword, String newPassword);
}