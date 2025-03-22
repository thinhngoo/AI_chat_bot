import 'package:firebase_core/firebase_core.dart';
import 'package:logger/logger.dart';

class FirebaseChecker {
  static final Logger _logger = Logger();
  static bool _isInitialized = false;
  
  static Future<bool> checkFirebaseInitialization() async {
    // If we already know Firebase is initialized, return immediately
    if (_isInitialized) return true;
    
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
}