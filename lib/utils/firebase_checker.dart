import 'package:firebase_core/firebase_core.dart';
import 'package:logger/logger.dart';

class FirebaseChecker {
  static final Logger _logger = Logger();
  static bool _isInitialized = false;
  
  static Future<bool> checkFirebaseInitialization() async {
    if (_isInitialized) return true;
    
    try {
      // Check if Firebase is already initialized
      if (Firebase.apps.isNotEmpty) {
        _isInitialized = true;
        _logger.i('Firebase is already initialized');
        return true;
      }
      
      _logger.w('Firebase is not initialized');
      return false;
    } catch (e) {
      _logger.e('Error checking Firebase initialization: $e');
      return false;
    }
  }
}
