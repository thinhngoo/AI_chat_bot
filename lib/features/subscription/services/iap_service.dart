import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:flutter/foundation.dart';
import 'api_constants.dart';

class IAPService {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  List<ProductDetails> _products = [];
  
  // Check if store is available
  Future<bool> isAvailable() async {
    return await _inAppPurchase.isAvailable();
  }
  
  // Initialize IAP
  Future<void> initializeIAP() async {
    // Listen to purchase updates
    final purchaseUpdated = _inAppPurchase.purchaseStream;
    
    // Set up stream listener
    purchaseUpdated.listen(
      (purchaseDetailsList) {
        _listenToPurchaseUpdated(purchaseDetailsList);
      },
      onDone: () {
        debugPrint('Purchase stream closed');
      },
      onError: (error) {
        debugPrint('Error in purchase stream: $error');
      },
    );
    
    // Load products
    await _loadProducts();
  }
  
  // Load available products
  Future<List<ProductDetails>> _loadProducts() async {
    try {
      final bool isStoreAvailable = await _inAppPurchase.isAvailable();
      
      if (!isStoreAvailable) {
        debugPrint('Store is not available');
        return [];
      }
      
      // Set the subscription IDs to query
      final Set<String> ids = <String>{
        ApiConstants.monthlyProSubscriptionId,
        ApiConstants.yearlyProSubscriptionId,
      };
      
      final ProductDetailsResponse response = 
          await _inAppPurchase.queryProductDetails(ids);
      
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('Some products were not found: ${response.notFoundIDs}');
      }
      
      _products = response.productDetails;
      debugPrint('Found ${_products.length} products');
      
      return _products;
    } catch (e) {
      debugPrint('Error loading IAP products: $e');
      return [];
    }
  }
  
  // Get available products
  Future<List<ProductDetails>> getProducts() async {
    if (_products.isEmpty) {
      return await _loadProducts();
    }
    return _products;
  }
  
  // Make a purchase of monthly Pro subscription
  Future<bool> purchaseMonthlyPro() async {
    try {
      final productDetails = _findProductById(ApiConstants.monthlyProSubscriptionId);
      if (productDetails == null) {
        debugPrint('Monthly Pro product not found');
        return false;
      }
      
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
      );
      
      return await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('Error during purchase: $e');
      return false;
    }
  }
  
  // Make a purchase of yearly Pro subscription
  Future<bool> purchaseAnnualPro() async {
    try {
      final productDetails = _findProductById(ApiConstants.yearlyProSubscriptionId);
      if (productDetails == null) {
        debugPrint('Yearly Pro product not found');
        return false;
      }
      
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
      );
      
      return await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('Error during purchase: $e');
      return false;
    }
  }
  
  // Restore purchases
  Future<bool> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
      return true;
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      return false;
    }
  }
  
  // Find a product by ID
  ProductDetails? _findProductById(String productId) {
    try {
      return _products.firstWhere((product) => product.id == productId);
    } catch (e) {
      return null;
    }
  }
  
  // Listen to purchase updates
  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          debugPrint('Purchase pending: ${purchaseDetails.productID}');
          break;
        
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          debugPrint('Purchase ${purchaseDetails.status == PurchaseStatus.purchased ? 'completed' : 'restored'}: ${purchaseDetails.productID}');
          
          // Verify purchase here if needed
          _handlePurchaseComplete(purchaseDetails);
          break;
        
        case PurchaseStatus.error:
          debugPrint('Purchase error: ${purchaseDetails.error!.message}');
          break;
        
        case PurchaseStatus.canceled:
          debugPrint('Purchase canceled');
          break;
      }
      
      // Complete purchase if not pending
      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }
  
  // Handle completed purchase
  void _handlePurchaseComplete(PurchaseDetails purchaseDetails) {
    // Use your API to update the subscription status
    // Example:
    // _subscriptionService.activateSubscription(purchaseDetails.productID);
    
    debugPrint('Purchase completed successfully: ${purchaseDetails.productID}');
  }
}