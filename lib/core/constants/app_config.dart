class AppConfig {
  // API URL for backend services
  static const String apiUrl = 'https://knowledge-api.dev.jarvis.cx/kb-core/v1';
  
  // Other app configuration constants
  static const int defaultPageSize = 10;
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB in bytes
  
  // Feature flags
  static const bool enableGoogleDrive = true;
  static const bool enableSlackIntegration = true;
  static const bool enableConfluenceIntegration = true;
}