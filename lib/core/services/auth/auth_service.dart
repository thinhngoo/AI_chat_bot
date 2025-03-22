import 'package:logger/logger.dart';
import 'platform/desktop/windows_auth_service.dart';  // Add this import back
import 'providers/firebase_auth_provider.dart';
import 'auth_provider_interface.dart';

class AuthService {
  final Logger _logger = Logger();
  late final AuthProviderInterface _auth;
  bool _firebaseInitialized = false;
  
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  
  AuthService._internal() {
    _initializeAuth();
  }
  
  // Modified to prioritize Firebase Auth for all platforms
  void _initializeAuth() {
    try {
      // Always try Firebase first, regardless of platform
      _auth = FirebaseAuthProvider();
      _logger.i('Using Firebase authentication provider');
    } catch (e) {
      // Only use WindowsAuthService as fallback if Firebase fails
      _logger.w('Firebase provider creation failed, using fallback: $e');
      _auth = WindowsAuthService();
    }
  }

  // Set Firebase initialization status
  void setFirebaseInitialized(bool status) {
    _firebaseInitialized = status;
    
    // Only switch to fallback if we're using Firebase but it failed
    if (!status && _auth is FirebaseAuthProvider) {
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
  
  // Method to get auth state changes
  Stream<dynamic> authStateChanges() {
    return _auth.authStateChanges();
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

  // Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      await _auth.signInWithGoogle();
    } catch (e) {
      _logger.e('Lỗi đăng nhập Google: $e');
      throw e.toString();
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