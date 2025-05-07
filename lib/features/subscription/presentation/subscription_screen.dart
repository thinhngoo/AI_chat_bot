import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth/auth_service.dart';
import '../services/subscription_service.dart';
import 'package:logger/logger.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final Logger _logger = Logger();
  final AuthService _authService = AuthService();
  late final SubscriptionService _subscriptionService;
  
  bool _isLoading = true;
  bool _isPro = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _subscriptionService = SubscriptionService(_authService, _logger);
    _checkSubscriptionStatus();
  }
  
  Future<void> _checkSubscriptionStatus() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      final subscription = await _subscriptionService.getCurrentSubscription();
      
      setState(() {
        _isPro = subscription.isPro;
        _isLoading = false;
      });
    } catch (e) {
      _logger.e('Error checking subscription status: $e');
      setState(() {
        _isPro = false;
        _isLoading = false;
        _errorMessage = 'Failed to load subscription information: $e';
      });
    }
  }
  
  Future<void> _handleUpgradeSubscription() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // This is where you'd integrate with your actual payment provider
      // For now, we'll just show a success message
      
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      _logger.i('User upgraded subscription - this is just a placeholder');
      
      setState(() {
        _isPro = true;
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription upgraded successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
      
    } catch (e) {
      _logger.e('Error upgrading subscription: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to upgrade subscription: $e';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upgrade subscription: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final colors = isDarkMode ? AppColors.dark : AppColors.light;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nâng cấp tài khoản'),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage, style: TextStyle(color: Colors.red)))
          : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.info_outline, size: 48, color: Colors.blue),
                      const SizedBox(height: 16),
                      Text(
                        'Tình trạng tài khoản hiện tại:',
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isPro ? 'Premium' : 'Miễn phí',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: _isPro ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (!_isPro) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Bạn đã hết số lượng token để sử dụng bot.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.orange,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                Text(
                  'Gói Premium',
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                _buildPlanCard(
                  theme: theme,
                  isDarkMode: isDarkMode,
                  title: 'Standard',
                  price: '50.000 VND / tháng',
                  features: [
                    'Không giới hạn số lượng chat',
                    'Hỗ trợ các mô hình AI tiên tiến',
                    'Không quảng cáo',
                  ],
                  isSelected: true,
                ),
                
                const SizedBox(height: 16),
                
                _buildPlanCard(
                  theme: theme,
                  isDarkMode: isDarkMode,
                  title: 'Premium',
                  price: '120.000 VND / 3 tháng',
                  features: [
                    'Tất cả tính năng của gói Standard',
                    'Tiết kiệm 20%',
                    'Ưu tiên truy cập các tính năng mới',
                  ],
                  isSelected: false,
                ),
                
                const SizedBox(height: 16),
                
                _buildPlanCard(
                  theme: theme,
                  isDarkMode: isDarkMode,
                  title: 'Ultimate',
                  price: '450.000 VND / năm',
                  features: [
                    'Tất cả tính năng của gói Premium',
                    'Tiết kiệm 25%',
                    'Hỗ trợ ưu tiên 24/7',
                  ],
                  isSelected: false,
                ),
                
                const SizedBox(height: 32),
                
                ElevatedButton(
                  onPressed: _isPro ? null : _handleUpgradeSubscription,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isPro 
                    ? const Text('Bạn đã nâng cấp tài khoản')
                    : const Text('Nâng cấp ngay'),
                ),
                
                const SizedBox(height: 16),
                
                if (!_isPro)
                  Text(
                    'Thanh toán an toàn, hủy bất kỳ lúc nào',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.muted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
    );
  }
  
  Widget _buildPlanCard({
    required ThemeData theme,
    required bool isDarkMode,
    required String title,
    required String price,
    required List<String> features,
    required bool isSelected,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected 
          ? (isDarkMode ? Colors.teal.shade900.withOpacity(0.3) : Colors.teal.shade50)
          : (isDarkMode ? Colors.grey.shade900 : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected 
            ? Colors.teal 
            : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.teal : null,
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Khuyên dùng',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            price,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle,
                  color: isSelected ? Colors.teal : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(feature),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
