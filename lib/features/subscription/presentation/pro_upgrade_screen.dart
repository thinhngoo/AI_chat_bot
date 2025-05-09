import 'package:logger/logger.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../services/iap_service.dart';
import '../services/subscription_service.dart';
import '../models/pricing_model.dart';
import '../models/subscription_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../widgets/text_field.dart';
import '../../../widgets/button.dart';
import '../../../widgets/information.dart';

class ProUpgradeScreen extends StatefulWidget {
  const ProUpgradeScreen({super.key});

  @override
  State<ProUpgradeScreen> createState() => _ProUpgradeScreenState();
}

class _ProUpgradeScreenState extends State<ProUpgradeScreen> {
  final IAPService _iapService = IAPService();
  final SubscriptionService _subscriptionService = SubscriptionService(
    AuthService(),
    Logger(),
  );

  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  // Field error states
  String? _cardNumberError;
  String? _expiryError;
  String? _cvvError;
  String? _nameError;
  // ignore: unused_field
  List<PricingPlan> _plans = [];
  // ignore: unused_field
  Subscription? _currentSubscription;
  PricingPlan? _selectedPlan;
  bool _isYearly = true; // Default to yearly for better value
  bool _isLoading = true;
  bool _isProcessing = false;
  String _errorMessage = '';
  @override
  void initState() {
    super.initState();
    _initializeData();
    
    // Reference unused fields to prevent warnings
    _plans = [];
    _currentSubscription = null;

    // TEMPORARY
    //setState(() {
    //   _isLoading = false;
    //   _isProcessing = false;
    //   _errorMessage = 'some error';
    //   _plans = [
    //     PricingPlan(
    //       id: '1',
    //       name: 'Pro',
    //       description: 'Pro subscription',
    //       planType: SubscriptionPlan.pro,
    //       monthlyPrice: 10,
    //       yearlyPrice: 100,
    //       features: [
    //         'Unlimited tokens',
    //         'Unlimited messages',
    //         'Unlimited images',
    //         'Unlimited videos',
    //         'Unlimited audio',
    //         'Unlimited documents',
    //         'Unlimited emails',
    //       ],
    //     ),
    //   ];
    //   _selectedPlan = _plans.firstWhere(
    //     (plan) => plan.planType == SubscriptionPlan.pro,
    //     orElse: () => _plans.first,
    //   );
    //   _isYearly = true;
    // });
 
    // Pre-fill test credit card for demo
    _cardNumberController.text = '4567 3137 8682 2209';
    _expiryController.text = '12/29';
    _cvvController.text = '277';
    _nameController.text = 'Thinh Ngo';

    // Set up listeners to validate on change
    _cardNumberController.addListener(_validateForm);
    _expiryController.addListener(_validateForm);
    _cvvController.addListener(_validateForm);
    _nameController.addListener(_validateForm);

    // Initial validation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validateForm();
    });
  }

  @override
  void dispose() {
    _cardNumberController.removeListener(_validateForm);
    _expiryController.removeListener(_validateForm);
    _cvvController.removeListener(_validateForm);
    _nameController.removeListener(_validateForm);

    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // == Payment ==
  Future<void> _initializeData() async {
    try {
      // Load subscription plans and current subscription
      final plans = await _subscriptionService.getAvailablePlans();
      final currentSubscription =
          await _subscriptionService.getCurrentSubscription();

      // Initialize IAP service
      await _iapService.initializeIAP();

      if (mounted) {
        setState(() {
          _plans = plans;
          _currentSubscription = currentSubscription;
          _selectedPlan = plans.firstWhere(
            (plan) => plan.planType == SubscriptionPlan.pro,
            orElse: () => plans.first,
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Failed to load subscription information. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _processPayment() async {
    _validateForm();

    if (_cardNumberError != null ||
        _expiryError != null ||
        _cvvError != null ||
        _nameError != null) {
      return;
    }

    // Validation for test card
    final cardNumber = _cardNumberController.text.replaceAll(' ', '');
    if (cardNumber != '4567313786822209') {
      GlobalSnackBar.show(
        context: context,
        message: 'Please use the test card 4567 3137 8682 2209',
        variant: SnackBarVariant.warning,
      );
      return;
    }

    if (_selectedPlan == null) {
      GlobalSnackBar.show(
        context: context,
        message: 'Please select a subscription plan',
        variant: SnackBarVariant.warning,
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = '';
    });

    try {
      // Call subscription service to process the payment and upgrade
      final success = await _subscriptionService.upgradeToPro(
        paymentMethodId: 'pm_card_visa', // Simulated payment method ID
        isYearly: _isYearly,
      );

      if (success && mounted) {
        // Show success dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Subscription Activated'),
            content: const Text(
                'Your Pro subscription has been activated successfully! '
                'You now have unlimited tokens and access to all premium features.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );

        // Return to previous screen
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Failed to process payment. Please try again.';
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: ${e.toString()}';
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = '';
    });

    try {
      final success = await _iapService.restorePurchases();

      if (success && mounted) {
        // Refresh subscription status
        final subscription = await _subscriptionService.getCurrentSubscription(
            forceRefresh: true);

        if (mounted) {
          if (subscription.isPro) {
            // Show success message
            GlobalSnackBar.show(
              context: context,
              message: 'Pro subscription restored successfully!',
              variant: SnackBarVariant.success,
            );
            Navigator.of(context).pop(true);
          } else {
            GlobalSnackBar.show(
              context: context,
              message: 'No active subscription found to restore',
              variant: SnackBarVariant.info,
            );
          }
        }
      } else if (mounted) {
        GlobalSnackBar.show(
          context: context,
          message: 'Failed to restore purchases',
          variant: SnackBarVariant.error,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // == Validation ==
  void _validateForm() {
    if (!mounted) return;

    setState(() {
      _cardNumberError = _validateCardNumber(_cardNumberController.text);
      _expiryError = _validateExpiry(_expiryController.text);
      _cvvError = _validateCVV(_cvvController.text);
      _nameError = _validateName(_nameController.text);
    });
  }

  String? _validateCardNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Card number is required';
    }

    final cleanedValue = value.replaceAll(' ', '');
    if (cleanedValue.length != 16) {
      return 'Card number must be 16 digits';
    }

    if (cleanedValue != '4567313786822209') {
      return 'Please use the test card number';
    }

    return null;
  }

  String? _validateExpiry(String? value) {
    if (value == null || value.isEmpty) {
      return 'Expiry date is required';
    }

    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
      return 'Use format MM/YY';
    }

    return null;
  }

  String? _validateCVV(String? value) {
    if (value == null || value.isEmpty) {
      return 'CVV is required';
    }

    if (value.length < 3) {
      return 'CVV must be at least 3 digits';
    }

    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name on card is required';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade to Pro'),
      ),
      body: _isLoading
          ? InformationIndicator(
              message: 'Loading subscription plans...',
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPricingCard(),
                    const SizedBox(height: 40),

                    _buildPaymentForm(),
                    const SizedBox(height: 32),

                    // Error message
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                    // Payment button
                    LargeButton(
                      label: _isProcessing ? 'Processing...' : 'Upgrade Now',
                      onPressed: _isProcessing ? null : _processPayment,
                      variant: ButtonVariant.primary,
                      isDarkMode: isDarkMode,
                      icon: _isProcessing ? null : Icons.rocket_launch,
                    ),

                    const SizedBox(height: 16),

                    // Restore purchases
                    LargeButton(
                      label: 'Restore Previous Purchase',
                      onPressed: _isProcessing ? null : _restorePurchases,
                      variant: ButtonVariant.secondary,
                      isDarkMode: isDarkMode,
                      icon: Icons.restore,
                    ),

                    // Legal info
                    const SizedBox(height: 16),
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'By upgrading, you agree to our Terms of Service and Privacy Policy. '
                          'Subscriptions will automatically renew unless canceled at least 24 hours '
                          'before the end of the current period.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                  ),
                          textAlign: TextAlign.center,
                        )),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPricingCard() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final colors = isDarkMode ? AppColors.dark : AppColors.light;
    if (_selectedPlan == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Plan name
            Text(
              _selectedPlan!.name,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 2),

            // Plan description
            Text(
              _selectedPlan!.description,
              style: theme.textTheme.titleSmall?.copyWith(
                color: colors.muted,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Billing options toggle
            Center(
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('Yearly'),
                    icon: Icon(Icons.calendar_today),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('Monthly'),
                    icon: Icon(Icons.date_range),
                  ),
                ],
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>(
                    (Set<WidgetState> states) {
                      if (states.contains(WidgetState.selected)) {
                        return theme.colorScheme.primary;
                      }
                      return theme.colorScheme.surface;
                    },
                  ),
                  foregroundColor: WidgetStateProperty.resolveWith<Color>(
                    (Set<WidgetState> states) {
                      if (states.contains(WidgetState.selected)) {
                        return theme.colorScheme.onPrimary;
                      }
                      return theme.colorScheme.onSurface;
                    },
                  ),
                  side: WidgetStateProperty.resolveWith<BorderSide>(
                    (Set<WidgetState> states) {
                      if (states.contains(WidgetState.selected)) {
                        return BorderSide.none;
                      }
                      final colors =
                          isDarkMode ? AppColors.dark : AppColors.light;
                      return BorderSide(color: colors.border);
                    },
                  ),
                ),
                selected: {_isYearly},
                onSelectionChanged: (Set<bool> newSelection) {
                  setState(() {
                    _isYearly = newSelection.first;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),

            // Price info
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _isYearly
                      ? _selectedPlan!.formattedMonthlyPriceYearly
                      : _selectedPlan!.formattedMonthlyPrice,
                  style: theme.textTheme.headlineLarge,
                ),
                const SizedBox(width: 4),
                Text(
                  _isYearly ? '/ month' : '/ month',
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),

            const SizedBox(height: 2),

            // Yearly billing note
            if (_isYearly)
              Center(
                child: Text(
                  'Billed annually as ${_selectedPlan!.formattedAnnualPrice}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.muted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

            const SizedBox(height: 4),

            // Savings badge for yearly
            if (_isYearly && _selectedPlan!.yearlySavingsPercent > 0)
              Center(
                child: Chip(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: colors.success.withAlpha(180),
                    ),
                  ),
                  backgroundColor: colors.success.withAlpha(30),
                  label: Text(
                    'Save ${_selectedPlan!.yearlySavingsPercent.round()}%',
                    style: TextStyle(
                      color: colors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            _buildFeatures(features: _selectedPlan!.features),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatures({required List<String> features}) {
    final int halfLength = (features.length / 2).ceil();
    final firstColumn = features.sublist(0, halfLength);
    final secondColumn = features.sublist(halfLength);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Features Include:',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: firstColumn.map((feature) => _buildFeatureItem(feature)).toList(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: secondColumn.map((feature) => _buildFeatureItem(feature)).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String feature) {
    final theme = Theme.of(context);
    final colors = theme.brightness == Brightness.dark ? AppColors.dark : AppColors.light;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: colors.success,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              feature,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentForm() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    const double fieldSpacing = 24.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Details',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 20),

        // Card number
        FloatingLabelTextField(
          controller: _cardNumberController,
          label: 'Card Number',
          hintText: 'Enter your card number',
          prefixIcon: Icons.credit_card,
          keyboardType: TextInputType.number,
          errorText: _cardNumberError,
          darkMode: isDarkMode,
          onChanged: (_) => _validateForm(),
        ),
        const SizedBox(height: fieldSpacing),

        // Expiry and CVV in a row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Expiry date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FloatingLabelTextField(
                    controller: _expiryController,
                    label: 'Expiry Date',
                    hintText: 'Enter your expiry date',
                    prefixIcon: Icons.date_range,
                    keyboardType: TextInputType.datetime,
                    errorText: _expiryError,
                    darkMode: isDarkMode,
                    onChanged: (_) => _validateForm(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // CVV
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FloatingLabelTextField(
                    controller: _cvvController,
                    label: 'CVV',
                    hintText: 'Enter your CVV',
                    prefixIcon: Icons.credit_card,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    errorText: _cvvError,
                    darkMode: isDarkMode,
                    onChanged: (_) => _validateForm(),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: fieldSpacing),

        // Name on card
        FloatingLabelTextField(
          controller: _nameController,
          label: 'Name on Card',
          prefixIcon: Icons.person,
          hintText: 'Enter your name as it appears on your card',
          keyboardType: TextInputType.name,
          errorText: _nameError,
          darkMode: isDarkMode,
          onChanged: (_) => _validateForm(),
        ),
      ],
    );
  }
}
