# Connection Timeout & Caching Improvements Integration Guide

This guide explains how to integrate the improved services that fix connection timeout issues and implement better caching strategies.

## Overview of Changes

We've created three main components:

1. **Improved Service Implementations**:
   - `subscription_service_fixed.dart` - Optimized subscription service
   - `bot_service_optimized.dart` - Optimized bot service

2. **Wrapper Services**:
   - `subscription_service_wrapper.dart` - Wrapper for smooth transition
   - `bot_service_wrapper.dart` - Wrapper for smooth transition

3. **UI Components**:
   - `background_refresh_indicator_fixed.dart` - Visual feedback for background operations
   - `splash_screen_extensions.dart` - Extensions for SplashScreen

## Integration Steps

### Step 1: Update Service Imports

Replace direct imports of BotService and SubscriptionService with wrapper versions:

```dart
// OLD
import '../../features/bot/services/bot_service.dart';
import '../../features/subscription/services/subscription_service.dart';

// NEW
import '../../features/bot/services/bot_service_wrapper.dart';
import '../../features/subscription/services/subscription_service_wrapper.dart';
```

### Step 2: Update Service Instantiation

Replace direct instantiation with wrapper instantiation:

```dart
// OLD
final BotService _botService = BotService();
final SubscriptionService _subscriptionService = SubscriptionService(_authService, _logger);

// NEW
final BotServiceWrapper _botService = BotServiceWrapper();
final SubscriptionServiceWrapper _subscriptionService = SubscriptionServiceWrapper();
```

### Step 3: Add Background Refresh Indicators

Add visual feedback using the StreamBackgroundRefreshIndicator:

```dart
Row(
  children: [
    Text('Subscription Info'),
    const SizedBox(width: 8),
    StreamBackgroundRefreshIndicator(
      refreshStream: _subscriptionService.subscriptionRefreshingStream,
    ),
  ],
)
```

### Step 4: Cleanup Resources

Don't forget to dispose of the services when they're no longer needed:

```dart
@override
void dispose() {
  _botService.dispose();
  _subscriptionService.dispose();
  super.dispose();
}
```

## Example: Updating a Screen with Background Refresh

```dart
import 'package:flutter/material.dart';
import '../../features/subscription/services/subscription_service_wrapper.dart';
import '../../widgets/background_refresh_indicator_fixed.dart';

class SubscriptionScreen extends StatefulWidget {
  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _subscriptionService = SubscriptionServiceWrapper();
  bool _isLoading = true;
  var _subscriptionData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  @override
  void dispose() {
    _subscriptionService.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _subscriptionService.getCurrentSubscription();
      setState(() {
        _subscriptionData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Subscription'),
            const SizedBox(width: 8),
            StreamBackgroundRefreshIndicator(
              refreshStream: _subscriptionService.subscriptionRefreshingStream,
            ),
          ],
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _buildContent(),
    );
  }
  
  Widget _buildContent() {
    // Build your content here
    return Text('Subscription: ${_subscriptionData.plan}');
  }
}
```

## Benefits of These Improvements

1. **Graceful Degradation**: Services will always try to return cached data on timeout
2. **Background Refreshing**: Stale data is refreshed in background without blocking UI
3. **Visual Feedback**: Users are informed when background operations are happening
4. **Tiered Expiration**: Different expiration times for stale vs. expired data
5. **Safe Migration**: Wrapper services allow gradual rollout of improved implementations

## Testing the Implementation

After integrating these changes, you should verify that the application:

1. Loads quickly, even with poor connectivity
2. Shows background refresh indicators when appropriate
3. Doesn't freeze or display loading indicators unnecessarily
4. Gracefully handles API timeouts
5. Uses cached data appropriately when APIs are unavailable
