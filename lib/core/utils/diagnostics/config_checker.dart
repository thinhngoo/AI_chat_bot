import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

/// Utility class to check configuration settings
class ConfigChecker {
  static final Logger _logger = Logger();

  /// Check Jarvis API configuration from .env file
  static Future<bool> checkJarvisApiConfig() async {
    _logger.i('Checking Jarvis API Configuration...');
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
    
    // Check Jarvis API configuration
    final authApiUrl = dotenv.env['AUTH_API_URL'];
    final jarvisApiUrl = dotenv.env['JARVIS_API_URL'];
    final jarvisApiKey = dotenv.env['JARVIS_API_KEY'];
    final stackProjectId = dotenv.env['STACK_PROJECT_ID'];
    
    _logger.i('\nJarvis API Configuration:');
    _logger.i('------------------------------------');
    
    // Check Auth API URL
    if (authApiUrl == null || authApiUrl.isEmpty) {
      _logger.e('✗ AUTH_API_URL is missing');
      _logger.i('  Required for authentication with Jarvis API');
    } else {
      _logger.i('✓ AUTH_API_URL is configured');
    }
    
    // Check Jarvis API URL
    if (jarvisApiUrl == null || jarvisApiUrl.isEmpty) {
      _logger.e('✗ JARVIS_API_URL is missing');
      _logger.i('  Required for chat functionality with Jarvis API');
    } else {
      _logger.i('✓ JARVIS_API_URL is configured');
    }
    
    // Check Jarvis API Key
    if (jarvisApiKey == null || jarvisApiKey.isEmpty) {
      _logger.e('✗ JARVIS_API_KEY is missing');
      _logger.i('  Required for API authentication');
    } else if (jarvisApiKey == 'your_jarvis_api_key_here') {
      _logger.e('✗ JARVIS_API_KEY contains placeholder value');
      _logger.i('  Please replace with your actual API key');
    } else {
      _logger.i('✓ JARVIS_API_KEY is configured');
    }
    
    // Check Stack Project ID
    if (stackProjectId == null || stackProjectId.isEmpty) {
      _logger.e('✗ STACK_PROJECT_ID is missing');
      _logger.i('  Required for authentication with Jarvis API');
    } else {
      _logger.i('✓ STACK_PROJECT_ID is configured');
    }
    
    _logger.i('\nConfiguration Summary:');
    _logger.i('------------------------------------');
    final bool jarvisConfigOk = (authApiUrl != null && 
                               authApiUrl.isNotEmpty &&
                               jarvisApiUrl != null && 
                               jarvisApiUrl.isNotEmpty &&
                               jarvisApiKey != null &&
                               jarvisApiKey.isNotEmpty &&
                               jarvisApiKey != 'your_jarvis_api_key_here' &&
                               stackProjectId != null &&
                               stackProjectId.isNotEmpty);
    
    if (jarvisConfigOk) {
      _logger.i('✓ All configuration looks good! Your application should work correctly.');
      return true;
    } else {
      _logger.w('⚠ There are configuration issues that need to be fixed.');
      _logger.i('\nPlease update your .env file with the correct values.');
      return false;
    }
  }
  
  /// Validate the Jarvis API configuration
  static Future<Map<String, bool>> validateJarvisApiConfig() async {
    try {
      await dotenv.load(fileName: '.env');
      
      final authApiUrl = dotenv.env['AUTH_API_URL'];
      final jarvisApiUrl = dotenv.env['JARVIS_API_URL'];
      final jarvisApiKey = dotenv.env['JARVIS_API_KEY'];
      final stackProjectId = dotenv.env['STACK_PROJECT_ID'];
      
      final bool validAuthApiUrl = authApiUrl != null && authApiUrl.isNotEmpty;
      final bool validJarvisApiUrl = jarvisApiUrl != null && jarvisApiUrl.isNotEmpty;
      final bool validJarvisApiKey = jarvisApiKey != null && 
                                    jarvisApiKey.isNotEmpty && 
                                    jarvisApiKey != 'your_jarvis_api_key_here';
      final bool validStackProjectId = stackProjectId != null && stackProjectId.isNotEmpty;
      
      return {
        'validAuthApiUrl': validAuthApiUrl,
        'validJarvisApiUrl': validJarvisApiUrl,
        'validJarvisApiKey': validJarvisApiKey,
        'validStackProjectId': validStackProjectId,
        'configValid': validAuthApiUrl && validJarvisApiUrl && validJarvisApiKey && validStackProjectId,
      };
    } catch (e) {
      return {
        'validAuthApiUrl': false,
        'validJarvisApiUrl': false,
        'validJarvisApiKey': false,
        'validStackProjectId': false,
        'configValid': false,
        'error': true,
      };
    }
  }
}

/// Run this script directly with: dart lib/core/utils/diagnostics/config_checker.dart
void main() async {
  final configValid = await ConfigChecker.checkJarvisApiConfig();
  
  // Exit with appropriate status code
  if (!configValid) {
    exit(1);
  }
}
