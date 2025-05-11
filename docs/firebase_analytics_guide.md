# Firebase Analytics Implementation Guide

This document explains how to use the analytics system in the AI Chat Bot project.

## Overview of the Analytics System

The application uses the following systems to track user behavior and application performance:

1. **Firebase Analytics**: Tracks user behavior and interaction with the application
2. **Firebase Crashlytics**: Tracks and reports application errors
3. **Custom Bot Analytics**: Tracks bot usage and provides a dedicated API for bot analytics
4. **Global Analytics**: A simple utility for accessing analytics functions throughout the app

## Analytics Architecture

Our analytics implementation includes:

1. `AnalyticsService`: Core service that handles Firebase Analytics and custom backend analytics
2. `AnalyticsEvents`: Standardized event names and parameters 
3. `ChatAnalytics`: Chat-specific analytics helper
4. `GlobalAnalytics`: Utility for easier access to analytics functions throughout the app
5. `AnalyticsProvider`: Provider for widget tree access
6. `AnalyticsSettings`: User interface for privacy controls

## How to Use Analytics in the Application

### 1. Access through AnalyticsProvider

```dart
// Trong bất kỳ widget nào trong cây widget
final analytics = AnalyticsProvider.of(context);

// Ghi nhật ký một sự kiện
await analytics.logFeatureUsed(
  featureName: 'feature_name',
  additionalParams: {'key': 'value'}
);
```

### 2. Sử dụng các lớp Analytics chuyên biệt

Chúng tôi khuyến khích sử dụng các lớp chuyên biệt cho từng tính năng, ví dụ `ChatAnalytics` cho màn hình chat:

```dart
final chatAnalytics = ChatAnalytics(AnalyticsService());

// Ghi nhật ký một sự kiện chat cụ thể
await chatAnalytics.logMessageSent(
  modelId: 'gpt-4o',
  isCustomBot: false,
  conversationId: 'conversation-id',
  message: 'User message'
);
```

## Sự kiện và thuộc tính tiêu chuẩn

Hệ thống phân tích sử dụng một tập hợp các sự kiện và thuộc tính tiêu chuẩn, được định nghĩa trong `AnalyticsEvents`:

### Sự kiện người dùng
- `chat_started`: Khi bắt đầu cuộc trò chuyện mới
- `message_sent`: Khi gửi tin nhắn
- `ai_model_switched`: Khi chuyển đổi giữa các mô hình
- `prompt_used`: Khi sử dụng prompt
- `error_occurred`: Khi xảy ra lỗi

### Sự kiện đăng ký
- `subscription_view`: Khi xem trang đăng ký
- `subscription_attempt`: Khi cố gắng đăng ký
- `subscription_success`: Khi đăng ký thành công
- `subscription_error`: Khi đăng ký thất bại
- `token_low`: Khi token gần hết

### Thuộc tính người dùng
- `subscription_level`: Cấp độ đăng ký
- `preferred_model`: Mô hình AI ưa thích
- `theme_preference`: Chủ đề giao diện
- `is_power_user`: Người dùng nâng cao

## Cách thêm sự kiện phân tích mới

1. Thêm hằng số sự kiện mới vào `AnalyticsEvents` nếu đó là một sự kiện tiêu chuẩn
2. Thêm phương thức mới vào lớp Analytics chuyên biệt nếu liên quan đến một tính năng cụ thể
3. Gọi phương thức trong mã nguồn khi sự kiện xảy ra

### Ví dụ:

```dart
// Trong lớp Analytics chuyên biệt
Future<void> logNewCustomEvent({
  required String param1,
  String? param2,
}) async {
  await _analytics.logEvent(
    name: 'custom_event_name',
    parameters: {
      'param1': param1,
      if (param2 != null) 'param2': param2,
    },
  );
}
```

## Kiểm thử Analytics

Hệ thống phân tích có thể được kiểm thử bằng cách sử dụng mock:

```dart
test('logMessageSent logs correct data', () {
  final mockAnalytics = MockAnalyticsService();
  final chatAnalytics = ChatAnalytics(mockAnalytics);
  
  chatAnalytics.logMessageSent(...);
  
  verify(mockAnalytics.logEvent(...)).called(1);
});
```

## Chế độ debug và gỡ lỗi

Để theo dõi các sự kiện đang được gửi đến Firebase Analytics:

1. Trong Firebase console, chọn dự án và mở tính năng DebugView
2. Trong ứng dụng, bật chế độ debug cho Analytics bằng cách đặt:

```dart
await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
```

## Privacy Compliance

- Do not log sensitive information such as passwords, payment information, or personal data
- Refer to the project's privacy policy before adding new analytics events
- Make sure users can disable analytics data collection if they want
- Use the AnalyticsSettings screen for user opt-out functionality

## Best Practices

1. Use standardized event names from `AnalyticsEvents` class
2. Keep parameters consistent across similar events
3. Add analytics tracking for new features
4. Respect user privacy choices
5. Document new analytics events in this guide

## Dashboard

View collected data in the Firebase Console:
- Go to [Firebase Console](https://console.firebase.google.com/)
- Select the AI Chat Bot project
- Navigate to Analytics

## Troubleshooting

Common issues with analytics implementation:

1. **Events Not Appearing**: Events can take up to 24 hours to appear in the console
2. **Debug Mode**: Use Firebase Debug Mode to quickly validate events
3. **Parameter Limits**: Event names are limited to 40 characters, parameter names to 40 characters, and parameter values to 100 characters
