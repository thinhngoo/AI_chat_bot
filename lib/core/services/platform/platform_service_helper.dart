import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:logger/logger.dart';

class PlatformServiceHelper {
  static final Logger _logger = Logger();
  
  // Pre-calculate platform info immediately at class load time
  static final Map<String, dynamic> _platformCache = _initPlatformCache();
  
  // Initialize platform cache once at startup
  static Map<String, dynamic> _initPlatformCache() {
    final Map<String, dynamic> cache = {};
    
    // Detect platform with minimal overhead
    final bool isWeb = kIsWeb;
    String platform;
    bool supportsFirebase;
    
    if (isWeb) {
      platform = 'web';
      supportsFirebase = true;
    } else {
      try {
        if (Platform.isAndroid) {
          platform = 'android';
          supportsFirebase = true;
        } else if (Platform.isIOS) {
          platform = 'ios';
          supportsFirebase = true;
        } else if (Platform.isMacOS) {
          platform = 'macos';
          supportsFirebase = true;
        } else if (Platform.isWindows) {
          platform = 'windows';
          supportsFirebase = true; // Optimistically assume support
        } else if (Platform.isLinux) {
          platform = 'linux';
          supportsFirebase = false;
        } else {
          platform = 'unknown';
          supportsFirebase = false;
        }
      } catch (e) {
        // Fallback for any platform detection errors
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