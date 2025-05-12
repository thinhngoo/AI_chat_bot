import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth/auth_service.dart';
import '../services/subscription_service.dart';
import '../models/usage_stats.dart';
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
  UsageStats? _usageStats;
  
  // Pricing URLs
  final String _pricingUrl = 'https://dev.jarvis.cx/pricing';
  
  // Test card information
  final String _testCardInfo = '4242 4242 4242 4242';

  @override
  void initState() {
    super.initState();
    _subscriptionService = SubscriptionService(_authService, _logger);
    _loadSubscriptionData();
  }
  
  Future<void> _loadSubscriptionData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      // Load both subscription and usage stats
      final subscription = await _subscriptionService.getCurrentSubscription(forceRefresh: true);
      final usageStats = await _subscriptionService.getUsageStats(forceRefresh: true);
      
      setState(() {
        _isPro = subscription.isPro;
        _usageStats = usageStats;
        _isLoading = false;
      });
      
      _logger.i('Subscription status: ${_isPro ? 'PRO' : 'FREE'}');
      _logger.i('Usage stats: ${_usageStats?.totalTokensUsed ?? 0} / ${_usageStats?.totalTokensLimit ?? 0}');
      
    } catch (e) {
      _logger.e('Error loading subscription data: $e');
      setState(() {
        _isPro = false;
        _isLoading = false;
        _errorMessage = 'Không thể tải thông tin tài khoản: $e';
      });
    }
  }
  
  Future<void> _handleUpgradeSubscription() async {
    try {
      _logger.i('Opening pricing page: $_pricingUrl');
      
      // Launch the pricing URL in the browser
      final Uri url = Uri.parse(_pricingUrl);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Không thể mở trang nâng cấp tài khoản';
      }
      
    } catch (e) {
      _logger.e('Error opening pricing page: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể mở trang nâng cấp: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
  
  void _copyTestCardToClipboard() {
    Clipboard.setData(ClipboardData(text: _testCardInfo));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã sao chép số thẻ test vào clipboard'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  
  Future<void> _refreshSubscription() async {
    await _loadSubscriptionData();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật thông tin tài khoản'),
          duration: Duration(seconds: 2),
        ),
      );
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refreshSubscription,
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _errorMessage, 
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshSubscription,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshSubscription,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Account status card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isPro
                            ? [Colors.teal.shade700, Colors.teal.shade900]
                            : [Colors.orange.shade300, Colors.deepOrange.shade400],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [                          BoxShadow(
                            color: Colors.black.withAlpha(25), // Changed from withOpacity(0.1) to withAlpha(25) - 0.1*255=25
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _isPro ? Icons.workspace_premium : Icons.info_outline,
                            size: 48,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tình trạng tài khoản:',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isPro ? 'PRO' : 'Miễn phí',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.token, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                _isPro 
                                  ? 'Không giới hạn' 
                                  : '${_usageStats?.totalTokensUsed ?? 0} / ${_usageStats?.totalTokensLimit ?? 10000}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (!_isPro && _usageStats != null) ...[
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: (_usageStats!.totalTokensUsed / 
                                    (_usageStats!.totalTokensLimit > 0 ? _usageStats!.totalTokensLimit : 1)),
                                backgroundColor: Colors.white.withAlpha(77), // Changed from withOpacity(0.3) to withAlpha(77) - 0.3*255=77
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _usageStats!.totalTokensUsed / (_usageStats!.totalTokensLimit > 0 ? _usageStats!.totalTokensLimit : 1) > 0.8
                                    ? Colors.red
                                    : Colors.white
                                ),
                                minHeight: 10,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Admin panel link for Pro users
                    if (_isPro)
                      Card(
                        color: isDarkMode ? Colors.grey.shade800 : Colors.blue.shade50,
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.dashboard, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Quản lý tài khoản Pro',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Bạn có thể quản lý cài đặt tài khoản và xem chi tiết việc sử dụng tại trang quản trị.',
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(                                onPressed: () async {
                                  final url = Uri.parse('https://admin.dev.jarvis.cx/pricing/overview');
                                  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                                    if (!mounted) return;
                                    // ScaffoldMessenger.of(context).showSnackBar(
                                    //   const SnackBar(content: Text('Không thể mở trang quản trị')),
                                    // );
                                  }
                                },
                                icon: const Icon(Icons.open_in_new),
                                label: const Text('Mở trang quản trị'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    if (_isPro)
                      const SizedBox(height: 24),
                    
                    // Pricing section header
                    Text(
                      _isPro ? 'Thông tin gói Pro' : 'Nâng cấp lên gói Pro',
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Pro plan features
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Colors.teal,
                          width: 2,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Gói Pro',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal,
                                  ),
                                ),
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
                            const Text(
                              '50.000 VND / tháng',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildFeatureItem('Không giới hạn số lượng token'),
                            _buildFeatureItem('Hỗ trợ tất cả các mô hình AI tiên tiến'),
                            _buildFeatureItem('Không quảng cáo'),
                            _buildFeatureItem('Ưu tiên truy cập các tính năng mới'),
                            _buildFeatureItem('Hỗ trợ ưu tiên 24/7'),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Action buttons
                    if (!_isPro) ...[
                      ElevatedButton(
                        onPressed: _handleUpgradeSubscription,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
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
                        child: const Text('Nâng cấp ngay'),
                      ),                    ] else ...[
                      ElevatedButton(
                        onPressed: () async {
                          final url = Uri.parse('https://admin.dev.jarvis.cx/pricing/overview');
                          if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                            if (!mounted) return;
                            // ScaffoldMessenger.of(context).showSnackBar(
                            //   const SnackBar(content: Text('Không thể mở trang quản trị')),
                            // );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
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
                        child: const Text('Quản lý tài khoản'),
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    if (!_isPro) ...[
                      // Test card section
                      Card(
                        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.credit_card, color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Thẻ test để nâng cấp',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _testCardInfo,
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 16,
                                        color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy),
                                    onPressed: _copyTestCardToClipboard,
                                    tooltip: 'Sao chép số thẻ',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Hãy sử dụng thông tin này trong trang thanh toán để nâng cấp tài khoản test.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Text(
                        'Thanh toán an toàn, hủy bất kỳ lúc nào',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.muted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.teal,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
