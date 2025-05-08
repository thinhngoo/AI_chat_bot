/// Constants for API configuration
/// 
/// These constants are used for API authentication
class ApiConstants {
  // Stack Auth API configuration
  static const String stackProjectId = 'a914f06b-5e46-4966-8693-80e4b9f4f409';
  static const String stackPublishableClientKey = 'pck_tqsy29b64a585km2g4wnpc57ypjprzzdch8xzpq0xhayr';
  
  // API URLs
  static const String authApiUrl = 'https://auth-api.dev.jarvis.cx';
  static const String jarvisApiUrl = 'https://api.dev.jarvis.cx'; // Add Jarvis API URL
  
  // API endpoints
  static const String authPasswordSignUp = '/api/v1/auth/password/sign-up';
  static const String authPasswordSignIn = '/api/v1/auth/password/sign-in';
  static const String authSessionRefresh = '/api/v1/auth/sessions/current/refresh';
  static const String authSessionCurrent = '/api/v1/auth/sessions/current';
  
  // AI Chat endpoints
  static const String aiChatConversations = '/api/v1/ai-chat/conversations';
  static const String aiChatConversationMessages = '/api/v1/ai-chat/conversations/{conversationId}/messages';
  
  // Email Composition endpoints
  static const String emailSuggestReply = '/api/v1/email/suggest-reply';
  static const String emailComposeResponse = '/api/v1/email/compose-response';
  
  // Bot Management endpoints
  static const String botsEndpoint = '/api/v1/assistants';
  static const String botById = '/api/v1/assistants/{botId}';
  static const String botKnowledge = '/api/v1/assistants/{botId}/knowledge';
  static const String botKnowledgeById = '/api/v1/assistants/{botId}/knowledge/{knowledgeBaseId}';
  static const String botAsk = '/api/v1/assistants/{botId}/ask';
  static const String botPublish = '/api/v1/assistants/{botId}/publish';
  static const String botPublishPlatform = '/api/v1/assistants/{botId}/publish/{platform}';
  static const String botConfigurations = '/api/v1/assistants/{botId}/configurations';
  
  // Knowledge Base endpoints
  static const String knowledgeBase = '/api/v1/knowledge';
  static const String knowledgeById = '/api/v1/knowledge/{knowledgeBaseId}';
  static const String knowledgeUpload = '/api/v1/knowledge/upload';
  static const String knowledgeUploadFile = '/api/v1/knowledge/{knowledgeBaseId}/upload/file';
  static const String knowledgeUploadWebsite = '/api/v1/knowledge/{knowledgeBaseId}/upload/website';
  static const String knowledgeUploadGoogleDrive = '/api/v1/knowledge/{knowledgeBaseId}/upload/google-drive';
  static const String knowledgeUploadSlack = '/api/v1/knowledge/{knowledgeBaseId}/upload/slack';
  static const String knowledgeUploadConfluence = '/api/v1/knowledge/{knowledgeBaseId}/upload/confluence';
  
  // Prompt Management endpoints
  static const String promptsEndpoint = '/api/v1/prompts';
  
  // Verification callback URL
  static const String verificationCallbackUrl = 'https://auth.dev.jarvis.cx/handler/email-verification?after_auth_return_to=%2Fauth%2Fsignin%3Fclient_id%3Djarvis_chat%26redirect%3Dhttps%253A%252F%252Fchat.dev.jarvis.cx%252Fauth%252Foauth%252Fsuccess';
  
  // Storage keys
  static const String accessTokenKey = 'jarvis_access_token';
  static const String refreshTokenKey = 'jarvis_refresh_token';
  static const String userIdKey = 'jarvis_user_id';
}
