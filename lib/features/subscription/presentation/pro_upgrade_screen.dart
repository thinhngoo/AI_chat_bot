import 'dart:async';
import 'package:flutter/material.dart';
import '../services/iap_service.dart';
import '../services/subscription_service.dart';
import '../models/pricing_model.dart';
import '../models/subscription_model.dart';
import 'widgets/feature_highlights.dart';
import '../../../core/services/auth/auth_service.dart';
import 'package:logger/logger.dart';

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
  
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  
  List<PricingPlan> _plans = [];
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
    
    // Pre-fill test credit card for demo
    _cardNumberController.text = "4242 4242 4242 4242";
    _expiryController.text = "12/25";
    _cvvController.text = "123";
    _nameController.text = "Test User";
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      // Load subscription plans and current subscription
      final plans = await _subscriptionService.getAvailablePlans();
      final currentSubscription = await _subscriptionService.getCurrentSubscription();
      
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
          _errorMessage = 'Failed to load subscription information. Please try again.';
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _processPayment() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
    // Validation for test card
    final cardNumber = _cardNumberController.text.replaceAll(' ', '');
    if (cardNumber != '4242424242424242') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please use the test card 4242 4242 4242 4242')),
      );
      return;
    }
    
    if (_selectedPlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subscription plan')),
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
              'You now have unlimited tokens and access to all premium features.'
            ),
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
        final subscription = await _subscriptionService.getCurrentSubscription(forceRefresh: true);
        
        if (mounted) {
          if (subscription.isPro) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pro subscription restored successfully!')),
            );
            Navigator.of(context).pop(true);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No active subscription found to restore')),
            );
          }
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to restore purchases')),
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
  
  String? _validateCardNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Card number is required';
    }
    
    final cleanedValue = value.replaceAll(' ', '');
    if (cleanedValue.length != 16) {
      return 'Card number must be 16 digits';
    }
    
    if (cleanedValue != '4242424242424242') {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade to Pro'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Price cards
                    _buildPricingCard(),
                    const SizedBox(height: 20),
                    
                    // Payment section
                    _buildPaymentForm(),
                    const SizedBox(height: 20),
                    
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
                    ElevatedButton(
                      onPressed: _isProcessing ? null : _processPayment,
                      child: _isProcessing
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 10),
                                Text('Processing...'),
                              ],
                            )
                          : const Text('Upgrade Now'),
                    ),
                    
                    // Restore purchases
                    TextButton(
                      onPressed: _isProcessing ? null : _restorePurchases,
                      child: const Text('Restore Previous Purchase'),
                    ),
                    
                    // Legal info
                    const SizedBox(height: 8),
                    Text(
                      'By upgrading, you agree to our Terms of Service and Privacy Policy. '
                      'Subscriptions will automatically renew unless canceled at least 24 hours '
                      'before the end of the current period.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildPricingCard() {
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Plan description
            Text(
              _selectedPlan!.description,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
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
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _isYearly ? '/ month' : '/ month',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
            
            // Yearly billing note
            if (_isYearly)
              Center(
                child: Text(
                  'Billed annually as ${_selectedPlan!.formattedAnnualPrice}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              
            // Savings badge for yearly
            if (_isYearly && _selectedPlan!.yearlySavingsPercent > 0)
              Center(
                child: Chip(
                  backgroundColor: Colors.green.shade100,
                  label: Text(
                    'Save ${_selectedPlan!.yearlySavingsPercent.round()}%',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            
            const SizedBox(height: 20),
            
            // Features list
            FeatureHighlights(features: _selectedPlan!.features),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPaymentForm() {
    return Form(
      key: _formKey,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
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
              TextFormField(
                controller: _cardNumberController,
                decoration: const InputDecoration(
                  labelText: 'Card Number',
                  hintText: 'Use test card: 4242 4242 4242 4242',
                  prefixIcon: Icon(Icons.credit_card),
                ),
                keyboardType: TextInputType.number,
                validator: _validateCardNumber,
              ),
              const SizedBox(height: 16),
              
              // Expiry and CVV in a row
              Row(
                children: [
                  // Expiry date
                  Expanded(
                    child: TextFormField(
                      controller: _expiryController,
                      decoration: const InputDecoration(
                        labelText: 'Expiry Date',
                        hintText: 'MM/YY',
                      ),
                      validator: _validateExpiry,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // CVV
                  Expanded(
                    child: TextFormField(
                      controller: _cvvController,
                      decoration: const InputDecoration(
                        labelText: 'CVV',
                        hintText: '123',
                      ),
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      validator: _validateCVV,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Name on card
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name on Card',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: _validateName,
              ),
            ],
          ),
        ),
      ),
    );
  }
}