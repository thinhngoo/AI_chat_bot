import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/subscription_model.dart';
import '../models/usage_stats.dart';
import '../services/subscription_service.dart';
import 'pro_upgrade_screen.dart';
import 'package:logger/logger.dart';
import '../../../core/services/auth/auth_service.dart';

class SubscriptionInfoScreen extends StatefulWidget {
  const SubscriptionInfoScreen({super.key});

  @override
  State<SubscriptionInfoScreen> createState() => _SubscriptionInfoScreenState();
}

class _SubscriptionInfoScreenState extends State<SubscriptionInfoScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService(
    AuthService(),
    Logger(),
  );

  bool _isLoading = true;
  String _errorMessage = '';
  Subscription? _subscription;
  UsageStats? _usageStats;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
  }

  Future<void> _loadSubscriptionData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final subscription = await _subscriptionService.getCurrentSubscription();
      final usageStats = await _subscriptionService.getUsageStats();

      if (mounted) {
        setState(() {
          _subscription = subscription;
          _usageStats = usageStats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load subscription data: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateToUpgradeScreen() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProUpgradeScreen(),
      ),
    );

    if (result == true) {
      _loadSubscriptionData();
    }
  }

  Future<void> _toggleAutoRenew() async {
    if (_subscription == null) return;

    try {
      final currentValue = _subscription!.autoRenew;
      final success =
          await _subscriptionService.toggleAutoRenewal(!currentValue);

      if (success && mounted) {
        _loadSubscriptionData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Auto-renewal ${!currentValue ? 'enabled' : 'disabled'}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to update auto-renewal: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _cancelSubscription() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text(
            'Are you sure you want to cancel your subscription? '
            'You\'ll still have access until the end of your current billing period.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No, Keep It'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final success = await _subscriptionService.cancelSubscription();

      if (success && mounted) {
        _loadSubscriptionData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription canceled successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to cancel subscription: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSubscriptionData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadSubscriptionData,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : _subscription != null
                  ? _buildSubscriptionInfo()
                  : const Center(
                      child: Text('No subscription information available')),
    );
  }

  Widget _buildSubscriptionInfo() {
    final isPro = _subscription!.isPro;
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _loadSubscriptionData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Plan info card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isPro
                              ? Icons.workspace_premium
                              : Icons.account_circle,
                          size: 40,
                          color:
                              isPro ? Colors.amber : theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPro ? 'Pro Plan' : 'Free Plan',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_subscription!.endDate != null)
                              Text(
                                'Expires ${_formatDate(_subscription!.endDate!)}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.7),
                                ),
                              ),
                          ],
                        ),
                        const Spacer(),
                        if (!isPro)
                          ElevatedButton(
                            onPressed: _navigateToUpgradeScreen,
                            child: const Text('Upgrade'),
                          ),
                      ],
                    ),
                    if (isPro) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('Auto-renew subscription'),
                        subtitle: Text(_subscription!.autoRenew
                            ? 'Your subscription will renew automatically'
                            : 'Your subscription will expire on ${_formatDate(_subscription!.endDate!)}'),
                        value: _subscription!.autoRenew,
                        onChanged: (_) => _toggleAutoRenew(),
                      ),
                      TextButton(
                        onPressed: _cancelSubscription,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Cancel Subscription'),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Token usage section
            Text(
              'Token Usage',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            if (_usageStats != null) ...[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total tokens used:',
                                style: theme.textTheme.titleSmall,
                              ),
                              Text(
                                _usageStats!.formattedTotalTokensUsed,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Tokens remaining:',
                                style: theme.textTheme.titleSmall,
                              ),
                              Text(
                                _usageStats!.tokensRemainingFormatted,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isPro ? Colors.green : null,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (!isPro && _usageStats!.totalTokensLimit > 0) ...[
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: _usageStats!.usagePercentage,
                          backgroundColor: theme.colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Current period: ${_usageStats!.formattedPeriod}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                      if (isPro) ...[
                        const SizedBox(height: 16),
                        const Row(
                          children: [
                            Icon(Icons.all_inclusive, color: Colors.green),
                            SizedBox(width: 8),
                            Text(
                              'Unlimited tokens with Pro subscription',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Model breakdown section
              Text(
                'Usage by Model',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var model in _usageStats!.modelUsage)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                model.modelName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Tokens used: ${NumberFormat.compact().format(model.tokensUsed)}',
                                    ),
                                  ),
                                  if (!isPro && model.tokenLimit > 0)
                                    Text(
                                      'Remaining: ${model.remainingTokensFormatted}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    )
                                  else if (isPro)
                                    const Text(
                                      'Unlimited',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                              if (!isPro && model.tokenLimit > 0) ...[
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: model.usagePercentage,
                                  backgroundColor:
                                      theme.colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Upgrade button at bottom (if not Pro)
            if (!isPro)
              ElevatedButton.icon(
                onPressed: _navigateToUpgradeScreen,
                icon: const Icon(Icons.workspace_premium),
                label: const Text('Upgrade to Pro for Unlimited Tokens'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference < 0) {
      return 'Expired';
    } else if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
