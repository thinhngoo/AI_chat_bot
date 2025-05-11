# Analytics Implementation Guide

This document explains how to use the analytics implementation in the AI Chat Bot app.

## Architecture

The analytics implementation follows a layered architecture to ensure flexibility and maintainability:

```
Analytics Infrastructure
├── AnalyticsService - Core service with Firebase implementation
├── AnalyticsEvents - Standard event definitions
├── GlobalAnalytics - Global utility for easy access
├── AnalyticsProvider - Widget tree provider
└── Feature-specific implementations (e.g., ChatAnalytics)
```

## Available Analytics Services

Our app uses multiple analytics systems to track user behavior and application performance:

1. **Firebase Analytics**: For general app analytics and user engagement metrics
2. **Firebase Crashlytics**: For crash reporting and error tracking
3. **Custom Bot Analytics Service**: For tracking specific bot-related events in our backend

## Using Analytics

There are three ways to log analytics events:

### 1. Using GlobalAnalytics (Recommended)

`GlobalAnalytics` provides a simple interface to access analytics functions anywhere:

```dart
// Import
import '../../../core/services/analytics/global_analytics.dart';

// Track a screen view
GlobalAnalytics().trackScreenView('ScreenName');

// Track a custom event
GlobalAnalytics().trackEvent('custom_event_name', parameters: {
  'param1': 'value1',
  'param2': 'value2',
});

// Track an error
GlobalAnalytics().trackError(
  'error_type', 
  'error message',
  source: 'ErrorSource',
);
```

### 2. Using AnalyticsService Directly

For core functionality, you can use `AnalyticsService`:

```dart
final _analytics = AnalyticsService();

// Screen Views
_analytics.logScreenView(
  screenName: 'ScreenName',
  screenClass: 'ClassName',
);

// Message Events
_analytics.logMessageSent(
  modelId: 'gpt-4o',  
  isCustomBot: false,
  conversationId: 'conversation_id',
);
```

#### Error Events
```dart
_analytics.logError(
  errorType: 'network_error',
  errorMessage: e.toString(),
  additionalData: {
    'additional_data': 'value',
  },
);
```

#### User Properties
```dart
// Set user ID
_analytics.setUserId('user_id');

// Set a user property
_analytics.setUserProperty(
  name: 'subscription_level',
  value: 'pro',
);
```

## Tracking Plan

Below are the key events we track:

1. **Screen Views**: All major screens in the app
2. **Message Events**: When users send messages to AI models or bots
3. **Model Changes**: When users switch between different AI models
4. **Subscription Events**: Upgrade clicks, subscription changes
5. **Error Events**: API errors, token exhaustion, etc.

## Development Guidelines

1. **DO NOT** include sensitive or personally identifiable information in analytics events
2. Use standardized event names to ensure consistency
3. Test analytics events in development to ensure they appear correctly in Firebase
4. Always check if analytics is enabled before logging events:

```dart
if (await GlobalAnalytics().isAnalyticsEnabled()) {
  // Log analytics events
}
```

## Disabling Analytics in Debug Mode

To disable analytics while developing, you can use the following code before initializing Firebase:

```dart
await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false);
```

## Adding New Analytics Events

When adding a new analytics event:

1. Consider what data is important to track
2. Use existing methods in AnalyticsService when possible
3. If needed, add new methods to AnalyticsService following the established pattern
4. Document the new event in this README
