import 'dart:async';
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth_provider_interface.dart';
import 'windows_google_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add Firebase Auth import
import '../../../firestore/firestore_service.dart'; // Add Firestore service for user data
import '../../../../models/user_model.dart'; // Add User model

class WindowsAuthService implements AuthProviderInterface {
  final Logger _logger = Logger();
  String? _currentUserEmail;
  final WindowsGoogleAuthService _googleAuthService = WindowsGoogleAuthService();
  final FirestoreService _firestoreService = FirestoreService(); // Add Firestore service
  
  // Stream controller for auth state changes
  final StreamController<String?> _authStateController = StreamController<String?>.broadcast();
  bool _isInitialized = false;
  
  WindowsAuthService() {
    _logger.i('WindowsAuthService constructor called');
    _initAuthState();
  }
  
  // Initialize auth state
  Future<void> _initAuthState() async {
    try {
      _logger.i('WindowsAuthService initializing auth state');
      // Get current user email
      final email = await getCurrentUserEmail();
      _currentUserEmail = email;
      
      // Add the current state to the stream controller immediately
      _authStateController.add(email);
      _isInitialized = true;
      _logger.i('WindowsAuthService initialized with current user: ${email ?? "null"}');
    } catch (e) {
      _logger.e('Error initializing auth state: $e');
      // Even on error, we should emit a value (null) to prevent StreamBuilder from hanging
      _authStateController.add(null);
      _isInitialized = true;
    }
  }
  
  @override
  dynamic get currentUser => _currentUserEmail;
  
  @override
  Stream<String?> authStateChanges() {
    _logger.i('authStateChanges() called, isInitialized: $_isInitialized');
    
    if (!_isInitialized) {
      // If not initialized yet, create a stream that first waits for initialization
      return _createSafeAuthStream();
    }
    
    _logger.i('Returning auth state stream, current user: ${_currentUserEmail ?? "null"}');
    return _authStateController.stream;
  }
  
  // Create a safe auth stream that ensures a value is always emitted
  Stream<String?> _createSafeAuthStream() {
    _logger.i('Creating safe auth stream');
    
    // Create a controller for the safe stream
    final controller = StreamController<String?>();
    
    // Add the current value immediately if we have it
    if (_isInitialized) {
      _logger.i('Adding current user to safe stream: ${_currentUserEmail ?? "null"}');
      controller.add(_currentUserEmail);
    }
    
    // Wait for initialization if necessary
    Future.delayed(const Duration(milliseconds: 500), () async {
      if (!_isInitialized) {
        _logger.i('Waiting for initialization to complete...');
        // Wait up to 3 seconds for initialization
        for (int i = 0; i < 6; i++) {
          await Future.delayed(const Duration(milliseconds: 500));
          if (_isInitialized) break;
        }
      }
      
      // At this point, either initialized or timed out, emit current state
      if (!controller.isClosed) {
        _logger.i('Emitting current state after delay: ${_currentUserEmail ?? "null"}');
        controller.add(_currentUserEmail);
        
        // Forward future events from the main controller
        _authStateController.stream.listen(
          (user) {
            if (!controller.isClosed) {
              _logger.i('Forwarding auth state change: ${user ?? "null"}');
              controller.add(user);
            }
          },
          onError: (e) {
            if (!controller.isClosed) {
              _logger.e('Error in auth stream: $e');
              controller.addError(e);
            }
          }
        );
      }
    });
    
    return controller.stream;
  }
  
