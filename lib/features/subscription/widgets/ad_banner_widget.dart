import 'package:flutter/material.dart';
// Commented out to fix build issues
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
  final AdService _adService = AdService();
  final SubscriptionService _subscriptionService = SubscriptionService(
    AuthService(),
    Logger(),
  );
  
  // BannerAd? _bannerAd;
  var _bannerAd;
  bool _isAdLoaded = false;
  bool _isPro = false;
  
  @override
  void initState() {
    super.initState();
    // _loadBannerAd(); // Disabled to fix build issues
    _checkSubscriptionStatus();
  }
  
  @override
  void dispose() {
    // _bannerAd?.dispose(); // Commented out to fix build issues
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
  
  void _loadBannerAd() {
    /* Commented out to fix build issues
    _bannerAd = _adService.createBannerAd(
      size: AdSize.banner,
      onAdLoaded: (Ad ad) {
        if (mounted) {
          setState(() {
            _isAdLoaded = true;
          });
        }
      },
      onAdFailedToLoad: (Ad ad, LoadAdError error) {
        ad.dispose();
        if (mounted) {
          setState(() {
            _bannerAd = null;
            _isAdLoaded = false;
          });
        }
        debugPrint('Banner ad failed to load: $error');
      },
    );
    
    _bannerAd?.load();
    */
    debugPrint('Banner ad loading disabled');
  }

  @override
  Widget build(BuildContext context) {
    // Don't show ads for Pro users
    if (_isPro) {
      return const SizedBox.shrink();
    }
    
    // Show a dummy ad placeholder instead of real ad
    return Container(
      height: 50,
      color: Colors.grey[200],
      alignment: Alignment.center,
      child: const Text(
        'Ad Banner Placeholder (Ad functionality disabled)',
        style: TextStyle(fontSize: 12),
      ),
    );
  }
}