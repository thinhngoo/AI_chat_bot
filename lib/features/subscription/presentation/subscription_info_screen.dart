import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../models/subscription_model.dart';
import '../models/usage_stats.dart';
import '../services/subscription_service.dart';
import '../../auth/presentation/login_page.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/button.dart';
import '../../../widgets/information.dart';
import 'pro_upgrade_screen.dart';

class SubscriptionInfoScreen extends StatefulWidget {
  final Function? toggleTheme;
  final Function? setThemeMode;
  final String? currentThemeMode;

  const SubscriptionInfoScreen(
      {super.key, this.toggleTheme, this.setThemeMode, this.currentThemeMode});

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
  String _themePreference = 'system'; // Default to system

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
    //     startDate: DateTime.now(),
    //     endDate: DateTime.now().add(const Duration(days: 30)),
    //     autoRenew: true,
    //     features: {
    //       'Unlimited tokens': true,
    //       'Unlimited requests': true,
    //       'Unlimited models': true,
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
    _loadThemePreference();
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

  // == Settings Preference ==/
  Future<void> _loadThemePreference() async {
    try {
      // If we have currentThemeMode, use it instead of reading from SharedPreferences
      if (widget.currentThemeMode != null) {
        setState(() {
          _themePreference = widget.currentThemeMode!;
        });
        return;
      }

      // Otherwise, read from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString('theme_preference') ?? 'system';

      if (mounted) {
        setState(() {
          _themePreference = savedTheme;
        });
      }
    } catch (e) {
      // Silently handle error
    }
  }

