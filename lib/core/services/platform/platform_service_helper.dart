import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/diagnostics/platform_checker.dart';

/// Helper class for platform-specific operations
class PlatformServiceHelper {
  static final Logger _logger = Logger();
  static PlatformServiceHelper? _instance;
  
  String _appDataPath = '';
  bool _isInitialized = false;
  
  /// Get the singleton instance
  static PlatformServiceHelper get instance {
    _instance ??= PlatformServiceHelper._internal();
    return _instance!;
  }
  
  PlatformServiceHelper._internal();
  
  /// Initialize the platform helper
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _logger.i('Initializing PlatformServiceHelper');
      
      // Log platform information
      PlatformChecker.logPlatformInfo();
      
      // Get application data path based on platform
      if (kIsWeb) {
        _appDataPath = 'web-storage';
        _logger.i('Running on web platform, using browser storage');
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final dir = await getApplicationSupportDirectory();
        _appDataPath = dir.path;
        _logger.i('Desktop platform detected, app data path: $_appDataPath');
      } else if (Platform.isAndroid || Platform.isIOS) {
        final dir = await getApplicationDocumentsDirectory();
        _appDataPath = dir.path;
        _logger.i('Mobile platform detected, app data path: $_appDataPath');
      } else {
        _logger.w('Unknown platform, using default storage');
        _appDataPath = 'unknown-platform';
      }
      
      _isInitialized = true;
    } catch (e) {
      _logger.e('Error initializing PlatformServiceHelper: $e');
      throw Exception('Failed to initialize platform services: $e');
    }
  }
  
  /// Get application data path
  String get appDataPath {
    if (!_isInitialized) {
      _logger.w('PlatformServiceHelper not initialized, returning empty path');
      return '';
    }
    return _appDataPath;
  }
  
  /// Check if the platform is mobile
  bool get isMobile => PlatformChecker.isMobile;
  
  /// Check if the platform is desktop
  bool get isDesktop => PlatformChecker.isDesktop;
  
  /// Check if the platform is web
  bool get isWeb => PlatformChecker.isWeb;
  
  /// Get all stored preferences as a Map
  Future<Map<String, dynamic>> getAllPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final allPrefs = <String, dynamic>{};
      
      for (final key in keys) {
        if (prefs.containsKey(key)) {
          if (prefs.getString(key) != null) {
            allPrefs[key] = prefs.getString(key);
          } else if (prefs.getBool(key) != null) {
            allPrefs[key] = prefs.getBool(key);
          } else if (prefs.getInt(key) != null) {
            allPrefs[key] = prefs.getInt(key);
          } else if (prefs.getDouble(key) != null) {
            allPrefs[key] = prefs.getDouble(key);
          } else if (prefs.getStringList(key) != null) {
            allPrefs[key] = prefs.getStringList(key);
          }
        }
      }
      
      return allPrefs;
    } catch (e) {
      _logger.e('Error getting all preferences: $e');
      return {};
    }
  }
  
  /// Clear all stored preferences
  Future<bool> clearAllPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.clear();
    } catch (e) {
      _logger.e('Error clearing preferences: $e');
      return false;
    }
  }
  
  /// Get platform diagnostics information
  Map<String, dynamic> getDiagnosticInfo() {
    return {
      'appDataPath': _appDataPath,
      'isInitialized': _isInitialized,
      'platformInfo': PlatformChecker.getPlatformInfo(),
    };
  }
}