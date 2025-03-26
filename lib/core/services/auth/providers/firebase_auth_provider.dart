import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart'; // For PlatformException
import 'dart:math'; // Add this import for min function
import 'dart:io' if (dart.library.html) 'dart:html'; // Conditional import
import '../../../models/user_model.dart';
import '../auth_provider_interface.dart';
import '../../firestore/firestore_service.dart';

class FirebaseAuthProvider implements AuthProviderInterface {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final Logger _logger = Logger();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Stream<User?> authStateChanges() {
    return _firebaseAuth.authStateChanges();
  }

  @override
  Future<bool> isLoggedIn() async {
    return _firebaseAuth.currentUser != null;
  }

  @override
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      _logger.e('Firebase Auth error: ${e.code} - ${e.message}');
      
      // Provide more user-friendly error messages
      switch (e.code) {
        case 'user-not-found':
          throw 'Tài khoản không tồn tại';
        case 'wrong-password':
          throw 'Mật khẩu không đúng';
        case 'invalid-email':
          throw 'Email không hợp lệ';
        case 'user-disabled':
          throw 'Tài khoản đã bị vô hiệu hóa';
        case 'too-many-requests':
          throw 'Quá nhiều yêu cầu, vui lòng thử lại sau';
        default:
          throw e.message ?? 'Lỗi xác thực không xác định';
      }
    } catch (e) {
      _logger.e('Non-Firebase Auth error: $e');
      throw 'Đã xảy ra lỗi khi đăng nhập';
    }
  }

  @override
  Future<void> signUpWithEmailAndPassword(String email, String password, {String? name}) async {
    try {
      // Create user in Firebase Authentication
      UserCredential result = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Save additional user data to Firestore
      if (result.user != null) {
        UserModel userModel = UserModel(
          uid: result.user!.uid,
          email: email,
          name: name,
          createdAt: DateTime.now(),
          isEmailVerified: false,
        );
        
        await _firestoreService.saveUserData(userModel);
      }
      
      // Send email verification
      await result.user?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      _logger.e('Firebase Auth error during signup: ${e.code} - ${e.message}');
      
      switch (e.code) {
        case 'email-already-in-use':
          throw 'Email already exists';
        case 'invalid-email':
          throw 'Email không hợp lệ';
        case 'weak-password':
          throw 'Mật khẩu quá yếu';
        case 'operation-not-allowed':
          throw 'Đăng ký bằng email và mật khẩu không được bật';
        default:
          throw e.message ?? 'Lỗi đăng ký không xác định';
      }
    } catch (e) {
      _logger.e('Error signing up: $e');
      throw 'Đã xảy ra lỗi khi đăng ký';
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      _logger.e('Error signing out: $e');
      throw 'Lỗi khi đăng xuất';
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      _logger.e('Error sending password reset: ${e.code} - ${e.message}');
      
      switch (e.code) {
        case 'user-not-found':
          throw 'Không tìm thấy người dùng với email này';
        case 'invalid-email':
          throw 'Email không hợp lệ';
        default:
          throw e.message ?? 'Lỗi đặt lại mật khẩu không xác định';
      }
    } catch (e) {
      _logger.e('Error sending password reset: $e');
      throw 'Lỗi gửi email đặt lại mật khẩu';
    }
  }

  @override
  bool isEmailVerified() {
    User? user = _firebaseAuth.currentUser;
    return user?.emailVerified ?? false;
  }

  @override
  Future<void> reloadUser() async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.reload();
        
        // Update email verification status in Firestore if needed
        if (user.emailVerified) {
          await _firestoreService.updateEmailVerificationStatus(user.uid, true);
        }
      }
    } catch (e) {
      _logger.e('Error reloading user: $e');
      throw 'Lỗi cập nhật thông tin người dùng';
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      // Different approach based on platform
      late final UserCredential? result;
      
      if (kIsWeb) {
        _logger.i('Attempting Google sign in (Web)');
        
        // Web implementation uses Firebase Auth directly
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        
        // Use signInWithPopup for better UX on web
        result = await _firebaseAuth.signInWithPopup(googleProvider);
      } else {
        _logger.i('Attempting Google sign in (Native platforms)');
        
        try {
          // Check for MissingPluginException early to avoid deeper errors
          try {
            // First, check if GoogleSignIn class can be instantiated at all
            // This will throw MissingPluginException if the plugin is completely missing
            final testInstance = GoogleSignIn();
            await testInstance.isSignedIn().timeout(const Duration(seconds: 1));
            _logger.i('GoogleSignIn plugin is available and initialized');
          } catch (e) {
            if (e is MissingPluginException || e.toString().contains('MissingPluginException')) {
              _logger.w('GoogleSignIn plugin is completely missing: $e');
              throw 'plugin_not_supported';
            }
            // Other errors are ok at this point, might just be initialization errors
            _logger.w('Non-critical Google Sign-In initialization error: $e');
          }
          
          // Select appropriate client ID based on platform
          final String? clientId;
          if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
            clientId = dotenv.env['GOOGLE_DESKTOP_CLIENT_ID'] ?? 
                      dotenv.env['GOOGLE_CLIENT_ID'];
            _logger.i('Using Desktop OAuth client ID for desktop platform');
          } else {
            clientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? 
                      dotenv.env['GOOGLE_CLIENT_ID'];
            _logger.i('Using Web OAuth client ID for mobile platform');
          }
          
          _logger.i('Using Google client ID: ${clientId != null ? 
              "${clientId.substring(0, min(10, clientId.length))}..." : "not found"}');
          
          // Initialize GoogleSignIn with the appropriate client ID
          // Fix: Remove redundant null check for kIsWeb (it can't be null)
          final GoogleSignIn googleSignIn = GoogleSignIn(
            clientId: kIsWeb ? null : clientId,
            scopes: ['email', 'profile'],
          );
          
          _logger.i('Starting Google Sign-In flow');
          final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
          
          if (googleUser == null) {
            _logger.w('Google Sign-In was canceled by user');
            throw 'Đăng nhập đã bị hủy';
          }
          
          _logger.i('Getting auth credentials');
          final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
          
          if (googleAuth.idToken == null) {
            _logger.e('Failed to get ID token from Google');
            throw 'Không thể xác thực với Firebase';
          }
          
          _logger.i('Creating Firebase credential');
          final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          
          _logger.i('Signing in to Firebase with credential');
          result = await _firebaseAuth.signInWithCredential(credential);
          _logger.i('Firebase sign in complete');
        } catch (e) {
          if (e == 'plugin_not_supported' || 
              e is MissingPluginException || 
              e.toString().contains('MissingPluginException') ||
              (e is PlatformException && e.code == 'sign_in_failed')) {
            _logger.w('Using fallback for Google Sign-In: $e');
            throw 'plugin_not_supported';
          } else {
            _logger.e('Error during Google Sign-In: $e');
            rethrow;
          }
        }
      }
      
      // Save user data to Firestore
      if (result.user != null) {
        _logger.i('Saving user data to Firestore for: ${result.user!.email}');
        
        UserModel userModel = UserModel(
          uid: result.user!.uid,
          email: result.user!.email ?? '',
          name: result.user!.displayName,
          createdAt: DateTime.now(),
          isEmailVerified: true, // Google accounts are verified
        );
        
        await _firestoreService.saveUserData(userModel);
        _logger.i('User data saved successfully');
      } else {
        _logger.w('No user data received from Firebase');
        throw 'Không nhận được thông tin người dùng';
      }
    } catch (e) {
      // Handle specific Firebase Auth exceptions
      if (e is FirebaseAuthException) {
        _logger.e('Firebase Auth error during Google sign-in: ${e.code}');
        
        switch (e.code) {
          case 'account-exists-with-different-credential':
            throw 'Tài khoản này đã tồn tại với phương thức đăng nhập khác';
          case 'invalid-credential':
            throw 'Thông tin đăng nhập không hợp lệ';
          case 'operation-not-allowed':
            throw 'Đăng nhập bằng Google chưa được bật trong Firebase Console';
          case 'user-disabled':
            throw 'Tài khoản đã bị vô hiệu hóa';
          default:
            throw e.message ?? 'Lỗi đăng nhập không xác định';
        }
      } 
      // Special case for our custom error
      else if (e.toString() == 'plugin_not_supported') {
        throw 'plugin_not_supported';
      }
      // Generic error handling
      else {
        _logger.e('Error during Google sign-in: $e');
        throw 'Đã xảy ra lỗi khi đăng nhập với Google';
      }
    }
  }

  @override
  Future<void> resendVerificationEmail() async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
        _logger.i('Verification email resent to ${user.email}');
      } else {
        _logger.w('Attempted to resend verification email but no user is logged in');
        throw 'Người dùng chưa đăng nhập, không thể gửi lại email xác minh';
      }
    } catch (e) {
      _logger.e('Error resending verification email: $e');
      throw 'Lỗi gửi lại email xác minh';
    }
  }
  
  bool isInitialized() {
    try {
      // Just access the instance to verify it exists
      FirebaseAuth.instance;
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> confirmPasswordReset(String code, String newPassword) async {
    try {
      await _firebaseAuth.confirmPasswordReset(
        code: code,
        newPassword: newPassword,
      );
    } on FirebaseAuthException catch (e) {
      _logger.e('Error confirming password reset: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'expired-action-code':
          throw 'Mã đặt lại mật khẩu đã hết hạn. Vui lòng yêu cầu mã mới.';
        case 'invalid-action-code':
          throw 'Mã đặt lại mật khẩu không hợp lệ. Vui lòng thử lại.';
        case 'user-disabled':
          throw 'Tài khoản người dùng đã bị vô hiệu hóa.';
        case 'user-not-found':
          throw 'Không tìm thấy tài khoản người dùng.';
        case 'weak-password':
          throw 'Mật khẩu mới quá yếu. Vui lòng chọn mật khẩu mạnh hơn.';
        default:
          throw e.message ?? 'Không thể đặt lại mật khẩu.';
      }
    } catch (e) {
      _logger.e('Error during password reset confirmation: $e');
      throw 'Lỗi xác nhận đặt lại mật khẩu';
    }
  }

  @override
  Future<void> updatePassword(String currentPassword, String newPassword) async {
    try {
      final user = _firebaseAuth.currentUser;
      
      if (user == null) {
        _logger.e('No user is currently logged in');
        throw 'Không có người dùng nào đang đăng nhập';
      }
      
      // Get user's sign-in methods to determine how to re-authenticate
      List<String> providers = [];
      try {
        final userInfo = await _firebaseAuth.fetchSignInMethodsForEmail(user.email ?? '');
        providers = userInfo.toList();
        _logger.i('User sign-in methods: $providers');
      } catch (e) {
        _logger.w('Error fetching sign-in methods: $e');
        // Continue anyway, we'll try password auth by default
      }
      
      // If user originally signed in with Google or other providers
      if (providers.contains('google.com') && !providers.contains('password')) {
        _logger.i('User signed in with Google. Cannot update password directly.');
        throw 'Tài khoản này đăng nhập bằng Google. Không thể cập nhật mật khẩu qua ứng dụng.';
      }
      
      if (user.email == null) {
        _logger.e('Current user has no email');
        throw 'Người dùng hiện tại không có email';
      }
      
      try {
        // For Firebase, we need to re-authenticate before changing password
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        
        // Re-authenticate
        _logger.i('Re-authenticating user before password change');
        await user.reauthenticateWithCredential(credential);
        
        // Update password
        _logger.i('Updating password for user: ${user.email}');
        await user.updatePassword(newPassword);
        
        _logger.i('Password updated successfully');
      } on FirebaseAuthException catch (e) {
        _logger.e('Firebase Auth error during re-authentication or password update: ${e.code} - ${e.message}');
        
        switch (e.code) {
          case 'wrong-password':
            throw 'Mật khẩu hiện tại không đúng';
          case 'weak-password':
            throw 'Mật khẩu mới quá yếu';
          case 'requires-recent-login':
            throw 'Phiên đăng nhập đã hết hạn. Vui lòng đăng xuất và đăng nhập lại để thực hiện thao tác này';
          case 'invalid-credential':
            // This commonly happens if the user originally signed in with a different method
            if (providers.isNotEmpty && !providers.contains('password')) {
              throw 'Không thể cập nhật mật khẩu. Tài khoản này sử dụng phương thức đăng nhập: ${_formatProviderNames(providers)}';
            } else {
              throw 'Mật khẩu hiện tại không đúng hoặc phiên đăng nhập đã hết hạn';
            }
          default:
            throw e.message ?? 'Lỗi không xác định khi cập nhật mật khẩu';
        }
      } catch (e) {
        _logger.e('Error updating password: $e');
        throw 'Đã xảy ra lỗi khi cập nhật mật khẩu: $e';
      }
    } catch (e) {
      if (e is String) {
        throw e;
      } else {
        _logger.e('Unexpected error in updatePassword: $e');
        throw 'Lỗi cập nhật mật khẩu: ${e.toString()}';
      }
    }
  }

  // Helper method to format provider names for user-friendly messages
  String _formatProviderNames(List<String> providers) {
    final Map<String, String> providerNames = {
      'google.com': 'Google',
      'facebook.com': 'Facebook',
      'twitter.com': 'Twitter',
      'github.com': 'GitHub',
      'apple.com': 'Apple',
      'password': 'Email/Mật khẩu',
      'phone': 'Số điện thoại',
    };
    
    return providers.map((provider) => 
      providerNames[provider] ?? provider
    ).join(', ');
  }
}