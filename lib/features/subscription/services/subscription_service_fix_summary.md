# Subscription Service Improvements

## Problem Description
The `SubscriptionService` was experiencing frequent connection timeout errors during API calls. The primary issues were:

1. Short, inflexible timeouts (fixed at 5 seconds)
2. Lack of proper background refresh mechanisms
3. Limited caching strategy with no tiered expiration
4. No UI indicators for background refresh operations
5. No proper tracking of cache freshness

## Solution Implemented

### 1. Tiered Caching System

Implemented a more sophisticated caching system with two thresholds:
- **Stale Threshold (1 minute)**: When cache becomes stale but still usable, triggering background refresh
- **Hard Expiration (3 minutes)**: When cache is considered fully expired and must be refreshed

```dart
// Tiered cache expiration strategies
static const Duration _cacheStaleThreshold = Duration(minutes: 1);
static const Duration _cacheHardExpiration = Duration(minutes: 3);
```

### 2. Improved Timeout Handling

Configured two different timeout levels:
- **Normal API calls (8 seconds)**: For regular user-initiated operations
- **Background refreshes (15 seconds)**: More patience for background operations

```dart
// Different timeout levels for better performance
static const Duration _normalTimeoutDuration = Duration(seconds: 8); 
static const Duration _backgroundTimeoutDuration = Duration(seconds: 15);
```

### 3. Background Refresh Capabilities

Added dedicated methods that refresh data in the background while returning cached data:
```dart
Future<void> _refreshSubscriptionInBackground() async {
  if (_isRefreshingSubscription) return; // Prevent multiple simultaneous refreshes
  
  try {
    // Implementation omitted for brevity
  } catch (e) {
    _logger.w('Background subscription refresh failed: $e');
    // No need to throw, this is a background operation
  } finally {
    _setRefreshingStatus(_subscriptionRefreshingController, false);
  }
}
```

### 4. UI Refresh Indicators

Added stream controllers for all major API calls to notify the UI about background refreshes:
```dart
// Stream controllers for notifying listeners about refresh status
final StreamController<bool> _subscriptionRefreshingController = StreamController<bool>.broadcast();
final StreamController<bool> _usageStatsRefreshingController = StreamController<bool>.broadcast();
final StreamController<bool> _tokenUsageRefreshingController = StreamController<bool>.broadcast();
final StreamController<bool> _subscriptionInfoRefreshingController = StreamController<bool>.broadcast();
  
// Getter streams for UI to observe refresh status
Stream<bool> get subscriptionRefreshingStream => _subscriptionRefreshingController.stream;
Stream<bool> get usageStatsRefreshingStream => _usageStatsRefreshingController.stream;
Stream<bool> get tokenUsageRefreshingStream => _tokenUsageRefreshingController.stream;
Stream<bool> get subscriptionInfoRefreshingStream => _subscriptionInfoRefreshingController.stream;
```

### 5. Improved Cache Timestamp Tracking

Added timestamp tracking for each data type:
```dart
DateTime? _lastSubscriptionFetchTime;
DateTime? _lastUsageStatsFetchTime;
DateTime? _lastTokenUsageFetchTime;
DateTime? _lastSubscriptionInfoFetchTime;
```

### 6. Prevention of Simultaneous Refresh Requests

Added safeguards to prevent multiple simultaneous refresh requests:
```dart
bool _isRefreshingSubscription = false;
bool _isRefreshingUsageStats = false;
bool _isRefreshingTokenUsage = false;
bool _isRefreshingSubscriptionInfo = false;
```

### 7. Enhanced Error Handling

Improved error handling with better logging and fallback mechanisms:
```dart
try {
  // API call code
} catch (e) {
  _logger.e('Error getting subscription: $e');
  
  // Try to get cached data if available
  final cachedSubscription = await _getCachedSubscription();
  if (cachedSubscription != null) {
    _logger.i('Using cached subscription data after error');
    _currentSubscription = cachedSubscription;
    return cachedSubscription;
  }
  
  // Return a default as last resort
  return _getDefaultSubscription();
} finally {
  _setRefreshingStatus(_subscriptionRefreshingController, false);
}
```

### 8. Proper Resource Cleanup

Added dispose method to clean up resources:
```dart
void dispose() {
  _subscriptionRefreshingController.close();
  _usageStatsRefreshingController.close();
  _tokenUsageRefreshingController.close();
  _subscriptionInfoRefreshingController.close();
}
```

### 9. Cache Expiration Checks

Added proper cache expiration checks for retrieving cached data:
```dart
// Check if cache is expired (hard expiration)
if (cacheTimeStr != null) {
  final cacheTime = DateTime.parse(cacheTimeStr);
  if (_isCacheExpired(cacheTime)) {
    _logger.d('Cached subscription data is hard expired');
    return null;
  }
}
```

## Usage with Background Refresh Indicator

To use the improved service with the background refresh indicator in your widgets:

```dart
Widget build(BuildContext context) {
  return Column(
    children: [
      Row(
        children: [
          Text('Subscription Info'),
          StreamBackgroundRefreshIndicator(
            refreshStream: _subscriptionService.subscriptionRefreshingStream,
          ),
        ],
      ),
      // Rest of your UI
    ],
  );
}
```

## Next Steps

1. Replace the original `SubscriptionService` implementation with this improved version
2. Test all API endpoints with various network conditions
3. Update UI components to use the new refresh indicator streams 
4. Add automated tests for timeout and cache scenarios