  // Check if user is logged in
  @override
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    _logger.i('isLoggedIn check returned: $isLoggedIn');
    return isLoggedIn;
  }

  // Get current user email
  Future<String?> getCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('currentUserEmail');
    _logger.i('getCurrentUserEmail returned: ${email ?? "null"}');
    return email;
  }

  // Sign in with email and password
  @override
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final users = await getUsers();
      
      final user = users.firstWhere(
        (user) => user['email'] == email && user['password'] == password,
        orElse: () => {},
      );
      
      if (user.isEmpty) {
        throw 'Tài khoản hoặc mật khẩu không đúng';
      }
      
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('currentUserEmail', email);
      _currentUserEmail = email;
      _logger.i('Sign in successful for: $email');
      
      // Update auth state
      _authStateController.add(email);
    } catch (e) {
      _logger.e('Sign in error: $e');
      throw e.toString();
    }
  }

  // Sign up with email and password - updated to match new interface
  @override
  Future<void> signUpWithEmailAndPassword(String email, String password, {String? name}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final users = await getUsers();
      
      // Check if email already exists
      if (users.any((user) => user['email'] == email)) {
        throw 'Email already exists';
      }
      
      users.add({
        'email': email,
        'password': password,
        'isVerified': true, // Auto-verify on Windows
        'name': name ?? '',
        'createdAt': DateTime.now().toIso8601String(),
      });
      
      await prefs.setString('users', jsonEncode(users));
      _logger.i('Sign up successful for: $email');
    } catch (e) {
      _logger.e('Sign up error: $e');
      throw e.toString();
    }
  }

  // Sign out
  @override
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('currentUserEmail');
    _currentUserEmail = null;
    _logger.i('Sign out successful');
    
    // Update auth state
    _authStateController.add(null);
  }

  // Password reset (simulation)
  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      final users = await getUsers();
      final userExists = users.any((user) => user['email'] == email);
      
      if (!userExists) {
        throw 'Không tìm thấy người dùng với email này';
      }
      
      _logger.i('Password reset email would be sent to: $email');
    } catch (e) {
      _logger.e('Password reset error: $e');
      throw e.toString();
    }
  }

  // Always return true for Windows
  @override
  bool isEmailVerified() => true;

  // No-op for Windows
  @override
  Future<void> reloadUser() async {
    _currentUserEmail = await getCurrentUserEmail();
  }

  // Retrieve users from SharedPreferences
  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString('users');
      
      if (usersJson == null) {
        return [];
      }
      
      final List<dynamic> decoded = jsonDecode(usersJson);
      return decoded.map((user) => Map<String, dynamic>.from(user)).toList();
    } catch (e) {
      _logger.e('Error retrieving users: $e');
      return [];
    }
  }

  // Update Google sign in to use WindowsGoogleAuthService
  @override
  Future<void> signInWithGoogle() async {
    try {
      _logger.i('Attempting Google sign in on Windows platform');
      
      // Get the global navigation key or BuildContext somehow
      // This is tricky without a global context - we'll need to use a workaround
      
      // Store the authentication state temporarily in shared preferences
      final authState = await _googleAuthService.startGoogleAuth();
      
      if (authState != null && authState.containsKey('email')) {
        final email = authState['email'] as String;
        final name = authState['name'] as String?;
        
        // Check if Firebase authentication was successful
        if (authState.containsKey('firebaseUid')) {
          final firebaseUid = authState['firebaseUid'] as String;
          _logger.i('Firebase authentication successful with UID: $firebaseUid');
          
          // The user is already signed in to Firebase at this point
          // Get current Firebase user for additional verification
          final currentUser = FirebaseAuth.instance.currentUser;
          
          if (currentUser != null) {
            // We have a valid Firebase user, save additional data to Firestore
            UserModel userModel = UserModel(
              uid: currentUser.uid,
              email: email,
              name: name,
              createdAt: DateTime.now(),
              isEmailVerified: true, // Google accounts are already verified
            );
            
            try {
              await _firestoreService.saveUserData(userModel);
              _logger.i('User data saved to Firestore: $email');
            } catch (e) {
              _logger.e('Error saving user data to Firestore: $e');
              // Continue with the login process even if Firestore save fails
            }
          }
        } else {
          _logger.w('Firebase authentication failed or was not attempted. Using local authentication.');
        }
        
        // Create or update user in local storage as fallback
        final prefs = await SharedPreferences.getInstance();
        final users = await getUsers();
        
        // Check if user already exists
        if (users.any((user) => user['email'] == email)) {
          // User exists, just log them in
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('currentUserEmail', email);
          _currentUserEmail = email;
          _authStateController.add(email);
        } else {
          // Create new user
          users.add({
            'email': email,
            'password': '', // Google users don't have passwords
            'isVerified': true,
            'name': name ?? '',
            'loginType': 'google',
            'createdAt': DateTime.now().toIso8601String(),
          });
          await prefs.setString('users', jsonEncode(users));
          
          // Log them in
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('currentUserEmail', email);
          _currentUserEmail = email;
          _authStateController.add(email);
        }
        
        _logger.i('Google sign in successful for: $email');
      } else {
        throw 'Google Sign-In was cancelled or failed';
      }
    } catch (e) {
      _logger.e('Google sign-in error: $e');
      throw e.toString();
    }
  }
  
  @override
  Future<void> resendVerificationEmail() async {
    // For Windows, we just simulate this since verification is auto-approved
    _logger.i('Simulating resend verification email on Windows platform');
  }
  
  @override
  Future<void> confirmPasswordReset(String code, String newPassword) async {
    try {
      _logger.i('Password reset confirmation - Windows simulated implementation');
      
      // For Windows service, we'll simulate the password reset
      // In a real app, you might use a different approach for desktop
      
      // Extract email from code (this is just a simulation)
      // In a real implementation, the code might contain the email or user identifier
      final userEmail = code.split('_').lastOrNull ?? '';
      
      final users = await getUsers();
      final userIndex = users.indexWhere((user) => 
          user['email'] == userEmail || user['resetCode'] == code);
      
      if (userIndex == -1) {
        throw 'Mã đặt lại mật khẩu không hợp lệ hoặc đã hết hạn';
      }
      
      // Update the user's password
      users[userIndex]['password'] = newPassword;
      users[userIndex]['resetCode'] = null; // Clear the reset code
      
      // Save updated users list
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('users', jsonEncode(users));
      
      _logger.i('Password reset confirmed for simulation');
    } catch (e) {
      _logger.e('Error confirming password reset: $e');
      throw e.toString();
    }
  }

  @override
  Future<void> updatePassword(String currentPassword, String newPassword) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final users = await getUsers();
      final currentUserEmail = await getCurrentUserEmail();
      
      if (currentUserEmail == null) {
        throw 'Không có người dùng nào đang đăng nhập';
      }
      
      // Find current user
      final userIndex = users.indexWhere((user) => user['email'] == currentUserEmail);
      
      if (userIndex == -1) {
        throw 'Không tìm thấy người dùng trong cơ sở dữ liệu';
      }
      
      // Verify current password
      if (users[userIndex]['password'] != currentPassword) {
        throw 'Mật khẩu hiện tại không đúng';
      }
      
      // Update password
      users[userIndex]['password'] = newPassword;
      
      // Save back to SharedPreferences
      await prefs.setString('users', jsonEncode(users));
      
      _logger.i('Password updated successfully for: $currentUserEmail');
    } catch (e) {
      _logger.e('Error updating password: $e');
      throw e.toString();
    }
  }

  // Clean up resources
  void dispose() {
    _logger.i('Disposing WindowsAuthService');
    _authStateController.close();
  }
}