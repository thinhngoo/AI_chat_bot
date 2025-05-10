import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/bot_integration_service.dart';
import '../services/bot_analytics_service.dart';
import '../services/bot_webhook_service.dart';
import '../models/bot_configuration.dart';

class BotIntegrationScreen extends StatefulWidget {
  final String botId;
  final String botName;
  
  const BotIntegrationScreen({
    super.key,
    required this.botId,
    required this.botName,
  });

  @override
  State<BotIntegrationScreen> createState() => _BotIntegrationScreenState();
}

class _BotIntegrationScreenState extends State<BotIntegrationScreen> with SingleTickerProviderStateMixin {
  final Logger _logger = Logger();
  final BotIntegrationService _botIntegrationService = BotIntegrationService();
  final BotAnalyticsService _analyticsService = BotAnalyticsService();
  final BotWebhookService _webhookService = BotWebhookService();
  
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic> _configurations = {};
  Map<String, PlatformConfigSettings> _platformSettings = {};
  Map<String, int> _usageStats = {};
  bool _loadingStats = false;
  // Track webhook URLs by platform
  Map<String, String?> _webhookUrls = {
    'slack': null,
    'telegram': null,
    'messenger': null,
  };
  
  late TabController _tabController;
  final List<String> _availablePlatforms = ['slack', 'telegram', 'messenger'];
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _platformSettings = _botIntegrationService.getPlatformConfigSettings();
    _fetchConfigurations();
    _fetchUsageStats();
    _fetchWebhookUrls();
  }
  
  Future<void> _fetchWebhookUrls() async {
    try {
      for (final platform in _availablePlatforms) {
        final webhookUrl = await _webhookService.getWebhookUrl(widget.botId, platform);
        if (mounted) {
          setState(() {
            _webhookUrls[platform] = webhookUrl;
          });
        }
      }
    } catch (e) {
      _logger.e('Error fetching webhook URLs: $e');
    }
  }
  
  Future<void> _fetchUsageStats() async {
    try {
      setState(() {
        _loadingStats = true;
      });
      
      final stats = await _analyticsService.getPlatformDistribution(widget.botId);
      
      if (!mounted) return;
      
      setState(() {
        _usageStats = stats;
        _loadingStats = false;
      });
    } catch (e) {
      _logger.e('Error fetching usage stats: $e');
      
      if (!mounted) return;
      
      setState(() {
        _loadingStats = false;
      });
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _fetchConfigurations() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      final configs = await _botIntegrationService.getConfigurations(widget.botId);
      
      if (!mounted) return;
      
      setState(() {
        _configurations = configs;
        _isLoading = false;
      });
    } catch (e) {
      _logger.e('Error fetching configurations: $e');
      
      if (!mounted) return;
      
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
    Future<void> _testConnection(String platform) async {
    if (!_configurations.containsKey(platform) || 
        !_configurations[platform]['configured']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please configure ${_platformSettings[platform]?.displayName ?? platform} before testing connection'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    try {
      setState(() {
        _isLoading = true;
      });
      
      final result = await _botIntegrationService.testConnection(
        widget.botId,
        platform,
      );
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      if (result['success']) {
        // If we have a webhook, validate it too
        if (_webhookUrls[platform] != null) {
          _validateWebhook(platform);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connection successful to ${_platformSettings[platform]?.displayName ?? platform}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection failed to ${_platformSettings[platform]?.displayName ?? platform}: ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      _logger.e('Error testing connection to $platform: $e');
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error testing connection: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _updateConfiguration(String platform, Map<String, dynamic> config) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      await _botIntegrationService.updateConfiguration(
        widget.botId,
        platform,
        config,
      );
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_platformSettings[platform]?.displayName ?? platform} configuration updated'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Refresh configurations
      await _fetchConfigurations();
    } catch (e) {
      _logger.e('Error updating configuration for $platform: $e');
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating configuration: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<Map<String, dynamic>?> _showConfigurationDialog(String platform) async {
    if (!_platformSettings.containsKey(platform)) {
      _logger.w('Platform settings not found for $platform');
      return null;
    }
    
    final settings = _platformSettings[platform]!;
    final existingConfig = _configurations[platform] ?? {};
    
    Map<String, TextEditingController> controllers = {};
    
    // Create controllers for each field
    for (final field in settings.requiredFields) {
      controllers[field.name] = TextEditingController(
        text: existingConfig[field.name] ?? '',
      );
    }
    
    try {
      final result = await showDialog<Map<String, dynamic>?>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                _getIconData(settings.icon),
                color: Color(settings.color),
              ),
              const SizedBox(width: 8),
              Text('Configure ${settings.displayName}'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  settings.description,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...settings.requiredFields.map((field) {
                  final controller = controllers[field.name]!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: field.label,
                          hintText: field.hint,
                          border: const OutlineInputBorder(),
                          helperText: field.isRequired ? 'Required' : 'Optional',
                        ),
                        obscureText: field.isMasked,
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                }).toList(),
                const SizedBox(height: 8),
                ExpansionTile(
                  title: const Text('Setup Instructions'),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        settings.setupInstructions,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                final config = <String, dynamic>{};
                
                for (final field in settings.requiredFields) {
                  final value = controllers[field.name]!.text;
                  
                  // Check for required fields
                  if (field.isRequired && value.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${field.label} is required'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  
                  if (value.isNotEmpty) {
                    config[field.name] = value;
                  }
                }
                
                Navigator.of(context).pop({
                  ...existingConfig,
                  ...config,
                  'configured': true,
                });
              },
              child: const Text('SAVE'),
            ),
          ],
        ),
      );
      
      // Dispose controllers
      for (final controller in controllers.values) {
        controller.dispose();
      }
      
      return result;
    } finally {
      // Ensure controllers are disposed in case of exceptions
      for (final controller in controllers.values) {
        controller.dispose();
      }
    }
  }
  
  Future<void> _showWebhookDialog(String platform) async {
    final TextEditingController webhookUrlController = TextEditingController(
      text: _webhookUrls[platform] ?? '',
    );
    TextEditingController? verificationTokenController;
    
    // Only Messenger requires a verification token
    if (platform == 'messenger') {
      verificationTokenController = TextEditingController();
      
      // Try to get the existing token from configurations
      try {
        final messengerConfig = _configurations[platform];
        if (messengerConfig != null && messengerConfig['config'] != null) {
          final config = messengerConfig['config'];
          if (config.containsKey('verifyToken')) {
            verificationTokenController.text = config['verifyToken'];
          }
        }
      } catch (e) {
        _logger.w('Error getting verification token: $e');
      }
    }
    
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${_platformSettings[platform]?.displayName} Webhook Setup'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter the webhook URL where the platform will send incoming messages:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: webhookUrlController,
                  decoration: InputDecoration(
                    labelText: 'Webhook URL',
                    hintText: 'https://your-server.com/webhook/${platform.toLowerCase()}',
                    border: const OutlineInputBorder(),
                  ),
                ),
                if (platform == 'messenger') ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Enter the verification token for webhook verification:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: verificationTokenController,
                    decoration: const InputDecoration(
                      labelText: 'Verification Token',
                      hintText: 'Custom verification token',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                const Text(
                  'Note: You need to have a server that can receive webhook events from the platform.',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final webhookUrl = webhookUrlController.text.trim();
                if (webhookUrl.isEmpty) {
                  return;
                }
                
                final result = <String, String>{
                  'webhookUrl': webhookUrl,
                };
                
                if (platform == 'messenger' && 
                    verificationTokenController != null && 
                    verificationTokenController.text.isNotEmpty) {
                  result['verificationToken'] = verificationTokenController.text.trim();
                }
                
                Navigator.of(context).pop(result);
              },
              child: const Text('Save'),
            ),
            if (_webhookUrls[platform] != null) ...[
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop({'delete': 'true'}),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Remove Webhook'),
              ),
            ],
          ],
        );
      },
    );
    
    if (result != null) {
      if (result.containsKey('delete')) {
        _deleteWebhook(platform);
      } else {
        _registerWebhook(
          platform,
          result['webhookUrl']!,
          verificationToken: result['verificationToken'],
        );
      }
    }
  }
  
  Future<void> _registerWebhook(
    String platform,
    String webhookUrl, {
    String? verificationToken,
  }) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final response = await _webhookService.registerWebhook(
        widget.botId,
        platform,
        webhookUrl,
        verificationToken: verificationToken,
      );
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        if (response['success'] == true) {
          _webhookUrls[platform] = webhookUrl;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Webhook registered successfully')),
          );
        } else {          _showErrorDialog(
            'Webhook Registration Failed',
            'Could not register webhook for ${_platformSettings[platform]?.displayName ?? platform}:',
            response['error']
          );
        }
      });
      
      // Refresh configuration after webhook update
      _fetchConfigurations();
    } catch (e) {
      _logger.e('Error registering webhook: $e');
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error registering webhook: $e')),
      );
    }
  }
  
  Future<void> _deleteWebhook(String platform) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final success = await _webhookService.deleteWebhook(
        widget.botId,
        platform,
      );
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        if (success) {
          _webhookUrls[platform] = null;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Webhook removed successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to remove webhook')),
          );
        }
      });
      
      // Refresh configuration after webhook deletion
      _fetchConfigurations();
    } catch (e) {
      _logger.e('Error deleting webhook: $e');
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting webhook: $e')),
      );
    }
  }
  
  Future<void> _validateWebhook(String platform) async {
    if (_webhookUrls[platform] == null) return;
    
    try {
      setState(() {
        _isLoading = true;
      });
      
      final response = await _webhookService.validateWebhook(
        widget.botId,
        platform,
        _webhookUrls[platform]!,
      );
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      if (response['success'] == true) {
        final bool isValid = response['valid'] == true;
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isValid 
                  ? 'Connection and webhook tests successful' 
                  : 'Connection successful but webhook validation failed'
              ),
              backgroundColor: isValid ? Colors.green : Colors.orange,
              action: isValid ? null : SnackBarAction(
                label: 'DETAILS',
                onPressed: () {
                  _showWebhookErrorDetails(response['details'] ?? 'No details available');
                },
              ),
            ),
          );
        }
      } else {        if (mounted) {
          _showErrorDialog(
            'Webhook Test Failed',
            'The connection to ${_platformSettings[platform]?.displayName ?? platform} was successful, but the webhook test failed.',
            response['error'] ?? 'Unknown error'
          );
        }
      }
    } catch (e) {
      _logger.e('Error validating webhook: $e');
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
    }
  }
    void _showWebhookErrorDetails(String details) {
    _showErrorDialog(
      'Webhook Validation Details',
      'The webhook validation encountered issues:',
      details
    );
  }
  
  void _showErrorDialog(String title, String message, [String? details]) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              if (details != null) ...[
                const SizedBox(height: 16),
                const Text('Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(26),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    details,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'chat_bubble_outline':
        return Icons.chat_bubble_outline;
      case 'send':
        return Icons.send;
      case 'facebook':
        return Icons.facebook;
      case 'public':
        return Icons.public;
      case 'chat':
        return Icons.chat;
      default:
        return Icons.integration_instructions;
    }
  }
  
  String _formatTimeAgo(DateTime dateTime) {
    final duration = DateTime.now().difference(dateTime);
    
    if (duration.inSeconds < 60) {
      return 'Just now';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes} ${duration.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (duration.inHours < 24) {
      return '${duration.inHours} ${duration.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (duration.inDays < 30) {
      return '${duration.inDays} ${duration.inDays == 1 ? 'day' : 'days'} ago';
    } else {
      return '${(duration.inDays / 30).floor()} ${(duration.inDays / 30).floor() == 1 ? 'month' : 'months'} ago';
    }
  }
  
  Widget _buildPlatformSetup(String platform) {
    if (!_platformSettings.containsKey(platform)) {
      return Center(
        child: Text('Platform $platform settings not found'),
      );
    }
    
    final settings = _platformSettings[platform]!;
    final existingConfig = _configurations[platform] ?? {};
    final bool isConfigured = existingConfig['configured'] == true;
    final bool isConnected = existingConfig['connected'] == true;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getIconData(settings.icon),
                        color: Color(settings.color),
                        size: 36,
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            settings.displayName,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isConnected
                                ? Colors.green.withAlpha(50)
                                : isConfigured
                                  ? Colors.orange.withAlpha(50)
                                  : Colors.grey.withAlpha(50),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              isConnected
                                ? 'Connected'
                                : isConfigured
                                  ? 'Configured'
                                  : 'Not Configured',
                              style: TextStyle(
                                color: isConnected
                                  ? Colors.green
                                  : isConfigured
                                    ? Colors.orange
                                    : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    settings.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (settings.documentationUrl.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final url = Uri.parse(settings.documentationUrl);
                        try {
                          await launchUrl(url);
                        } catch (e) {
                          _logger.e('Error launching URL: $e');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Could not open documentation: $e'),
                              ),
                            );
                          }
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.integration_instructions,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Documentation',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 8,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.settings),
                        label: Text(isConfigured ? 'Edit Configuration' : 'Configure'),
                        onPressed: () async {
                          final config = await _showConfigurationDialog(platform);
                          if (config != null) {
                            await _updateConfiguration(platform, config);
                          }
                        },
                      ),
                      if (isConfigured) ...[
                        OutlinedButton.icon(
                          icon: const Icon(Icons.sync),
                          label: const Text('Test Connection'),
                          onPressed: () => _testConnection(platform),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.webhook),
                          label: Text(_webhookUrls[platform] != null ? 'Edit Webhook' : 'Setup Webhook'),
                          onPressed: () => _showWebhookDialog(platform),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Validate Webhook'),
                          onPressed: () => _validateWebhook(platform),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isConfigured) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Integration Details',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (_usageStats.containsKey(platform))
                  Chip(
                    label: Text(
                      'Usage: ${_usageStats[platform]} interactions',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (existingConfig.containsKey('details'))
                      Text(existingConfig['details'].toString()),                    if (!existingConfig.containsKey('details'))
                      Text('No detailed information available'),
                    if (_webhookUrls[platform] != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text(
                            'Webhook URL: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Expanded(
                            child: Text(
                              _webhookUrls[platform]!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 16),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _webhookUrls[platform]!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Webhook URL copied to clipboard')),
                              );
                            },
                            tooltip: 'Copy to clipboard',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ],
                    if (_usageStats.containsKey(platform) && _usageStats[platform]! > 0) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Analytics',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Last interaction: ${_formatTimeAgo(DateTime.now().subtract(const Duration(minutes: 30)))}'),
                      Text('Average response time: 1.2s'),
                    ],
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          ExpansionTile(
            title: const Text('Setup Instructions'),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(settings.setupInstructions),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bot Integrations: ${widget.botName}'),
            Text(
              'Manage platform connections',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _fetchConfigurations,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Icon(_getIconData(_platformSettings['slack']?.icon ?? 'chat_bubble_outline')),
              text: 'Slack',
            ),
            Tab(
              icon: Icon(_getIconData(_platformSettings['telegram']?.icon ?? 'send')),
              text: 'Telegram',
            ),
            Tab(
              icon: Icon(_getIconData(_platformSettings['messenger']?.icon ?? 'facebook')),
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
                  Text(
                    'Error: $_errorMessage',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchConfigurations,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: _availablePlatforms.map((platform) => 
                SingleChildScrollView(
                  child: _buildPlatformSetup(platform),
                )
              ).toList(),
            ),
    );
  }
}