  Future<void> _saveThemePreference(String preference) async {
    try {
      // Capture the current brightness before async operations
      final currentBrightness = Theme.of(context).brightness;
      
      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_preference', preference);

      // Use setThemeMode if available (preferred)
      if (widget.setThemeMode != null) {
        widget.setThemeMode!(preference);
        return;
      }

      // Fall back to toggleTheme if setThemeMode not available
      if (widget.toggleTheme != null && mounted) {
        // Apply the theme change
        if (preference == 'dark') {
          // Force dark mode
          if (currentBrightness != Brightness.dark) {
            widget.toggleTheme!();
          }
        } else if (preference == 'light') {
          // Force light mode
          if (currentBrightness != Brightness.light) {
            widget.toggleTheme!();
          }
        }
      }
    } catch (e) {
      // Silently handle error
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
        GlobalSnackBar.show(
          context: context,
          message: 'Failed to logout: ${e.toString()}',
          variant: SnackBarVariant.error,
        );
      }
    }
  }

  // == Subscription Actions ==
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
        GlobalSnackBar.show(
          context: context,
          message: 'Auto-renewal ${!currentValue ? 'enabled' : 'disabled'}',
          variant: SnackBarVariant.success,
        );
      }
    } catch (e) {
      if (mounted) {
        GlobalSnackBar.show(
          context: context,
          message: 'Failed to update auto-renewal: ${e.toString()}',
          variant: SnackBarVariant.error,
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
        GlobalSnackBar.show(
          context: context,
          message: 'Subscription canceled successfully',
          variant: SnackBarVariant.success,
        );
      }
    } catch (e) {
      if (mounted) {
        GlobalSnackBar.show(
          context: context,
          message: 'Failed to cancel subscription: ${e.toString()}',
          variant: SnackBarVariant.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account'),
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
              variant: InformationVariant.loading,
              message: 'Loading subscription data...',
            )
          : _errorMessage.isNotEmpty
              ? InformationIndicator(
                  variant: InformationVariant.error,
                  message: _errorMessage,
                  buttonText: 'Try Again',
                  onButtonPressed: _loadSubscriptionData,
                )
              : _subscription != null
                  ? _buildSubscriptionInfo()
                  : InformationIndicator(
                      variant: InformationVariant.info,
                      message: 'No subscription information available',
                    ),
    );
  }

  Widget _buildSubscriptionInfo() {
    final isPro = _subscription!.isPro;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: _loadSubscriptionData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPlanInfoCard(
              subscription: _subscription!,
              onUpgrade: _navigateToUpgradeScreen,
              onToggleAutoRenew: _toggleAutoRenew,
              onCancelSubscription: _cancelSubscription,
            ),

            const SizedBox(height: 12),

            _buildAppearanceSelector(
              themePreference: _themePreference,
              onThemeChanged: (preference) {
                setState(() {
                  _themePreference = preference;
                });
                _saveThemePreference(preference);
              },
              isDarkMode: isDarkMode,
            ),

            const SizedBox(height: 12),

            _buildTokenUsageSection(
              usageStats: _usageStats,
              isPro: isPro,
              isDarkMode: isDarkMode,
            ),

            const SizedBox(height: 24),

            if (!isPro)
              LargeButton(
                label: 'Upgrade for Unlimited',
                icon: Icons.workspace_premium,
                onPressed: _navigateToUpgradeScreen,
                isDarkMode: isDarkMode,
              ),

            const SizedBox(height: 20),

            LargeButton(
              label: 'Logout',
              icon: Icons.logout,
              onPressed: _handleLogout,
              isDarkMode: isDarkMode,
              variant: ButtonVariant.delete,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanInfoCard({
    required Subscription subscription,
    required VoidCallback onUpgrade,
    required VoidCallback onToggleAutoRenew,
    required VoidCallback onCancelSubscription,
  }) {
    final isPro = subscription.isPro;
    final theme = Theme.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final AppColors colors = isDarkMode ? AppColors.dark : AppColors.light;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPro ? Icons.workspace_premium : Icons.account_circle,
                  size: 40,
                  color: isPro ? Colors.amber : theme.colorScheme.primary,
                ),
                
                const SizedBox(width: 12),
                
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPro ? 'Pro Plan' : 'Free Plan',
                      style: theme.textTheme.headlineMedium,
                    ),
                    if (subscription.endDate != null)
                      Text(
                        'Expires ${_formatDate(subscription.endDate!)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.muted,
                        )
                      ),
                  ],
                ),
                
                const Spacer(),
                
                if (!isPro)
                  MiniGhostButton(
                    label: 'Upgrade',
                    icon: Icons.workspace_premium,
                    onPressed: onUpgrade,
                    color: colors.cardForeground,
                    isDarkMode: isDarkMode,
                  ),
              ],
            ),
            
            if (isPro) ...[
              const SizedBox(height: 8),
              Divider(color: colors.border),
              const SizedBox(height: 12),
              SwitchListTile(
                title: Text(
                  'Auto-renew subscription',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.cardForeground,
                    fontWeight: FontWeight.bold
                  ),
                ),
                subtitle: Text(
                  subscription.autoRenew
                    ? 'Your subscription will renew automatically'
                    : 'Your subscription will expire on ${_formatDate(subscription.endDate!)}',
                  style: theme.textTheme.bodyMedium?.copyWith(color: colors.muted),
                ),
                value: subscription.autoRenew,
                onChanged: (_) => onToggleAutoRenew(),
              ),

              const SizedBox(height: 24),

              Center(
                child: MiniGhostButton(
                  label: 'Cancel Subscription',
                  icon: Icons.cancel,
                  onPressed: onCancelSubscription,
                  color: colors.delete,
                  isDarkMode: isDarkMode,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceSelector({
    required String themePreference,
    required ValueChanged<String> onThemeChanged,
    required bool isDarkMode,
  }) {
    final theme = Theme.of(context);
    final colors = isDarkMode ? AppColors.dark : AppColors.light;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appearance',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildThemeOption(
                  context: context,
                  icon: Icons.settings_suggest,
                  label: 'System',
                  isSelected: themePreference == 'system',
                  onTap: () => onThemeChanged('system'),
                  colors: colors,
                ),
                _buildThemeOption(
                  context: context,
                  icon: Icons.dark_mode,
                  label: 'Dark',
                  isSelected: themePreference == 'dark',
                  onTap: () => onThemeChanged('dark'),
                  colors: colors,
                ),
                _buildThemeOption(
                  context: context,
                  icon: Icons.light_mode,
                  label: 'Light',
                  isSelected: themePreference == 'light',
                  onTap: () => onThemeChanged('light'),
                  colors: colors,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required AppColors colors,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDarkMode ? colors.cardForeground : Colors.amber;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withAlpha(20)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? primaryColor
                  : colors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? primaryColor
                    : colors.muted,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? primaryColor
                      : colors.muted,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTokenUsageSection({
    required UsageStats? usageStats,
    required bool isPro,
    required bool isDarkMode,
  }) {
    if (usageStats == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final colors = isDarkMode ? AppColors.dark : AppColors.light;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.muted,
                      ),
                    ),
                    
                    const Spacer(),

                    if (isPro)
                      Icon(Icons.all_inclusive, color: colors.success)
                    else
                      Text(
                        '${usageStats.totalTokensUsed} / ${usageStats.totalTokensLimit}',
                        style: theme.textTheme.bodyMedium,
                      ),
                  ],
                ),
                
                const SizedBox(height: 4),

                LinearProgressIndicator(
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(16),
                  value: usageStats.usagePercentage,
                  backgroundColor: theme.colorScheme.onSurface.withAlpha(30),
                  valueColor: isPro ? AlwaysStoppedAnimation<Color>(colors.success) : AlwaysStoppedAnimation<Color>(
                    Color.lerp(Colors.green, Colors.red, usageStats.usagePercentage) ?? Colors.red,
                  ),
                ),
                
                const SizedBox(height: 16),

                if (!isPro && usageStats.totalTokensLimit > 0) ...[
                  Text(
                    'Current period: ${usageStats.formattedPeriod}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(178),
                    ),
                  ),
                ],

                if (isPro) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: colors.success),
                      
                      const SizedBox(width: 8),
                      
                      Text(
                        'Unlimited tokens with Pro subscription',
                        style: TextStyle(
                          color: colors.success,
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
                
                const SizedBox(height: 20),

                for (var model in usageStats.modelUsage)
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
                                style: theme.textTheme.bodyMedium,
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
                            backgroundColor: theme.colorScheme.onSurface.withAlpha(30),
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
