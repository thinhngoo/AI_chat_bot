import 'package:logger/logger.dart';
import 'platform_service_helper.dart';

// Import conditionally to avoid errors on Windows
import 'package:firebase_auth/firebase_auth.dart' if (dart.library.io) 'windows_auth_stub.dart';
import 'windows_auth_service.dart';

class AuthService {
  final Logger _logger = Logger();
  late final dynamic _auth;
  final bool _useWindowsAuth = PlatformServiceHelper.isDesktopWindows;
  
  AuthService() {
    if (_useWindowsAuth) {
      _auth = WindowsAuthService();
      _logger.i('Using Windows Auth Service');
    } else {
      _auth = FirebaseAuth.instance;
      _logger.i('Using Firebase Auth Service');
    }
  }

  // Method to get currently logged in user
  dynamic get currentUser => _useWindowsAuth ? null : _auth.currentUser;

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    if (_useWindowsAuth) {
      return await _auth.isLoggedIn();
    }
    return _auth.currentUser != null;
  }

  // Sign in with email and password
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      if (_useWindowsAuth) {
        await _auth.signInWithEmailAndPassword(email, password);
      } else {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
      _logger.i('Đăng nhập thành công');
    } catch (e) {
      _logger.e('Lỗi đăng nhập: $e');
      throw e.toString();
    }
  }

  // Sign up with email and password
  Future<void> signUpWithEmailAndPassword(String email, String password) async {
    try {
      if (_useWindowsAuth) {
        await _auth.signUpWithEmailAndPassword(email, password);
      } else {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        // Send email verification
        await userCredential.user!.sendEmailVerification();
      }
      
      _logger.i('Đăng ký thành công, email xác minh đã được gửi');
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
    if (_useWindowsAuth) {
      await _auth.signOut();
    } else {
      await _auth.signOut();
    }
    _logger.i('Đăng xuất thành công');
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      if (_useWindowsAuth) {
        await _auth.sendPasswordResetEmail(email);
      } else {
        await _auth.sendPasswordResetEmail(email: email);
      }
      _logger.i('Email đặt lại mật khẩu đã được gửi');
    } catch (e) {
      _logger.e('Lỗi gửi email đặt lại mật khẩu: $e');
      throw e.toString();
    }
  }

  // Check if email is verified
  bool isEmailVerified() {
    if (_useWindowsAuth) {
      return _auth.isEmailVerified();
    }
    
    User? user = _auth.currentUser;
    return user != null && user.emailVerified;
  }

  // Reload user to check if email has been verified
  Future<void> reloadUser() async {
    if (_useWindowsAuth) {
      await _auth.reloadUser();
      return;
    }
    
    User? user = _auth.currentUser;
    if (user != null) {
      await user.reload();
    }
  }

  // Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      if (_useWindowsAuth) {
        await _auth.signInWithGoogle();
      } else {
        // Implementation would normally go here
        throw Exception('Google sign-in not fully implemented');
      }
    } catch (e) {
      _logger.e('Lỗi đăng nhập Google: $e');
      throw 'Đăng nhập với Google thất bại';
    }
  }
}