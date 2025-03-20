import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Windows-specific implementation that doesn't rely on Firebase Auth
class WindowsAuthService {
  final Logger _logger = Logger();
  
  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  // Get current user email
  Future<String?> getCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('currentUserEmail');
  }

  // Sign in with email and password
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final users = await getUsers();
      
      final user = users.firstWhere(
        (user) => user['email'] == email && user['password'] == password,
        orElse: () => {},
      );
      
      if (user.isEmpty) {
        throw 'Invalid login credentials';
      }
      
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('currentUserEmail', email);
      _logger.i('Sign in successful for: $email');
    } catch (e) {
      _logger.e('Sign in error: $e');
      throw e.toString();
    }
  }

  // Sign up with email and password
  Future<void> signUpWithEmailAndPassword(String email, String password) async {
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
      });
      
      await prefs.setString('users', jsonEncode(users));
      _logger.i('Sign up successful for: $email');
    } catch (e) {
      _logger.e('Sign up error: $e');
      throw e.toString();
    }
  }

  // Sign out
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('currentUserEmail');
    _logger.i('Sign out successful');
  }

  // Password reset (simulation)
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      final users = await getUsers();
      final userExists = users.any((user) => user['email'] == email);
      
      if (!userExists) {
        throw 'No user found with this email';
      }
      
      _logger.i('Password reset email would be sent to: $email');
    } catch (e) {
      _logger.e('Password reset error: $e');
      throw e.toString();
    }
  }

  // Always return true for Windows
  bool isEmailVerified() => true;

  // No-op for Windows
  Future<void> reloadUser() async {}

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

  // Mock Google sign in
  Future<void> signInWithGoogle() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('currentUserEmail', 'google_user@example.com');
      _logger.i('Mock Google sign-in successful');
    } catch (e) {
      _logger.e('Google sign-in error: $e');
      throw 'Failed to sign in with Google';
    }
  }
}
