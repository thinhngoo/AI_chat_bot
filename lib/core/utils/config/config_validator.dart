import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

class ConfigValidator {
  static final Logger _logger = Logger();
  
  static Map<String, bool> validateGoogleAuthConfig() {
    final results = <String, bool>{};
    
    // Check required environment variables
    final desktopClientId = dotenv.env['GOOGLE_DESKTOP_CLIENT_ID'];
    results['hasDesktopClientId'] = desktopClientId != null && desktopClientId.isNotEmpty;
    
    final clientSecret = dotenv.env['GOOGLE_CLIENT_SECRET'];
    results['hasClientSecret'] = clientSecret != null && clientSecret.isNotEmpty;
    
    // Check for placeholder values that weren't replaced
    if (results['hasDesktopClientId'] == true) {
      if (desktopClientId == 'your_desktop_client_id_here' || 
          desktopClientId == 'your_client_id_here') {
        _logger.w('GOOGLE_DESKTOP_CLIENT_ID contains a placeholder value');
        results['hasDesktopClientId'] = false;
      }
    }
    
    if (results['hasClientSecret'] == true) {
      if (clientSecret == 'your_client_secret_here') {
        _logger.w('GOOGLE_CLIENT_SECRET contains a placeholder value');
        results['hasClientSecret'] = false;
      }
    }
    
    // Add overall status
    results['isGoogleAuthConfigValid'] = 
        results['hasDesktopClientId'] == true && 
        results['hasClientSecret'] == true;
    
    return results;
  }
  
  static bool isFirebaseGoogleAuthValid() {
    // This is just a quick check of the environment variables
    // We can't check Firebase Console settings programmatically
    final desktopClientId = dotenv.env['GOOGLE_DESKTOP_CLIENT_ID'];
    
    if (desktopClientId == null || desktopClientId.isEmpty) {
      return false;
    }
    
    if (desktopClientId == 'your_desktop_client_id_here' || 
        desktopClientId == 'your_client_id_here') {
      return false;
    }
    
    return true;
  }
  
  static Map<String, bool> validateApiConfig() {
    final results = <String, bool>{};
    
    // Check Gemini API key
    final geminiApiKey = dotenv.env['GEMINI_API_KEY'];
    results['hasGeminiApiKey'] = geminiApiKey != null && geminiApiKey.isNotEmpty;
    
    if (results['hasGeminiApiKey'] == true) {
      if (geminiApiKey == 'your_gemini_api_key_here') {
        _logger.w('GEMINI_API_KEY contains a placeholder value');
        results['hasGeminiApiKey'] = false;
      }
    }
    
    return results;
  }

  // Check if .env file is properly loaded
  static bool isEnvFileLoaded() {
    final isLoaded = dotenv.isInitialized;
    
    if (!isLoaded) {
      _logger.e('.env file is not loaded properly');
    } else {
      final geminiApiKey = dotenv.env['GEMINI_API_KEY'];
      _logger.i('.env file is loaded, Gemini API key exists: ${geminiApiKey != null && geminiApiKey.isNotEmpty}');
    }
    
    return isLoaded;
  }
  
  static String getGoogleAuthSetupHelp() {
    return '''
To set up Google Authentication:

1. Create a .env file at the project root (copy from .env.example)
2. Add your Google OAuth credentials:
   GOOGLE_DESKTOP_CLIENT_ID=your_desktop_client_id_here
   GOOGLE_CLIENT_SECRET=your_client_secret_here

3. In Firebase Console:
   - Go to Authentication > Sign-in method > Google
   - Add the SAME client ID to "Web SDK configuration"
''';
  }
}
