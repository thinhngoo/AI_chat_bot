import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

class ConfigValidator {
  static final Logger _logger = Logger();
  
  static Map<String, bool> validateJarvisApiConfig() {
    final results = <String, bool>{};
    
    // Check required environment variables
    final authApiUrl = dotenv.env['AUTH_API_URL'];
    results['hasAuthApiUrl'] = authApiUrl != null && authApiUrl.isNotEmpty;
    
    final jarvisApiUrl = dotenv.env['JARVIS_API_URL'];
    results['hasJarvisApiUrl'] = jarvisApiUrl != null && jarvisApiUrl.isNotEmpty;
    
    final jarvisApiKey = dotenv.env['JARVIS_API_KEY'];
    results['hasJarvisApiKey'] = jarvisApiKey != null && jarvisApiKey.isNotEmpty;
    
    final stackProjectId = dotenv.env['STACK_PROJECT_ID'];
    results['hasStackProjectId'] = stackProjectId != null && stackProjectId.isNotEmpty;
    
    final stackClientKey = dotenv.env['STACK_PUBLISHABLE_CLIENT_KEY'];
    results['hasStackClientKey'] = stackClientKey != null && stackClientKey.isNotEmpty;
    
    // Check for placeholder values that weren't replaced
    if (results['hasJarvisApiKey'] == true) {
      if (jarvisApiKey == 'your_jarvis_api_key_here' || 
          jarvisApiKey == 'your_api_key_here') {
        _logger.w('JARVIS_API_KEY contains a placeholder value');
        results['hasJarvisApiKey'] = false;
      }
    }
    
    // Add overall status
    results['isJarvisApiConfigValid'] = 
        results['hasAuthApiUrl'] == true && 
        results['hasJarvisApiUrl'] == true && 
        results['hasJarvisApiKey'] == true &&
        results['hasStackProjectId'] == true;
    
    return results;
  }
  
  // Check if .env file is properly loaded
  static bool isEnvFileLoaded() {
    final isLoaded = dotenv.isInitialized;
    
    if (!isLoaded) {
      _logger.e('.env file is not loaded properly');
    } else {
      final jarvisApiKey = dotenv.env['JARVIS_API_KEY'];
      _logger.i('.env file is loaded, Jarvis API key exists: ${jarvisApiKey != null && jarvisApiKey.isNotEmpty}');
    }
    
    return isLoaded;
  }
  
  // Validate AI model API keys
  static Map<String, bool> validateAiApiConfig() {
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
  
  static String getJarvisApiSetupHelp() {
    return '''
To set up Jarvis API Integration:

1. Create a .env file at the project root (copy from .env.example)
2. Add your Jarvis API credentials:
   AUTH_API_URL=https://app.stack-auth.com/api/v1
   JARVIS_API_URL=https://api.jarvis.cx
   JARVIS_API_KEY=your_jarvis_api_key_here
   
3. Add your Stack authentication credentials:
   STACK_PROJECT_ID=your_stack_project_id
   STACK_PUBLISHABLE_CLIENT_KEY=your_stack_client_key
   
   IMPORTANT: The STACK_PROJECT_ID and STACK_PUBLISHABLE_CLIENT_KEY must be valid
   and must match each other. If they don't match, authentication will fail.
   
4. Restart the application to apply the changes

If you continue to experience issues, use the User Data Viewer page in the
Settings menu to check your configuration.
''';
  }
}
