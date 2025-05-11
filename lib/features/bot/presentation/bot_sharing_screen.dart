import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

import '../../../core/constants/api_constants.dart';
import '../services/bot_sharing_service.dart';
import '../models/sharing_config.dart';
import '../utils/webhook_url_helper.dart';

class BotSharingScreen extends StatefulWidget {
  final String botId;
  final String botName;
  
  const BotSharingScreen({
    super.key,
    required this.botId,
    required this.botName,
  });

  @override
  State<BotSharingScreen> createState() => _BotSharingScreenState();
}

class _BotSharingScreenState extends State<BotSharingScreen> with SingleTickerProviderStateMixin {
  final Logger _logger = Logger();
  final BotSharingService _botSharingService = BotSharingService();
  
  bool _isLoading = true;
  String _errorMessage = '';
  late TabController _tabController;
  
  SharingConfig? _sharingConfig;
  Map<String, bool> _configVerifyingState = {};
  Map<String, bool> _configPublishingState = {};
  
  // Platform information
  final Map<String, String> _platformNames = {
    'slack': 'Slack',
    'telegram': 'Telegram',
    'messenger': 'Facebook Messenger',
  };

  final Map<String, IconData> _platformIcons = {
    'slack': Icons.chat_bubble_outline,
    'telegram': Icons.send,
    'messenger': Icons.facebook,
  };

