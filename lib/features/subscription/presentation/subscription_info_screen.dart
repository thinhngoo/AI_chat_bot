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
import '../../../widgets/dialog.dart';
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
  final Logger logger = Logger();
  Future<void> _loadSubscriptionData({bool forceRefresh = false}) async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final subscription = await _subscriptionService.getCurrentSubscription(forceRefresh: forceRefresh);
      final usageStats = await _subscriptionService.getUsageStats(forceRefresh: forceRefresh);

      logger.d('subscription: $subscription');
      logger.d('usageStats: $usageStats');

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
      _loadSubscriptionData(forceRefresh: true);
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
    final confirm = await GlobalDialog.show(
      context: context,
      title: 'Cancel Subscription',
      message: 'Are you sure you want to cancel your subscription? You\'ll still have access until the end of your current billing period.',
      variant: DialogVariant.warning,
      confirmLabel: 'Yes, Cancel',
      cancelLabel: 'No, Keep It',
    );

    if (confirm != true) return;

    try {
      final success = await _subscriptionService.cancelSubscription();

      if (success && mounted) {
        _loadSubscriptionData(forceRefresh: true);
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
              onPressed: () => _loadSubscriptionData(forceRefresh: true),
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
                  onButtonPressed: () => _loadSubscriptionData(forceRefresh: true),
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
      onRefresh: () => _loadSubscriptionData(forceRefresh: true),
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

            const SizedBox(height: 12),

            if (!isPro) ...[
              Button(
                label: 'Upgrade for Unlimited',
                icon: Icons.diamond,
                onPressed: _navigateToUpgradeScreen,
                isDarkMode: isDarkMode,
                size: ButtonSize.large,
                fontWeight: FontWeight.bold,
              ),

              const SizedBox(height: 12),
            ],

            Button(
              label: 'Logout',
              icon: Icons.logout,
              onPressed: _handleLogout,
              isDarkMode: isDarkMode,
              variant: ButtonVariant.delete,
              size: ButtonSize.large,
              fontWeight: FontWeight.bold,
            ),

            const SizedBox(height: 20),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colors = isDarkMode ? AppColors.dark : AppColors.light;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPro ? Icons.diamond : Icons.account_circle,
                  size: 40,
                  color: isPro ? colors.yellow : Theme.of(context).colorScheme.primary,
                ),
                
                const SizedBox(width: 12),
                
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPro ? 'Pro Plan' : 'Free Plan',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    if (subscription.endDate != null)
                      Text(
                        'Expires ${_formatDate(subscription.endDate!)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).hintColor,
                        )
                      ),
                  ],
                ),
                
                const Spacer(),
                
                if (!isPro)
                  Button(
                    label: 'Upgrade',
                    icon: Icons.diamond,
                    onPressed: onUpgrade,
                    color: Theme.of(context).colorScheme.onSurface,
                    isDarkMode: isDarkMode,
                    variant: ButtonVariant.ghost,
                    fullWidth: false,
                  ),
              ],
            ),
            
            if (isPro) ...[
              const SizedBox(height: 8),
              Divider(color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 12),
              SwitchListTile(
                title: Text(
                  'Auto-renew subscription',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold
                  ),
                ),
                subtitle: Text(
                  subscription.autoRenew
                    ? 'Your subscription will renew automatically'
                    : 'Your subscription will expire on ${_formatDate(subscription.endDate!)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).hintColor),
                ),
                value: subscription.autoRenew,
                onChanged: (_) => onToggleAutoRenew(),
              ),

              const SizedBox(height: 24),

              Center(
                child: Button(
                  label: 'Cancel Subscription',
                  icon: Icons.cancel,
                  onPressed: onCancelSubscription,
                  color: Theme.of(context).colorScheme.error,
                  isDarkMode: isDarkMode,
                  variant: ButtonVariant.ghost,
                  ghostAlpha: 50,
                  size: ButtonSize.medium,
                  fullWidth: false,
                  fontWeight: FontWeight.bold,
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appearance',
              style: Theme.of(context).textTheme.headlineMedium,
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
                ),
                _buildThemeOption(
                  context: context,
                  icon: Icons.dark_mode,
                  label: 'Dark',
                  isSelected: themePreference == 'dark',
                  onTap: () => onThemeChanged('dark'),
                ),
                _buildThemeOption(
                  context: context,
                  icon: Icons.light_mode,
                  label: 'Light',
                  isSelected: themePreference == 'light',
                  onTap: () => onThemeChanged('light'),
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
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDarkMode ? Theme.of(context).colorScheme.onSurface : Colors.amber.shade300;

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
                  : Theme.of(context).colorScheme.outline,
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
                    : Theme.of(context).hintColor,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? primaryColor
                      : Theme.of(context).hintColor,
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
    final colors = Theme.of(context).colorScheme.brightness == Brightness.dark ? AppColors.dark : AppColors.light;
    
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
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Text(
                      'Total tokens used',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    
                    const Spacer(),

                    if (isPro)
                      Icon(Icons.all_inclusive, color: colors.green)
                    else
                      Text(
                        '${usageStats.totalTokensUsed} / ${usageStats.totalTokensLimit}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                  ],
                ),
                
                const SizedBox(height: 4),

                LinearProgressIndicator(
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(16),
                  value: isPro ? 1 : usageStats.usagePercentage,
                  backgroundColor: Theme.of(context).colorScheme.onSurface.withAlpha(30),
                  valueColor: isPro ? AlwaysStoppedAnimation<Color>(colors.green) : AlwaysStoppedAnimation<Color>(
                    Color.lerp(colors.green, colors.red, usageStats.usagePercentage) ?? colors.red,
                  ),
                ),
                
                const SizedBox(height: 16),

                if (!isPro && usageStats.totalTokensLimit > 0) ...[
                  Text(
                    'Current period: ${usageStats.formattedPeriod}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(178),
                    ),
                  ),
                ],

                if (isPro) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: colors.green),
                      
                      const SizedBox(width: 8),
                      
                      Text(
                        'Unlimited tokens with Pro subscription',
                        style: TextStyle(
                          color: colors.green,
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
                  style: Theme.of(context).textTheme.headlineMedium,
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
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            if (!isPro && model.tokenLimit > 0)
                              Text(
                                '${model.remainingTokensFormatted} tokens left',
                                style: Theme.of(context).textTheme.bodyMedium,
                              )
                            else if (isPro)
                              Text(
                                'Unlimited',
                                style: TextStyle(
                                  color: colors.green,
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
                            backgroundColor: Theme.of(context).colorScheme.onSurface.withAlpha(30),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color.lerp(colors.green, colors.red, model.usagePercentage) ?? colors.red,
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
