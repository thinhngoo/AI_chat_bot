import 'package:flutter/material.dart';
import '../models/subscription_model.dart';
import '../services/subscription_service.dart';
import 'pro_upgrade_screen.dart';
import 'subscription_info_screen.dart';
import '../../../core/services/auth/auth_service.dart';
import 'package:logger/logger.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService(
    AuthService(),
    Logger(),
  );
  
  bool _isLoading = true;
  Subscription? _subscription;
  
  @override
  void initState() {
    super.initState();
    _loadSubscriptionStatus();
  }
  
  Future<void> _loadSubscriptionStatus() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final subscription = await _subscriptionService.getCurrentSubscription();
      
      setState(() {
        _subscription = subscription;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load subscription information: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }
  
  Widget _buildContent() {
    if (_subscription?.isPro == true) {
      // User has an active Pro subscription - show subscription info
      return _buildSubscriptionInfo();
    } else {
      // User doesn't have Pro - show upgrade options
      return _buildUpgradePromo();
    }
  }
  
  Widget _buildSubscriptionInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.green.shade50,
          child: Column(
            children: [
              const Icon(
                Icons.verified,
                color: Colors.green,
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                'Pro Subscription Active',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Valid until: ${_subscription?.endDate != null ? _formatDate(_subscription!.endDate!) : 'Ongoing'}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubscriptionInfoScreen(),
                ),
              ).then((_) => _loadSubscriptionStatus());
            },
            child: const Text('Manage Subscription'),
          ),
        ),
      ],
    );
  }
  
  Widget _buildUpgradePromo() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Unlock Premium Features',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Feature highlights
          _buildFeatureItem(
            Icons.speed,
            'Unlimited AI Responses',
            'No daily limits on your conversations',
          ),
          _buildFeatureItem(
            Icons.auto_awesome,
            'Advanced AI Models',
            'Access to more capable AI models',
          ),
          _buildFeatureItem(
            Icons.format_paint,
            'Custom Chat Themes',
            'Personalize your chat experience',
          ),
          _buildFeatureItem(
            Icons.privacy_tip,
            'Priority Support',
            'Get help when you need it',
          ),
          
          const SizedBox(height: 32),
          
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProUpgradeScreen(),
                ),
              ).then((_) => _loadSubscriptionStatus());
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Upgrade to Pro',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}