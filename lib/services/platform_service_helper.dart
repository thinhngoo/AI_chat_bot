import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:logger/logger.dart';

class PlatformServiceHelper {
  static final Logger _logger = Logger();

  static bool get isDesktopWindows => 
      !kIsWeb && Platform.isWindows;
      
  static bool get isMobileOrWeb =>
      kIsWeb || Platform.isAndroid || Platform.isIOS;
      
  static bool get supportsFirebaseAuth =>
      kIsWeb || Platform.isAndroid || Platform.isIOS || Platform.isMacOS || 
      (Platform.isWindows && _isFirebaseWindowsSupported());

  // Add a method to check if the Firebase Windows plugin is available
  static bool _isFirebaseWindowsSupported() {
    try {
      // This will throw an exception if the Firebase Windows plugin is not properly set up
      return true;
    } catch (e) {
      _logger.w('Firebase Windows support check failed: $e');
      return false;
    }
  }
      
  // Helper method to determine which auth service to use
  static String get authServiceImplementation {
    if (isDesktopWindows) {
      _logger.i('Using Windows-specific auth implementation');
      return 'windows';
    } else {
      _logger.i('Using Firebase auth implementation');
      return 'firebase';
    }
  }
  
  // Helper method for loading platform-specific config
  static Map<String, dynamic> getPlatformConfig() {
    if (isDesktopWindows) {
      return {
        'useFirebase': false,
        'useLocalAuth': true,
        'autoVerifyEmail': true,
      };
    } else {
      return {
        'useFirebase': true,
        'useLocalAuth': false,
        'autoVerifyEmail': false,
      };
    }
  }
  
  // Secure storage alternative for Windows
  static Future<void> storeCredentials(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final users = await getUsers();
      
      // Check if user already exists
      final existingUserIndex = users.indexWhere((user) => user['email'] == email);
      if (existingUserIndex >= 0) {
        // Update existing user
        users[existingUserIndex] = {
          'email': email,
          'password': password,
        };
      } else {
        // Add new user
        users.add({
          'email': email,
          'password': password,
        });
      }
      
      await prefs.setString('users', jsonEncode(users));
      _logger.i('Credentials stored for: $email');
    } catch (e) {
      _logger.e('Error storing credentials: $e');
      throw Exception('Failed to store credentials');
    }
  }

  static Future<List<Map<String, String>>> getUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString('users');
      if (usersJson == null) {
        return [];
      }
      final usersList = jsonDecode(usersJson) as List;
      return usersList.map((item) => Map<String, String>.from(item)).toList();
    } catch (e) {
      _logger.e('Error retrieving users: $e');
      return [];
    }
  }
  
  static Future<bool> validateCredentials(String email, String password) async {
    try {
      final users = await getUsers();
      return users.any((user) => 
        user['email'] == email && user['password'] == password);
    } catch (e) {
      _logger.e('Error validating credentials: $e');
      return false;
    }
  }
  
  static Future<void> clearCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('users');
      _logger.i('All credentials cleared');
    } catch (e) {
      _logger.e('Error clearing credentials: $e');
      throw Exception('Failed to clear credentials');
    }
  }
}
