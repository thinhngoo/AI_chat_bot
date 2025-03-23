import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

/// Utility class to check Firebase configuration status
class FirebaseConfigChecker {
  static final Logger _logger = Logger();

  /// Check Google Sign-In configuration status
  static Future<Map<String, dynamic>> checkGoogleSignInConfig() async {
    final results = <String, dynamic>{
      'isConfigured': false,
      'messages': <String>[],
      'webClientID': null,
    };
    
    // Check .env file configuration
    final desktopClientId = dotenv.env['GOOGLE_DESKTOP_CLIENT_ID'];
    final clientSecret = dotenv.env['GOOGLE_CLIENT_SECRET'];
    
    // Check the configured client ID
    if (desktopClientId == null || desktopClientId.isEmpty) {
      results['messages'].add('GOOGLE_DESKTOP_CLIENT_ID not found in .env file');
    } else if (desktopClientId == 'your_desktop_client_id_here') {
      results['messages'].add('GOOGLE_DESKTOP_CLIENT_ID contains placeholder value');
    } else {
      results['webClientID'] = desktopClientId;
      results['messages'].add('GOOGLE_DESKTOP_CLIENT_ID configured: ${_maskSecret(desktopClientId)}');
      
      // Check if it matches the expected client ID
      const expectedClientID = '784300763720-ii2er5tptdqdg3nn8984rakhh1auiiip.apps.googleusercontent.com';
      if (desktopClientId != expectedClientID) {
        results['messages'].add('WARNING: Client ID does not match the expected value');
      }
    }
    
    // Check client secret
    if (clientSecret == null || clientSecret.isEmpty || clientSecret == 'your_client_secret_here') {
      results['messages'].add('GOOGLE_CLIENT_SECRET not configured properly');
    } else {
      results['messages'].add('GOOGLE_CLIENT_SECRET configured');
    }
    
    // Skip Firebase initialization check
    results['firebaseInitialized'] = false;
    results['messages'].add('Firebase initialization check skipped (running in standalone mode)');

    // Final result
    results['isConfigured'] = 
        desktopClientId != null && 
        desktopClientId.isNotEmpty && 
        desktopClientId != 'your_desktop_client_id_here' &&
        clientSecret != null &&
        clientSecret.isNotEmpty &&
        clientSecret != 'your_client_secret_here';
    
    return results;
  }
  
  /// Mask sensitive information for logging
  static String _maskSecret(String value) {
    if (value.length <= 8) return '****';
    return '${value.substring(0, 4)}...${value.substring(value.length - 4)}';
  }
  
  /// Print configuration status to console for debugging
  static Future<void> printConfigStatus() async {
    final status = await checkGoogleSignInConfig();
    _logger.i('Firebase Google Sign-In Config Status:');
    _logger.i('- Properly configured: ${status['isConfigured']}');
    
    for (final message in status['messages']) {
      _logger.i('- $message');
    }
  }
}
