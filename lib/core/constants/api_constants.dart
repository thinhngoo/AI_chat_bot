/// Constants for API configuration
/// 
/// These constants are used for API authentication and configuration
class ApiConstants {
  // Stack Auth API configuration
  static const String stackProjectId = 'fdd3c88a-6321-4a07-ba47-d94ed8725c92';
  static const String stackPublishableClientKey = 'pck_v8e67qcptwdd334p7gaw04nrh7fke7g2sy8yh4vg4z4yg';
  static const String stackSecretServerKey = 'ssk_wj0nrj1t9xaqxn95k34x7fev28ghcp433t809f7081q88';
  static const String stackJwksUrl = 'https://api.stack-auth.com/api/v1/projects/fdd3c88a-6321-4a07-ba47-d94ed8725c92/.well-known/jwks.json';
  
  // API URLs
  static const String authApiUrl = 'https://app.stack-auth.com/api/v1';
  static const String jarvisApiUrl = 'https://api.jarvis.cx';
  static const String knowledgeApiUrl = 'https://knowledge-api.jarvis.cx';
  
  // Verification callback URL
  static const String verificationCallbackUrl = 'https://auth.dev.jarvis.cx/handler/email-verification?after_auth_return_to=%2Fauth%2Fsignin%3Fclient_id%3Djarvis_chat%26redirect%3Dhttps%253A%252F%252Fchat.dev.jarvis.cx%252Fauth%252Foauth%252Fsuccess';
  
  // The Jarvis API key will still need to come from .env
  // but we can add a default test key for development environments
  static const String defaultApiKey = 'test_jarvis_api_key_for_development_only';
}
