class ApiConstants {
  // Development environment flag - set this to false for production
  static const bool isDevelopmentEnvironment = true;
  
  // API URLs 
  // Note: These are placeholder URLs that won't actually work in development
  // For development, the app will use cached values and defaults
  static const String jarvisApiUrl = isDevelopmentEnvironment 
      ? 'https://dev-api.your-actual-domain.com' 
      : 'https://api.your-actual-domain.com';
      
  static const String subscriptionBaseUrl = '$jarvisApiUrl/subscription';
  static const String usageStatsUrl = '$jarvisApiUrl/usage/stats';
  
  // Ad-related constants
  static const String testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  
  // IAP product IDs
  static const String monthlyProSubscriptionId = 'com.aichatbot.subscription.monthly';
  static const String yearlyProSubscriptionId = 'com.aichatbot.subscription.yearly';
}