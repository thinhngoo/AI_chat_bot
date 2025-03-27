import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/jarvis_api_service.dart';

class PlatformServiceHelper {
  static final Logger _logger = Logger();
  static final JarvisApiService _apiService = JarvisApiService();
  
  // Pre-calculate platform info immediately at class load time
  static final Map<String, dynamic> _platformCache = _initPlatformCache();
  
  // Initialize platform cache once at startup with a safer approach
  static Map<String, dynamic> _initPlatformCache() {
    final Map<String, dynamic> cache = {};
    
    try {
      // Detect platform with minimal overhead
      final bool isWeb = kIsWeb;
      String platform;
      
      if (isWeb) {
        platform = 'web';
      } else {
        try {
          // Log platform details to help with debugging
          // Avoid excessive logging that might slow down startup
          final String operatingSystem = Platform.operatingSystem;
          
          if (operatingSystem == 'android') {
            platform = 'android';
          } else if (operatingSystem == 'ios') {
            platform = 'ios';
          } else if (operatingSystem == 'macos') {
            platform = 'macos';
          } else if (operatingSystem == 'windows') {
            platform = 'windows';
          } else if (operatingSystem == 'linux') {
            platform = 'linux';
          } else {
            platform = 'unknown';
          }
          
          Logger().i('Platform detection - OS: $operatingSystem');
        } catch (e) {
          // Fallback for any platform detection errors
          Logger().e('Error detecting platform: $e');
          platform = 'unknown';
        }
      }
      
      // Cache platform information
      cache['platform'] = platform;
      cache['isWeb'] = isWeb;
      cache['isDesktopWindows'] = !isWeb && platform == 'windows';
      cache['isMobileOrWeb'] = isWeb || platform == 'android' || platform == 'ios';
      
      // Create platform info result map
      final Map<String, dynamic> platformInfo = {
        'platform': platform,
        'isDesktop': platform == 'windows' || platform == 'macos' || platform == 'linux',
        'isMobile': platform == 'android' || platform == 'ios',
        'isWeb': isWeb,
      };
      
      cache['platformInfo'] = platformInfo;
      
    } catch (e) {
      // Fallback in case of any error
      Logger().e('Error in platform detection: $e');
      cache['platform'] = 'unknown';
      cache['isWeb'] = false;
      cache['isDesktopWindows'] = false;
      cache['isMobileOrWeb'] = false;
      cache['platformInfo'] = {
        'platform': 'unknown',
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
  
  // Return the cached platform info immediately
  static Map<String, dynamic> getPlatformInfo() {
    return _platformCache['platformInfo'] as Map<String, dynamic>;
  }
  
  // Helper method to determine which auth service to use
  static String get authServiceImplementation {
    return isDesktopWindows ? 'windows' : 'jarvis';
  }
  
  // Helper method for loading platform-specific config
  static Map<String, dynamic> getPlatformConfig() {
    return {
      'useJarvisApi': true,
      'autoVerifyEmail': true,
    };
  }
  
  // Credentials are now managed by JarvisApiService
  static Future<void> storeCredentials(String email, String password) async {
    try {
      // Login with Jarvis API to store credentials
      await _apiService.signIn(email, password);
      _logger.i('Credentials stored via Jarvis API login');
    } catch (e) {
      _logger.e('Error storing credentials: $e');
      throw Exception('Failed to store credentials');
    }
  }

  static Future<bool> validateCredentials(String email, String password) async {
    try {
      // Validate by attempting to sign in
      await _apiService.signIn(email, password);
      return true;
    } catch (e) {
      _logger.e('Error validating credentials: $e');
      return false;
    }
  }
  
  static Future<void> clearCredentials() async {
    try {
      // Log out of Jarvis API
      await _apiService.logout();
      _logger.i('All credentials cleared');
    } catch (e) {
      _logger.e('Error clearing credentials: $e');
      throw Exception('Failed to clear credentials');
    }
  }
  
  // Get all users stored in local storage (Windows)
  static Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString('users');
      
      if (usersJson == null || usersJson.isEmpty) {
        return [];
      }
      
      final List<dynamic> decoded = jsonDecode(usersJson);
      return decoded.map((user) => Map<String, dynamic>.from(user)).toList();
    } catch (e) {
      _logger.e('Error getting users from local storage: $e');
      return [];
    }
  }
}