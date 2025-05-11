import 'dart:async';
import 'package:flutter/material.dart';
import '../../widgets/background_refresh_indicator_fixed.dart';
import '../../features/bot/services/bot_service_wrapper.dart';
import '../../features/subscription/services/subscription_service_wrapper.dart';

/// Extension methods to enhance SplashScreen functionality with background refresh indicators
extension SplashScreenExtensions on Widget {
  /// Adds a background refresh indicator to the SplashScreen
  /// This widget will automatically show when any background operation is in progress
  Widget withBackgroundRefreshIndicator({
    required BuildContext context,
    required BotServiceWrapper botService,
    required SubscriptionServiceWrapper subscriptionService,
  }) {
    return Stack(
      children: [
        // Original widget
        this,
        
        // Position the indicator at the top-right corner
        Positioned(
          top: 8,
          right: 8,
          child: _buildCombinedRefreshIndicator(
            context: context,
            botService: botService,
            subscriptionService: subscriptionService,
          ),
        ),
      ],
    );
  }
}

/// Builds a combined background refresh indicator that watches multiple refresh streams
Widget _buildCombinedRefreshIndicator({
  required BuildContext context,
  required BotServiceWrapper botService,
  required SubscriptionServiceWrapper subscriptionService,
}) {
  return StreamBuilder<bool>(
    // Merge all streams into a single boolean stream that is true when any refresh is happening
    stream: _mergeStreams([
      botService.refreshingStream,
      subscriptionService.subscriptionRefreshingStream,
      subscriptionService.usageStatsRefreshingStream,
      subscriptionService.tokenUsageRefreshingStream,
      subscriptionService.subscriptionInfoRefreshingStream,
    ]),
    initialData: false,
    builder: (context, snapshot) {
      // Check if any service is refreshing
      final isAnyRefreshing = snapshot.data ?? false;
      
      return AnimatedOpacity(
        opacity: isAnyRefreshing ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(178), // Use withAlpha instead of withOpacity
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              BackgroundRefreshIndicator(
                isRefreshing: isAnyRefreshing,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              const Text(
                'Refreshing data...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Combines multiple boolean streams into a single stream
/// The resulting stream will emit true if any of the source streams emit true
Stream<bool> _mergeStreams(List<Stream<bool>> streams) {
  // Create a controller for the merged stream
  final controller = StreamController<bool>.broadcast();
  
  // Track subscriptions and current values
  final subscriptions = <StreamSubscription<bool>>[];
  final values = List<bool>.filled(streams.length, false);
  
  // Subscribe to all input streams
  for (int i = 0; i < streams.length; i++) {
    final index = i;
    subscriptions.add(
      streams[index].listen(
        (value) {
          values[index] = value;
          // Emit true if any stream has emitted true
          controller.add(values.any((isRefreshing) => isRefreshing));
        },
        onError: controller.addError,
      )
    );
  }
  
  // Close all subscriptions when the controller is closed
  controller.onCancel = () {
    for (final subscription in subscriptions) {
      subscription.cancel();
    }
  };
  
  return controller.stream;
}
