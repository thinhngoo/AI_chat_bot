import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/subscription_model.dart';
import '../models/usage_stats.dart';
import '../services/subscription_service.dart';
import 'pro_upgrade_screen.dart';
import 'package:logger/logger.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/button.dart';
import '../../../widgets/information.dart';
import '../../auth/presentation/login_page.dart';

class SubscriptionInfoScreen extends StatefulWidget {
  const SubscriptionInfoScreen({super.key});

  @override
  State<SubscriptionInfoScreen> createState() => _SubscriptionInfoScreenState();
}

class _SubscriptionInfoScreenState extends State<SubscriptionInfoScreen> {
  final AuthService _authService = AuthService();
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
    // TEMPORARY
    // setState(() {
    //   _isLoading = false;
    //   _errorMessage = '';
    //   _subscription = Subscription(
    //     id: '1',
    //     plan: SubscriptionPlan.free,
    //     // plan: SubscriptionPlan.pro,
    //     startDate: DateTime.now(),
    //     // endDate: DateTime.now().add(const Duration(days: 30)),
    //     autoRenew: true,
    //     features: {
    //       'Unlimited tokens': false,
    //       'Unlimited requests': false,
    //       'Unlimited models': false,
    //     },
    //   );
    //   _usageStats = UsageStats(
    //     totalTokensUsed: 401,
    //     totalTokensLimit: 400,
    //     currentPeriodTokensUsed: 20,
    //     periodStart: DateTime.now(),
    //     periodEnd: DateTime.now().add(const Duration(days: 30)),
    //     modelBreakdown: {
    //       'gpt-4o': (0.2 * 300).round(),
    //       'gpt-4o-mini': (0.4 * 40).round(),
    //       'claude-3-haiku': (0.3 * 60).round(),
    //     },
    //   );
    // });
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

  Future<void> _handleLogout() async {
    final navigator = Navigator.of(context);
    
    try {
      final success = await _authService.signOut();

      if (success && mounted) {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (ctx) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to logout: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final AppColors colors = isDarkMode ? AppColors.dark : AppColors.light;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadSubscriptionData,
              tooltip: 'Refresh',
            ),
          ),
        ],
      ),
      body: _isLoading
          ? InformationIndicator(
              message: 'Loading subscription data...',
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error,
                          color: colors.error,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colors.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        MiniGhostButton(
                          label: 'Try Again',
                          icon: Icons.refresh,
                          onPressed: _loadSubscriptionData,
                          color: colors.foreground,
                          isDarkMode: isDarkMode,
                        ),
                      ],
                    ),
                  ),
                )
              : _subscription != null
                  ? _buildSubscriptionInfo()
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: colors.muted,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No subscription information available',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildSubscriptionInfo() {
    final isPro = _subscription!.isPro;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final AppColors colors = isDarkMode ? AppColors.dark : AppColors.light;
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
                              style: theme.textTheme.headlineMedium,
                            ),
                            if (_subscription!.endDate != null)
                              Text(
                                'Expires ${_formatDate(_subscription!.endDate!)}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withAlpha(128),
                                ),
                              ),
                          ],
                        ),
                        const Spacer(),
                        if (!isPro)
                          MiniGhostButton(
                            label: 'Upgrade',
                            icon: Icons.workspace_premium,
                            onPressed: _navigateToUpgradeScreen,
                            color: colors.cardForeground,
                            isDarkMode: isDarkMode,
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

            const SizedBox(height: 12),

            // Token usage section
            if (_usageStats != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Token Usage',
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Text(
                            'Total tokens used',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const Spacer(),
                          Text(
                            '${_usageStats != null ? NumberFormat.compact().format(_usageStats!.totalTokensUsed) : "None"} / ${_usageStats != null ? NumberFormat.compact().format(_usageStats!.totalTokensLimit) : "No Limit"}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),

                      LinearProgressIndicator(
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(16),
                        value: _usageStats!.usagePercentage,
                        backgroundColor:
                            theme.colorScheme.onSurface.withAlpha(30),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color.lerp(Colors.green, Colors.red, _usageStats!.usagePercentage) ?? Colors.red,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (!isPro && _usageStats!.totalTokensLimit > 0) ...[
                        Text(
                          'Current period: ${_usageStats!.formattedPeriod}',                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(178), // Changed from withOpacity(0.7) to withAlpha(178) - 0.7*255=178
                          ),
                        ),
                      ],
                      if (isPro) ...[
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

              const SizedBox(height: 12),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Usage by Model',
                        style: theme.textTheme.headlineMedium,
                      ),
                      
                      const SizedBox(height: 16),

                      for (var model in _usageStats!.modelUsage)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      model.modelName,
                                      style:
                                          theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                  if (!isPro && model.tokenLimit > 0)
                                    Text(
                                      '${model.remainingTokensFormatted} tokens left',
                                      style: theme.textTheme.bodyMedium,
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
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(16),
                                  value: model.usagePercentage,
                                  backgroundColor:
                                      theme.colorScheme.onSurface.withAlpha(30),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color.lerp(Colors.green, Colors.red, model.usagePercentage) ?? Colors.red,
                                  ),
                                ),
                              ],
                              
                              const SizedBox(height: 8),
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
              LargeButton(
                label: 'Upgrade to Pro for Unlimited Tokens',
                icon: Icons.workspace_premium,
                onPressed: _navigateToUpgradeScreen,
                isDarkMode: isDarkMode,
              ),

            const SizedBox(height: 20),
            
            // Logout button
            LargeButton(
              label: 'Logout',
              icon: Icons.logout,
              onPressed: _handleLogout,
              isDarkMode: isDarkMode,
              isPrimary: false,
              isDelete: true,
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
