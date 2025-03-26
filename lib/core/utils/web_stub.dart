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
