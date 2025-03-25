import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:logger/logger.dart';

class PlatformServiceHelper {
  static final Logger _logger = Logger();
  
  // Pre-calculate platform info immediately at class load time
  static final Map<String, dynamic> _platformCache = _initPlatformCache();
  
  // Initialize platform cache once at startup with a safer approach
  static Map<String, dynamic> _initPlatformCache() {
    final Map<String, dynamic> cache = {};
    
    try {
      // Detect platform with minimal overhead
      final bool isWeb = kIsWeb;
      String platform;
      bool supportsFirebase;
      
      if (isWeb) {
        platform = 'web';
        supportsFirebase = true;
      } else {
        try {
          // Log platform details to help with debugging
          // Avoid excessive logging that might slow down startup
          final String operatingSystem = Platform.operatingSystem;
          
          if (operatingSystem == 'android') {
            platform = 'android';
            supportsFirebase = true;
          } else if (operatingSystem == 'ios') {
            platform = 'ios';
            supportsFirebase = true;
          } else if (operatingSystem == 'macos') {
            platform = 'macos';
            supportsFirebase = true;
          } else if (operatingSystem == 'windows') {
            platform = 'windows';
            supportsFirebase = true; // We can use Firebase on Windows, but not google_sign_in
          } else if (operatingSystem == 'linux') {
            platform = 'linux';
            supportsFirebase = false;
          } else {
            platform = 'unknown';
            supportsFirebase = false;
          }
          
          Logger().i('Platform detection - OS: $operatingSystem');
        } catch (e) {
          // Fallback for any platform detection errors
          Logger().e('Error detecting platform: $e');
          platform = 'unknown';
          supportsFirebase = false;
        }
      }
      
      // Cache platform information
      cache['platform'] = platform;
      cache['supportsFirebase'] = supportsFirebase;
      cache['isWeb'] = isWeb;
      cache['isDesktopWindows'] = !isWeb && platform == 'windows';
      cache['isMobileOrWeb'] = isWeb || platform == 'android' || platform == 'ios';
      
      // Create platform info result map
      final Map<String, dynamic> platformInfo = {
        'platform': platform,
        'supportsFirebase': supportsFirebase,
        'isDesktop': platform == 'windows' || platform == 'macos' || platform == 'linux',
        'isMobile': platform == 'android' || platform == 'ios',
        'isWeb': isWeb,
      };
      
      cache['platformInfo'] = platformInfo;
      
    } catch (e) {
      // Fallback in case of any error
      Logger().e('Error in platform detection: $e');
      cache['platform'] = 'unknown';
      cache['supportsFirebase'] = false;
      cache['isWeb'] = false;
      cache['isDesktopWindows'] = false;
      cache['isMobileOrWeb'] = false;
      cache['platformInfo'] = {
        'platform': 'unknown',
        'supportsFirebase': false,
        'isDesktop': false,
        'isMobile': false,
        'isWeb': false,
        'error': true,
      };
    }
    
    return cache;
  }

  // Fast getters that use pre-calculated values  
  static bool get isDesktopWindows => _platformCache['isDesktopWindows'] as bool;
  static bool get isMobileOrWeb => _platformCache['isMobileOrWeb'] as bool;
  static bool get supportsFirebaseAuth => _platformCache['supportsFirebase'] as bool;
  
  // Return the cached platform info immediately
  static Map<String, dynamic> getPlatformInfo() {
    return _platformCache['platformInfo'] as Map<String, dynamic>;
  }
  
  // Helper method to determine which auth service to use
  static String get authServiceImplementation {
    return isDesktopWindows ? 'windows' : 'firebase';
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