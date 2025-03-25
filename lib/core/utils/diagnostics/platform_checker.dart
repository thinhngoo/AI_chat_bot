import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Utility class to check platform compatibility
class PlatformChecker {
  static final Logger _logger = Logger();

  /// Check and print platform compatibility information
  static void checkPlatform() {
    _logger.i('Checking platform compatibility...');
    _logger.i('------------------------------------');
    
    // Detect platform
    final bool isWeb = kIsWeb;
    
    if (isWeb) {
      _logger.i('✓ Platform: Web (compatible)');
    } else {
      try {
        final String os = Platform.operatingSystem;
        final String osVersion = Platform.operatingSystemVersion;
        
        _logger.i('Platform: $os ($osVersion)');
        
        // Check compatibility
        if (Platform.isAndroid) {
          _logger.i('✓ Android is fully supported');
        } else if (Platform.isIOS) {
          _logger.i('✓ iOS is fully supported');
        } else if (Platform.isWindows) {
          _logger.i('✓ Windows is supported with limited Google authentication');
          _logger.i('  - Google Sign-In requires special configuration');
          _logger.i('  - Firebase desktop plugins are supported');
        } else if (Platform.isMacOS) {
          _logger.i('✓ macOS is supported with some limitations');
        } else if (Platform.isLinux) {
          _logger.w('⚠ Linux support is experimental');
          _logger.w('  - Some Firebase features may not work correctly');
        } else {
          _logger.w('⚠ Unknown platform: $os');
          _logger.w('  - Compatibility cannot be guaranteed');
        }
      } catch (e) {
        _logger.e('Error detecting platform: $e');
      }
    }
    
    _logger.i('\nEnvironment variables check:');
    _logger.i('------------------------------------');
    
    // Check for Dart and Flutter versions
    _logger.i('Dart SDK: ${Platform.version}');
    
    _logger.i('\nSummary:');
    _logger.i('------------------------------------');
    if (isWeb || Platform.isAndroid || Platform.isIOS || Platform.isWindows) {
      _logger.i('✓ Your platform is supported by this application.');
    } else {
      _logger.w('⚠ Your platform has limited support. Some features may not work correctly.');
    }
    _logger.i('For more details, refer to the README.md file.');
  }
  
  /// Determine if the current platform is fully supported
  static bool isFullySupported() {
    if (kIsWeb) return true;
    return Platform.isAndroid || Platform.isIOS || Platform.isWindows;
  }
  
  /// Get platform details as a Map
  static Map<String, dynamic> getPlatformDetails() {
    final Map<String, dynamic> details = {
      'isWeb': kIsWeb,
      'isFullySupported': isFullySupported(),
      'dartVersion': Platform.version,
    };
    
    if (!kIsWeb) {
      details['operatingSystem'] = Platform.operatingSystem;
      details['operatingSystemVersion'] = Platform.operatingSystemVersion;
      details['isAndroid'] = Platform.isAndroid;
      details['isIOS'] = Platform.isIOS;
      details['isWindows'] = Platform.isWindows;
      details['isMacOS'] = Platform.isMacOS;
      details['isLinux'] = Platform.isLinux;
    }
    
    return details;
  }
}

/// Run this script directly with: dart lib/core/utils/diagnostics/platform_checker.dart
void main() {
  PlatformChecker.checkPlatform();
}
