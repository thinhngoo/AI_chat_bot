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
  static const String authApiUrl = 'https://api.stack-auth.com/api';
  static const String jarvisApiUrl = 'https://api.jarvis.cx';
  static const String knowledgeApiUrl = 'https://knowledge-api.jarvis.cx';
  
  // Gemini API configuration
  static const String geminiApiKey = 'AIzaSyClkVxfV1SMF7iORASUZGVPa2HoIIa5KEk';
  static const String geminiApiUrl = 'https://generativelanguage.googleapis.com/v1beta';
  
  // Verification callback URL
  static const String verificationCallbackUrl = 'https://auth.dev.jarvis.cx/handler/email-verification?after_auth_return_to=%2Fauth%2Fsignin%3Fclient_id%3Djarvis_chat%26redirect%3Dhttps%253A%252F%252Fchat.dev.jarvis.cx%252Fauth%252Foauth%252Fsuccess';
  
  // Default API key for development environments
  static const String defaultApiKey = 'test_jarvis_api_key_for_development_only';
  
  // API endpoints
  static const String authPasswordSignUp = '/v1/auth/password/sign-up';
  static const String authPasswordSignIn = '/v1/auth/password/sign-in';
  static const String authSessionRefresh = '/v1/auth/sessions/current/refresh';
  static const String authSessionCurrent = '/v1/auth/sessions/current';
  static const String authEmailVerificationStatus = '/v1/auth/email/verification/status';
  static const String userProfile = '/user/profile';
  static const String userChangePassword = '/user/change-password';
  
  // Updated API endpoints for AI chat based on documentation
  static const String conversations = '/api/v1/ai-chat/conversations';
  static const String messages = '/api/v1/ai-chat/messages';
  static const String status = '/status';
  static const String models = '/models';
  
  // Gemini API endpoints
  static const String geminiGenerateContent = '/models/gemini-2.0-flash:generateContent';
  static const String geminiStreamContent = '/models/gemini-2.0-flash:streamGenerateContent';
  
  // Model constants
  static const String defaultModel = 'gemini-1.5-flash-latest';
  static const Map<String, String> modelNames = {
    'gemini-1.5-flash-latest': 'Gemini 1.5 Flash',
    'gemini-1.5-pro-latest': 'Gemini 1.5 Pro',
    'claude-3-5-sonnet-20240620': 'Claude 3.5 Sonnet',
    'gpt-4o': 'GPT-4o',
    'gpt-4o-mini': 'GPT-4o Mini',
  };
  
  // Storage keys
  static const String accessTokenKey = 'jarvis_access_token';
  static const String refreshTokenKey = 'jarvis_refresh_token';
  static const String userIdKey = 'jarvis_user_id';

  // Required OAuth scopes for Jarvis API - updated with full scopes
  static const List<String> requiredScopes = [
    'ai-chat:read',
    'ai-chat:write',
    'user:read',
    'user:write',
    'ai-model:read',
    'conversation:read',
    'conversation:write'
  ];
  
  // Stack Auth configuration - kept for reference but not used in current implementation
  static const bool useStackAuthFormatting = false; // Set to false to disable Stack Auth formatting
  static const String stackOAuthScopesParam = 'scopes';
  static const String oauthResponseType = 'code';
  static const bool stackUseServerFunctions = false; // Use client-side functions only
}
