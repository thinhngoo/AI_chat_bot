import 'package:firebase_core/firebase_core.dart';
import 'package:logger/logger.dart';

class FirebaseChecker {
  static final Logger _logger = Logger();
  static bool _isInitialized = false;
  static DateTime _lastCheckTime = DateTime.now();
  static String _lastError = '';
  
  static Future<bool> checkFirebaseInitialization() async {
    // If we already know Firebase is initialized, return immediately
    if (_isInitialized) return true;
    
    // Avoid checking too frequently
    final now = DateTime.now();
    if (now.difference(_lastCheckTime).inMilliseconds < 200) {
      return _isInitialized;
    }
    
    _lastCheckTime = now;
    
    try {
      // Fast check - just see if apps list is populated
      final isInitialized = Firebase.apps.isNotEmpty;
      
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
  }
  
  // Set initialization state explicitly
  static void setInitialized(bool initialized) {
    _isInitialized = initialized;
  }
  
  // Get the last error encountered during initialization check
  static String getLastError() {
    return _lastError;
  }
}