import 'package:flutter/widgets.dart';
import 'analytics_service.dart';

/// A provider that makes analytics service accessible throughout the widget tree
class AnalyticsProvider extends InheritedWidget {
  final AnalyticsService analytics;
  
  const AnalyticsProvider({
    Key? key,
    required this.analytics,
    required Widget child,
  }) : super(key: key, child: child);
  
  static AnalyticsService of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<AnalyticsProvider>();
    assert(provider != null, 'No AnalyticsProvider found in context');
    return provider!.analytics;
  }

  @override
  bool updateShouldNotify(AnalyticsProvider oldWidget) {
    // Analytics service is a singleton, so we shouldn't need to update
    return false;
  }
}
