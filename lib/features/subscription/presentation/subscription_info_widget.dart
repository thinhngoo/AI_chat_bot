import 'package:flutter/material.dart';
import '../../../widgets/background_refresh_indicator_fixed.dart';
import '../models/subscription_model.dart';
import '../services/subscription_service_fixed.dart';
import '../../../core/services/auth/auth_service.dart';
import 'package:logger/logger.dart';

class SubscriptionInfoWidget extends StatefulWidget {
  const SubscriptionInfoWidget({super.key});

  @override
  State<SubscriptionInfoWidget> createState() => _SubscriptionInfoWidgetState();
}

class _SubscriptionInfoWidgetState extends State<SubscriptionInfoWidget> {
  late final SubscriptionService _subscriptionService;
  final Logger _logger = Logger();
  
  Subscription? _subscription;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _subscriptionService = SubscriptionService(AuthService(), _logger);
    _loadSubscriptionInfo();
  }
  
  @override
  void dispose() {
    _subscriptionService.dispose();
    super.dispose();
  }
  
  Future<void> _loadSubscriptionInfo() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final subscription = await _subscriptionService.getCurrentSubscription();
      
      if (mounted) {
        setState(() {
          _subscription = subscription;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error loading subscription',
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.red),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSubscriptionInfo,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    final subscription = _subscription;
    if (subscription == null) {
      return const Center(
        child: Text('No subscription information available'),
      );
    }
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  'Current Plan: ${subscription.isPro ? 'Pro' : 'Free'}',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(width: 8),
                // Use the StreamBackgroundRefreshIndicator to show when background refresh is happening
                StreamBackgroundRefreshIndicator(
                  refreshStream: _subscriptionService.subscriptionRefreshingStream,
                ),
              ],
            ),
            const Divider(),
            if (subscription.isPro) ...[
              Text(
                'Pro Features:',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _buildFeatureRow('💾 Token Limit:', 'Unlimited'),
              _buildFeatureRow('🤖 Custom Bots:', 'Unlimited'),
              _buildFeatureRow(
                '🧠 Available Models:',
                subscription.features['allowedModels']?.join(', ') ?? 'None',
              ),
              const SizedBox(height: 16),
              Text(
                'Subscription Details:',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _buildFeatureRow(
                '📅 Start Date:',
                subscription.startDate.toString().split(' ')[0],
              ),
              if (subscription.endDate != null)
                _buildFeatureRow(
                  '⏱️ End Date:',
                  subscription.endDate.toString().split(' ')[0],
                ),
              _buildFeatureRow(
                '🔄 Auto-renew:',
                subscription.autoRenew ? 'Enabled' : 'Disabled',
              ),
            ] else ...[
              Text(
                'Free Plan Limitations:',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _buildFeatureRow(
                '💾 Token Limit:',
                subscription.features['tokenLimit']?.toString() ?? 'Unknown',
              ),
              _buildFeatureRow(
                '🤖 Custom Bots:',
                'Up to ${subscription.features['maxBots']?.toString() ?? '0'}',
              ),
              _buildFeatureRow(
                '🧠 Available Models:',
                subscription.features['allowedModels']?.join(', ') ?? 'None',
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Handle upgrade action
                },
                child: const Text('Upgrade to Pro'),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await _subscriptionService.getCurrentSubscription(forceRefresh: true);
                if (mounted) {
                  setState(() {});
                }
              },
              child: const Text('Refresh Subscription Info'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeatureRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
