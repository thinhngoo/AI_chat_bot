/// Constants for API configuration
/// 
/// These constants are used for API authentication
class ApiConstants {
  // Stack Auth API configuration
  static const String stackProjectId = 'a914f06b-5e46-4966-8693-80e4b9f4f409';
  static const String stackPublishableClientKey = 'pck_tqsy29b64a585km2g4wnpc57ypjprzzdch8xzpq0xhayr';
  
  // API URLs
  static const String authApiUrl = 'https://auth-api.dev.jarvis.cx';
  static const String jarvisApiUrl = 'https://api.dev.jarvis.cx'; // Base API URL
  static const String kbCoreApiUrl = 'https://api.dev.jarvis.cx'; // KB Core API URL (could be different in some environments)
  
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
  
  // Assistant Management endpoints (renamed from Bot to Assistant for consistency with API)
  static const String assistantsEndpoint = '/kb-core/v1/ai-assistant';
  static const String assistantById = '/kb-core/v1/ai-assistant/{assistantId}';
  static const String assistantKnowledge = '/kb-core/v1/ai-assistant/{assistantId}/knowledge';
  static const String assistantKnowledgeById = '/kb-core/v1/ai-assistant/{assistantId}/knowledge/{knowledgeBaseId}';
  static const String assistantAsk = '/kb-core/v1/ai-assistant/{assistantId}/ask';
  static const String assistantPublish = '/kb-core/v1/ai-assistant/{assistantId}/publish';
  static const String assistantPublishPlatform = '/kb-core/v1/ai-assistant/{assistantId}/publish/{platform}';
  static const String assistantConfigurations = '/kb-core/v1/ai-assistant/{assistantId}/configurations';
  static const String favoriteAssistant = '/kb-core/v1/ai-assistant/{assistantId}/favorite';
  
  // Thread Management endpoints
  static const String threadsEndpoint = '/kb-core/v1/threads';
  static const String createThreadForAssistant = '/kb-core/v1/ai-assistant/{assistantId}/thread';
  static const String threadById = '/kb-core/v1/threads/{threadId}';
  static const String threadMessages = '/kb-core/v1/threads/{threadId}/messages';
  static const String updateAssistantWithThread = '/kb-core/v1/ai-assistant/{assistantId}/thread/{threadId}';
  
  // Legacy Bot Management endpoints (keeping for backward compatibility)
  static const String botsEndpoint = assistantsEndpoint;
  static const String botById = assistantById;
  static const String botKnowledge = assistantKnowledge;
  static const String botKnowledgeById = assistantKnowledgeById;
  static const String botAsk = assistantAsk;
  static const String botPublish = assistantPublish;
  static const String botPublishPlatform = assistantPublishPlatform;
  static const String botConfigurations = assistantConfigurations;
  
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
