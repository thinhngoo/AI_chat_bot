import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

/// Utility class to check configuration settings
class ConfigChecker {
  static final Logger _logger = Logger();

  /// Check Google Auth and API configuration from .env file
  static Future<bool> checkGoogleAuthConfig() async {
    _logger.i('Checking Google Auth Configuration...');
    _logger.i('------------------------------------');
    
    // Load environment variables from .env file
    bool envLoaded = false;
    try {
      await dotenv.load(fileName: '.env');
      _logger.i('✓ .env file loaded successfully');
      envLoaded = true;
    } catch (e) {
      _logger.e('✗ Failed to load .env file: $e');
      _logger.i('\nMake sure you have created a .env file in the project root directory.');
      _logger.i('You can copy .env.example to .env and fill in your API keys.');
    }
    
    if (!envLoaded) return false;
    
    // Check Google Auth configuration
    final desktopClientId = dotenv.env['GOOGLE_DESKTOP_CLIENT_ID'];
    final clientSecret = dotenv.env['GOOGLE_CLIENT_SECRET'];
    final geminiApiKey = dotenv.env['GEMINI_API_KEY'];
    
    _logger.i('\nGoogle Authentication:');
    _logger.i('------------------------------------');
    
    // Check Desktop Client ID
    if (desktopClientId == null || desktopClientId.isEmpty) {
      _logger.e('✗ GOOGLE_DESKTOP_CLIENT_ID is missing');
      _logger.i('  Required for Google Sign-In on desktop platforms');
    } else if (desktopClientId == 'your_desktop_client_id_here') {
      _logger.e('✗ GOOGLE_DESKTOP_CLIENT_ID contains placeholder value');
      _logger.i('  Please replace with your actual client ID from Google Cloud Console');
    } else {
      _logger.i('✓ GOOGLE_DESKTOP_CLIENT_ID is configured');
    }
    
    // Check Client Secret
    if (clientSecret == null || clientSecret.isEmpty) {
      _logger.e('✗ GOOGLE_CLIENT_SECRET is missing');
      _logger.i('  Required for Google Sign-In on desktop platforms');
    } else if (clientSecret == 'your_client_secret_here') {
      _logger.e('✗ GOOGLE_CLIENT_SECRET contains placeholder value');
      _logger.i('  Please replace with your actual client secret from Google Cloud Console');
    } else {
      _logger.i('✓ GOOGLE_CLIENT_SECRET is configured');
    }
    
    _logger.i('\nAPI Keys:');
    _logger.i('------------------------------------');
    
    // Check Gemini API Key
    if (geminiApiKey == null || geminiApiKey.isEmpty) {
      _logger.e('✗ GEMINI_API_KEY is missing');
      _logger.i('  Required for AI chat functionality');
    } else if (geminiApiKey == 'your_gemini_api_key_here' || 
               geminiApiKey == 'demo_api_key_please_configure' ||
               geminiApiKey == 'demo_api_key') {
      _logger.e('✗ GEMINI_API_KEY contains placeholder value');
      _logger.i('  Please replace with your actual API key from Google AI Studio');
    } else {
      _logger.i('✓ GEMINI_API_KEY is configured');
    }
    
    _logger.i('\nConfiguration Summary:');
    _logger.i('------------------------------------');
    final bool googleAuthOk = (desktopClientId != null && 
                              desktopClientId.isNotEmpty && 
                              desktopClientId != 'your_desktop_client_id_here' &&
                              clientSecret != null &&
                              clientSecret.isNotEmpty &&
                              clientSecret != 'your_client_secret_here');
                              
    final bool apiKeysOk = (geminiApiKey != null && 
                           geminiApiKey.isNotEmpty && 
                           geminiApiKey != 'your_gemini_api_key_here' &&
                           geminiApiKey != 'demo_api_key_please_configure' &&
                           geminiApiKey != 'demo_api_key');
    
    if (googleAuthOk && apiKeysOk) {
      _logger.i('✓ All configuration looks good! Your application should work correctly.');
      return true;
    } else {
      _logger.w('⚠ There are configuration issues that need to be fixed.');
      if (!googleAuthOk) {
        _logger.w('  - Google Authentication needs configuration');
      }
      if (!apiKeysOk) {
        _logger.w('  - API Keys need configuration');
      }
      _logger.i('\nPlease update your .env file with the correct values.');
      return false;
    }
  }
  
  /// Check if Google Auth configuration is valid
  static Future<Map<String, bool>> validateGoogleAuthConfig() async {
    try {
      await dotenv.load(fileName: '.env');
      
      final desktopClientId = dotenv.env['GOOGLE_DESKTOP_CLIENT_ID'];
      final clientSecret = dotenv.env['GOOGLE_CLIENT_SECRET'];
      
      final bool validClientId = desktopClientId != null && 
                                desktopClientId.isNotEmpty && 
                                desktopClientId != 'your_desktop_client_id_here';
                                
      final bool validClientSecret = clientSecret != null &&
                                    clientSecret.isNotEmpty &&
                                    clientSecret != 'your_client_secret_here';
      
      return {
        'validClientId': validClientId,
        'validClientSecret': validClientSecret,
        'configValid': validClientId && validClientSecret,
      };
    } catch (e) {
      return {
        'validClientId': false,
        'validClientSecret': false,
        'configValid': false,
        'error': true,
      };
    }
  }
  
  /// Check if API key configuration is valid
  static Future<bool> validateApiKey() async {
    try {
      await dotenv.load(fileName: '.env');
      
      final geminiApiKey = dotenv.env['GEMINI_API_KEY'];
      
      return geminiApiKey != null && 
             geminiApiKey.isNotEmpty && 
             geminiApiKey != 'your_gemini_api_key_here' &&
             geminiApiKey != 'demo_api_key_please_configure' &&
             geminiApiKey != 'demo_api_key';
    } catch (e) {
      return false;
    }
  }
}

/// Run this script directly with: dart lib/core/utils/diagnostics/config_checker.dart
void main() async {
  final configValid = await ConfigChecker.checkGoogleAuthConfig();
  
  // Exit with appropriate status code
  if (!configValid) {
    exit(1);
  }
}
