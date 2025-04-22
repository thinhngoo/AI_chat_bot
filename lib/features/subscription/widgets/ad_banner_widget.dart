import 'package:flutter/material.dart';
// Temporarily disabled due to build issues
// import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';
import '../services/subscription_service.dart';
import '../../../core/services/auth/auth_service.dart';
import 'package:logger/logger.dart';

class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  final SubscriptionService _subscriptionService = SubscriptionService(
    AuthService(),
    Logger(),
  );

  AdService? _adService;
  bool _isPro = false;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _checkSubscriptionStatus();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize ad service with context
    _adService = AdService(context);
    _loadAd();
  }

  @override
  void dispose() {
    _adService?.dispose();
    super.dispose();
  }

  Future<void> _checkSubscriptionStatus() async {
    try {
      final subscription = await _subscriptionService.getCurrentSubscription();
      if (mounted) {
        setState(() {
          _isPro = subscription.isPro;
        });
      }
    } catch (e) {
      debugPrint('Error checking subscription status: $e');
      if (mounted) {
        setState(() {
          _isPro = false; // Default to free user if error
        });
      }
    }
  }
  
  Future<void> _loadAd() async {
    if (_isPro || _adService == null) return;
    
    try {
      await _adService!.loadBannerAd();
      if (mounted) {
        setState(() {
          _isAdLoaded = _adService!.isBannerAdLoaded;
        });
      }
    } catch (e) {
      debugPrint('Error loading banner ad: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't show ads for Pro users
    if (_isPro) {
      return const SizedBox.shrink();
    }
    
    // Instead of using AdWidget which is unavailable, show a placeholder
    return Container(
      width: double.infinity,
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 40),
        border: Border.all(color: Colors.grey.withValues(alpha: 100), width: 0.5),
      ),
      child: const Text(
        'Ad Banner Placeholder',
        style: TextStyle(fontStyle: FontStyle.italic),
      ),
    );
  }
}