/// A stub class to provide platform properties on web
/// 
/// This allows conditional imports to work properly
/// when dart:io is not available.
class Platform {
  // All platform checks return false on web
  static bool get isWindows => false;
  static bool get isMacOS => false;
  static bool get isLinux => false;
  static bool get isAndroid => false;
  static bool get isIOS => false;
}

/// Stub implementation of web-specific utilities for non-web platforms
class WebStub {
  /// Check if running on web
  static bool get isWeb => false;
  
  /// Get web browser information (stub implementation)
  static Map<String, String> getBrowserInfo() {
    return {
      'isWeb': 'false',
      'browser': 'none',
      'version': 'none',
    };
  }
  
  /// Get web navigator information (stub implementation)
  static Map<String, dynamic> getNavigatorInfo() {
    return {
      'isWeb': false,
      'cookiesEnabled': false,
      'language': 'unknown',
    };
  }
  
  /// Check if cookies are enabled (stub implementation)
  static bool get areCookiesEnabled => false;
  
  /// Get current URL (stub implementation)
  static String getCurrentUrl() {
    return '';
  }
  
  /// Initialize web analytics (stub implementation)
  static Future<void> initializeWebAnalytics() async {
    // Do nothing in non-web environments
    return;
  }
  
  /// Log web analytics event (stub implementation)
  static void logAnalyticsEvent(String eventName, [Map<String, dynamic>? parameters]) {
    // Do nothing in non-web environments
  }
  
  /// Show a toast message (stub implementation)
  static void showToast(String message, {ToastGravity gravity = ToastGravity.bottom}) {
    // Do nothing in non-web environments
  }
}

/// Toast position enum for compatibility with web
enum ToastGravity {
  top,
  center,
  bottom,
}
