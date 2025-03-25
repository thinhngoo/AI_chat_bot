import 'package:firebase_core/firebase_core.dart';
import 'package:logger/logger.dart';

class FirebaseChecker {
  static final Logger _logger = Logger();
  static bool _isInitialized = false;
  static DateTime _lastCheckTime = DateTime.now();
  static String _lastError = '';
  static bool _manuallySet = false;
  
  static Future<bool> checkFirebaseInitialization() async {
    // If manually set, return that value immediately
    if (_manuallySet) {
      return _isInitialized;
    }
    
    // If we already know Firebase is initialized, return immediately
    if (_isInitialized) return true;
    
    // Avoid checking too frequently to prevent UI freezing
    final now = DateTime.now();
    if (now.difference(_lastCheckTime).inMilliseconds < 500) {
      return _isInitialized;
    }
    
    _lastCheckTime = now;
    
    try {
      // Fast check - just see if apps list is populated
      // Wrap in a timeout to avoid blocking
      final isInitialized = await Future.value(Firebase.apps.isNotEmpty)
          .timeout(const Duration(milliseconds: 200), onTimeout: () => false);
      
      if (isInitialized) {
        _isInitialized = true;
        _lastError = ''; // Clear any previous errors
        return true;
      }
      
      _lastError = 'Firebase.apps is empty';
      return false;
    } catch (e) {
      // Store the error for reference
      _lastError = e.toString();
      
      // Don't log detailed error to avoid freezing
      _logger.d('Firebase check failed: ${e.toString().split("\n").first}');
      return false;
    }
  }
  
  // Force reset initialization state - useful for testing
  static void resetInitializationState() {
    _isInitialized = false;
    _manuallySet = false;
  }
  
  // Set initialization state explicitly
  static void setInitialized(bool initialized) {
    _isInitialized = initialized;
    _manuallySet = true;
  }
  
  // Get the last error encountered during initialization check
  static String getLastError() {
    return _lastError;
  }
}