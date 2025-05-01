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

    // Show loading spinner when ad is not yet loaded
    if (!_isAdLoaded) {
      return FutureBuilder(
        // TEMPORARY: Remove this after implementing AdWidget
        future: Future.delayed(const Duration(seconds: 5)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              width: double.infinity,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
                  width: 0.5,
                ),
              ),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            );
          } else {
            return _buildAdPlaceholder(context);
          }
        },
      );
    }

    // Show ad placeholder when ad is loaded
    return _buildAdPlaceholder(context);
  }

  Widget _buildAdPlaceholder(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
          width: 0.5,
        ),
      ),
      child: const Text(
        'Ad Banner Placeholder',
        style: TextStyle(fontStyle: FontStyle.italic),
      ),
    );
  }
}