  final Map<String, Color> _platformColors = {
    'slack': const Color(0xFF4A154B),
    'telegram': const Color(0xFF0088CC),
    'messenger': const Color(0xFF0084FF),
  };
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchSharingConfigurations();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  // Method to test API endpoints - for debugging purposes
  Future<void> _testApiEndpoints() async {
    try {
      final message = await _botSharingService.testEndpoints(widget.botId);
      
      if (!mounted) return;
      
      // Show the test results in a dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('API Endpoints Test'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Current API endpoint configuration:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CLOSE'),
            ),
          ],
        ),
      );
    } catch (e) {
      _logger.e('Error testing API endpoints: $e');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error testing API endpoints: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
    Future<void> _fetchSharingConfigurations() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      _logger.d('Starting to fetch sharing configurations for botId: ${widget.botId}');
      final config = await _botSharingService.getConfigurations(widget.botId);      _logger.d('Successfully retrieved configuration: ${config.platforms}');
      
      if (mounted) {
        setState(() {
          _sharingConfig = config;
          _isLoading = false;
        });
        
        // Show a success message with the actual API used
        final apiUrl = ApiConstants.kbCoreApiUrl;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Configuration loaded from $apiUrl'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      _logger.e('Error fetching sharing configurations: $e');
      
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _disconnectBotIntegration(String platform) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final success = await _botSharingService.disconnectBotIntegration(
        widget.botId,
        platform,
      );
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_platformNames[platform]} integration disconnected successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh configurations
        _fetchSharingConfigurations();
      } else {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to disconnect ${_platformNames[platform]} integration'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      _logger.e('Error disconnecting integration: $e');
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _verifyBotConfiguration(String platform) async {
    if (_sharingConfig == null || !_sharingConfig!.platforms.containsKey(platform)) {
      return;
    }
    
    try {
      setState(() {
        _configVerifyingState[platform] = true;
      });
      
      final config = _sharingConfig!.platforms[platform]!.details;
      Map<String, dynamic> result;
      
      switch (platform) {
        case 'telegram':
          result = await _botSharingService.verifyTelegramBotConfig(widget.botId, config);
          break;
        case 'slack':
          result = await _botSharingService.verifySlackBotConfig(widget.botId, config);
          break;
        case 'messenger':
          result = await _botSharingService.verifyMessengerBotConfig(widget.botId, config);
          break;
        default:
          throw 'Unsupported platform: $platform';
      }
      
      if (!mounted) return;
      
      setState(() {
        _configVerifyingState[platform] = false;
      });
      
      if (result['success'] == true) {
        if (result['verified'] == true) {
          // Update config to show verified status
          _fetchSharingConfigurations();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_platformNames[platform]} configuration verified successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          _showErrorDialog(
            'Verification Failed',
            result['message'] ?? 'Failed to verify configuration',
          );
        }
      } else {
        _showErrorDialog(
          'Verification Error',
          result['message'] ?? 'An error occurred during verification',
        );
      }
    } catch (e) {
      _logger.e('Error verifying configuration: $e');
      
      if (!mounted) return;
      
      setState(() {
        _configVerifyingState[platform] = false;
      });
      
      _showErrorDialog(
        'Verification Error',
        'An error occurred: $e',
      );
    }
  }
  
  Future<void> _publishBot(String platform) async {
    if (_sharingConfig == null || !_sharingConfig!.platforms.containsKey(platform)) {
      return;
    }
    
    try {
      setState(() {
        _configPublishingState[platform] = true;
      });
      
      final config = _sharingConfig!.platforms[platform]!.details;
      Map<String, dynamic> result;
      
      switch (platform) {
        case 'telegram':
          result = await _botSharingService.publishTelegramBot(widget.botId, config);
          break;
        case 'slack':
          result = await _botSharingService.publishSlackBot(widget.botId, config);
          break;
        case 'messenger':
          result = await _botSharingService.publishMessengerBot(widget.botId, config);
          break;
        default:
          throw 'Unsupported platform: $platform';
      }
      
      if (!mounted) return;
      
      setState(() {
        _configPublishingState[platform] = false;
      });
      
      if (result['success'] == true) {
        if (result['published'] == true) {
          // Update config to show published status
          _fetchSharingConfigurations();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bot published to ${_platformNames[platform]} successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          _showErrorDialog(
            'Publishing Failed',
            result['message'] ?? 'Failed to publish bot',
          );
        }
      } else {
        _showErrorDialog(
          'Publishing Error',
          result['message'] ?? 'An error occurred during publishing',
        );
      }
    } catch (e) {
      _logger.e('Error publishing bot: $e');
      
      if (!mounted) return;
      
      setState(() {
        _configPublishingState[platform] = false;
      });
      
      _showErrorDialog(
        'Publishing Error',
        'An error occurred: $e',
      );
    }
  }
  
  Future<Map<String, dynamic>?> _showConfigDialog(String platform) async {
    final TextEditingController tokenController = TextEditingController();
    final TextEditingController channelController = TextEditingController();
    final TextEditingController verificationTokenController = TextEditingController();
    final TextEditingController appSecretController = TextEditingController();
    
    // Pre-fill with existing configuration if available
    if (_sharingConfig != null && 
        _sharingConfig!.platforms.containsKey(platform) &&
        _sharingConfig!.platforms[platform]!.details.isNotEmpty) {
      final details = _sharingConfig!.platforms[platform]!.details;
      
      if (details.containsKey('token')) {
        tokenController.text = details['token'];
      }
      
      if (details.containsKey('channel')) {
        channelController.text = details['channel'];
      }
      
      if (details.containsKey('verifyToken')) {
        verificationTokenController.text = details['verifyToken'];
      }
      
      if (details.containsKey('appSecret')) {
        appSecretController.text = details['appSecret'];
      }
    }
    
    // Register controllers for disposal
    final controllers = <String, TextEditingController>{
      'token': tokenController,
      'channel': channelController,
      'verificationToken': verificationTokenController,
      'appSecret': appSecretController,
    };
    
    // Different fields for different platforms
    Widget configFields;
    switch (platform) {      case 'slack':
        configFields = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: tokenController,
              decoration: const InputDecoration(
                labelText: 'Slack Bot Token',
                hintText: 'xoxb-...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: channelController,
              decoration: const InputDecoration(
                labelText: 'Default Channel ID (optional)',
                hintText: 'C01234567',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Display the webhook URL information for Slack
            WebhookUrlHelper.buildWebhookUrlDisplay(
              context: context,
              webhookUrl: WebhookUrlHelper.generateSlackCallbackUrl(widget.botId),
              label: 'Request URL:',
              backgroundColor: Colors.purple.shade50,
              borderColor: Colors.purple.shade200,
              textColor: Colors.purple.shade800,
            ),
            const SizedBox(height: 16),
            const Text('How to set up your Slack Bot:'),
            const SizedBox(height: 8),
            const Text(
              '1. Go to https://api.slack.com/apps\n'
              '2. Create a new app or select an existing one\n'
              '3. Navigate to "Event Subscriptions"\n'
              '4. Enable events and add the Request URL shown above\n'
              '5. Subscribe to bot events: message.channels, message.groups\n'
              '6. Navigate to "OAuth & Permissions"\n'
              '7. Copy the Bot User OAuth Token that starts with "xoxb-"',
              style: TextStyle(fontSize: 12),
            ),
          ],
        );
        break;
        case 'telegram':
        configFields = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: tokenController,
              decoration: const InputDecoration(
                labelText: 'Telegram Bot Token',
                hintText: '123456789:AAHn...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Display the webhook URL information for Telegram
            WebhookUrlHelper.buildWebhookUrlDisplay(
              context: context,
              webhookUrl: WebhookUrlHelper.generateTelegramWebhookUrl(widget.botId),
              label: 'Webhook URL:',
              backgroundColor: Colors.blue.shade50,
              borderColor: Colors.blue.shade200,
              textColor: Colors.blue.shade800,
            ),
            const SizedBox(height: 16),
            const Text('How to set up your Telegram Bot:'),
            const SizedBox(height: 8),
            const Text(
              '1. Open Telegram and search for @BotFather\n'
              '2. Send the command /newbot\n'
              '3. Follow the steps to create a new bot\n'
              '4. Copy the HTTP API token provided by BotFather\n'
              '5. Set the webhook URL using the setWebhook method:\n'
              '   https://api.telegram.org/bot<YOUR_TOKEN>/setWebhook?url=<WEBHOOK_URL>',
              style: TextStyle(fontSize: 12),
            ),
          ],
        );
        break;
      
      case 'messenger':
        configFields = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: tokenController,
              decoration: const InputDecoration(
                labelText: 'Page Access Token',
                hintText: 'EAABz...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: appSecretController,
              decoration: const InputDecoration(
                labelText: 'App Secret',
                hintText: '1234abcd...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: verificationTokenController,
              decoration: const InputDecoration(
                labelText: 'Verification Token',
                hintText: 'Custom verification string (e.g. "knowledge")',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),            // Display the callback URL information for Messenger
            WebhookUrlHelper.buildWebhookUrlDisplay(
              context: context,
              webhookUrl: WebhookUrlHelper.generateMessengerCallbackUrl(widget.botId),
              label: 'Callback URL:',
              backgroundColor: Colors.blue.shade50,
              borderColor: Colors.blue.shade200,
              textColor: Colors.blue.shade800,
            ),
            const SizedBox(height: 16),
            const Text('How to set up Facebook Messenger:'),
            const SizedBox(height: 8),
            const Text(
              '1. Create a Facebook App at https://developers.facebook.com/apps\n'
              '2. Add the Messenger product to your app\n'
              '3. Configure a Facebook Page for your app\n'
              '4. Generate a Page Access Token\n'
              '5. Find your App Secret in App Settings\n'
              '6. In Webhooks setup, add the Callback URL shown above\n'
              '7. Use your custom Verification Token (e.g. "knowledge")',
              style: TextStyle(fontSize: 12),
            ),
          ],
        );
        break;
      
      default:
        configFields = const Text('Configuration not available for this platform');
    }
    
    try {
      // Show dialog and return result
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                _platformIcons[platform] ?? Icons.integration_instructions,
                color: _platformColors[platform],
              ),
              const SizedBox(width: 8),
              Text('Configure ${_platformNames[platform]}'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Please provide the necessary information to connect your bot to ${_platformNames[platform]}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                configFields,
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('CANCEL'),
            ),            ElevatedButton(
              onPressed: () {
                // Collect values from controllers
                final config = <String, dynamic>{};
                
                if (tokenController.text.isNotEmpty) {
                  config['token'] = tokenController.text;
                }
                
                if (channelController.text.isNotEmpty) {
                  config['channel'] = channelController.text;
                }
                
                if (verificationTokenController.text.isNotEmpty) {
                  config['verifyToken'] = verificationTokenController.text;
                }
                
                if (appSecretController.text.isNotEmpty) {
                  config['appSecret'] = appSecretController.text;
                }
                  // For platforms that need callback URLs, include them
                if (platform == 'messenger') {
                  config['callbackUrl'] = WebhookUrlHelper.generateMessengerCallbackUrl(widget.botId);
                } else if (platform == 'telegram') {
                  config['webhookUrl'] = WebhookUrlHelper.generateTelegramWebhookUrl(widget.botId);
                } else if (platform == 'slack') {
                  config['webhookUrl'] = WebhookUrlHelper.generateSlackCallbackUrl(widget.botId);
                }
                
                Navigator.of(context).pop(config);
              },
              child: const Text('SAVE'),
            ),
          ],
        ),
      );
      
      // Clean up controllers
      controllers.forEach((_, controller) => controller.dispose());
      
      return result;
    } finally {
      // Ensure controllers are disposed in case of exceptions
      controllers.forEach((_, controller) => controller.dispose());
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Share Bot: ${widget.botName}'),
            Text(
              'Connect to messaging platforms',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
              ),
            ),
          ],
        ),        actions: [
          // Add test button to verify API endpoints
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Test API Endpoints',
            onPressed: _testApiEndpoints, 
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _fetchSharingConfigurations,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Icon(_platformIcons['slack']!),
              text: 'Slack',
            ),
            Tab(
              icon: Icon(_platformIcons['telegram']!),
              text: 'Telegram',
            ),
            Tab(
              icon: Icon(_platformIcons['messenger']!),
              text: 'Messenger',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_errorMessage'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchSharingConfigurations,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPlatformTab('slack'),
                    _buildPlatformTab('telegram'),
                    _buildPlatformTab('messenger'),
                  ],
                ),
    );
  }
  
  Widget _buildPlatformTab(String platform) {
    final platformName = _platformNames[platform] ?? platform;
    final platformColor = _platformColors[platform] ?? Colors.grey;
    final platformIcon = _platformIcons[platform] ?? Icons.integration_instructions;
    
    final isConfigured = _sharingConfig?.platforms[platform]?.isConfigured ?? false;
    final isVerified = _sharingConfig?.platforms[platform]?.isVerified ?? false;
    final isPublished = _sharingConfig?.platforms[platform]?.isPublished ?? false;
    final usageCount = _sharingConfig?.platforms[platform]?.usageCount ?? 0;
    final embedCode = _sharingConfig?.platforms[platform]?.embedCode;
    final webhookUrl = _sharingConfig?.platforms[platform]?.webhookUrl;
    
    final isVerifying = _configVerifyingState[platform] ?? false;
    final isPublishing = _configPublishingState[platform] ?? false;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(platformIcon, color: platformColor, size: 32),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            platformName,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            isConfigured 
                              ? isPublished 
                                ? 'Active' 
                                : 'Configured but not published'
                              : 'Not configured',
                            style: TextStyle(
                              color: isPublished 
                                ? Colors.green 
                                : isConfigured ? Colors.orange : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      
                      const Spacer(),
                      
                      if (isConfigured && isPublished)
                        Chip(
                          label: Text(
                            '$usageCount interactions',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  if (!isConfigured) ...[
                    const Text(
                      'This platform is not configured yet. Add your credentials to get started.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: Text('Configure $platformName'),
                        onPressed: () async {
                          final config = await _showConfigDialog(platform);
                          if (config != null && config.isNotEmpty) {
                            // Add config to verify
                            _verifyBotConfiguration(platform);
                          }
                        },
                      ),
                    ),
                  ] else ...[
                    // Configuration status
                    _buildConfigStatusCard(
                      context,
                      platform,
                      isVerified,
                      isPublished,
                      isVerifying,
                      isPublishing,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Webhook URL if available
                    if (webhookUrl != null && webhookUrl.isNotEmpty) ...[
                      const Text(
                        'Webhook URL',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              webhookUrl,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            onPressed: () => _copyToClipboard(
                              webhookUrl,
                              'Webhook URL copied to clipboard',
                            ),
                            tooltip: 'Copy webhook URL',
                            constraints: const BoxConstraints(),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Embed code if available
                    if (embedCode != null && embedCode.isNotEmpty) ...[
                      const Text(
                        'Embed Code',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              embedCode,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: () => _copyToClipboard(
                                  embedCode,
                                  'Embed code copied to clipboard',
                                ),
                                icon: const Icon(Icons.copy, size: 16),
                                label: const Text('Copy Code'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  textStyle: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Configuration'),
                          onPressed: () async {
                            final config = await _showConfigDialog(platform);
                            if (config != null && config.isNotEmpty) {
                              // Verify updated config
                              _verifyBotConfiguration(platform);
                            }
                          },
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          label: const Text('Disconnect', style: TextStyle(color: Colors.red)),
                          onPressed: () => _disconnectBotIntegration(platform),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildConfigStatusCard(
    BuildContext context,
    String platform,
    bool isVerified,
    bool isPublished,
    bool isVerifying,
    bool isPublishing,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withAlpha(40),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Integration Status',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Verification status
            Row(
              children: [
                Icon(
                  isVerified ? Icons.check_circle : Icons.pending,
                  color: isVerified ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Configuration Verification',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                if (!isVerified)
                  ElevatedButton(
                    onPressed: isVerifying ? null : () => _verifyBotConfiguration(platform),
                    child: isVerifying
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Verify'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Publishing status
            Row(
              children: [
                Icon(
                  isPublished ? Icons.public : Icons.public_off,
                  color: isPublished ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bot Publishing',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                if (isVerified && !isPublished)
                  ElevatedButton(
                    onPressed: isPublishing ? null : () => _publishBot(platform),
                    child: isPublishing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Publish'),
                  )
                else if (isPublished)
                  const Chip(
                    label: Text('Active'),
                    backgroundColor: Colors.green,
                    labelStyle: TextStyle(color: Colors.white),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
