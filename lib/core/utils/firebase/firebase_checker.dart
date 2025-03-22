import 'package:firebase_core/firebase_core.dart';
import 'package:logger/logger.dart';

class FirebaseChecker {
  static final Logger _logger = Logger();
  static bool _isInitialized = false;
  static DateTime _lastCheckTime = DateTime.now();
  
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
        return true;
      }
      
      return false;
    } catch (e) {
      // Don't log detailed error to avoid freezing
      _logger.w('Firebase check failed');
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
}