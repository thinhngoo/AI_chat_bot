import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import '../services/bot_service.dart';

class BotPublishScreen extends StatefulWidget {
  final String botId;
  final String botName;
  
  const BotPublishScreen({
    super.key,
    required this.botId,
    required this.botName,
  });

  @override
  State<BotPublishScreen> createState() => _BotPublishScreenState();
}

class _BotPublishScreenState extends State<BotPublishScreen> {
  final Logger _logger = Logger();
  final BotService _botService = BotService();
  
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic> _publishConfig = {};
  
  final Map<String, String> _platformNames = {
    'slack': 'Slack',
    'telegram': 'Telegram',
    'messenger': 'Facebook Messenger',
    'web': 'Website Widget',
  };
  
  final Map<String, IconData> _platformIcons = {
    'slack': Icons.workspaces_outlined,
    'telegram': Icons.send,
    'messenger': Icons.facebook,
    'web': Icons.language,
  };
  
  @override
  void initState() {
    super.initState();
    _fetchPublishingConfigurations();
  }
  
  Future<void> _fetchPublishingConfigurations() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      final config = await _botService.getPublishingConfigurations(widget.botId);
      
      if (mounted) {
        setState(() {
          _publishConfig = config;
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.e('Error fetching publishing configurations: $e');
      
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _publishToPlatform(String platform) async {
    try {
      // Show platform configuration dialog
      final Map<String, dynamic>? config = await _showConfigDialog(platform);
      
      if (config == null) {
        // User canceled
        return;
      }
      
      setState(() {
        _isLoading = true;
      });
      
      // Publish to platform
      await _botService.publishBot(
        botId: widget.botId,
        platform: platform,
        config: config,
      );
      
      // Refresh configurations
      await _fetchPublishingConfigurations();
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Published to ${_platformNames[platform] ?? platform}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _logger.e('Error publishing to $platform: $e');
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _unpublishFromPlatform(String platform) async {
    try {
      // Show confirmation dialog
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Unpublish from ${_platformNames[platform] ?? platform}'),
          content: Text('Are you sure you want to unpublish "${widget.botName}" from ${_platformNames[platform] ?? platform}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Unpublish', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      
      if (confirmed != true) {
        // User canceled
        return;
      }
      
      setState(() {
        _isLoading = true;
      });
      
      // Unpublish from platform
      await _botService.unpublishBot(
        botId: widget.botId,
        platform: platform,
      );
      
      // Refresh configurations
      await _fetchPublishingConfigurations();
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unpublished from ${_platformNames[platform] ?? platform}'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      _logger.e('Error unpublishing from $platform: $e');
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<Map<String, dynamic>?> _showConfigDialog(String platform) async {
    final TextEditingController tokenController = TextEditingController();
    final TextEditingController channelController = TextEditingController();
    
    try {
      return await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Configure ${_platformNames[platform] ?? platform}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: tokenController,
                  decoration: InputDecoration(
                    labelText: '${_platformNames[platform] ?? platform} Token',
                    hintText: 'Enter your bot token',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                if (platform == 'slack') ...[
                  TextField(
                    controller: channelController,
                    decoration: const InputDecoration(
                      labelText: 'Default Channel',
                      hintText: 'e.g., #general',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const Text(
                  'For instructions on how to obtain tokens, please refer to our documentation.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final Map<String, dynamic> config = {
                  'token': tokenController.text,
                };
                
                if (platform == 'slack' && channelController.text.isNotEmpty) {
                  config['channel'] = channelController.text;
                }
                
                Navigator.of(context).pop(config);
              },
              child: const Text('Publish'),
            ),
          ],
        ),
      );
    } finally {
      tokenController.dispose();
      channelController.dispose();
    }
  }
  
  void _copyToClipboard(String platform, String value) {
    if (value.isEmpty) return;
    
    Clipboard.setData(ClipboardData(text: value)).then((_) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied ${_platformNames[platform] ?? platform} URL to clipboard'),
          backgroundColor: Colors.blue,
        ),
      );
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publish Bot'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPublishingConfigurations,
            tooltip: 'Refresh',
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
                        'Error: $_errorMessage',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchPublishingConfigurations,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Publish your bot to these platforms:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.titleLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Slack
                      _buildPlatformCard(
                        platform: 'slack',
                        isPublished: _publishConfig.containsKey('slack'),
                        configData: _publishConfig['slack'],
                      ),
                      
                      // Telegram
                      _buildPlatformCard(
                        platform: 'telegram',
                        isPublished: _publishConfig.containsKey('telegram'),
                        configData: _publishConfig['telegram'],
                      ),
                      
                      // Facebook Messenger
                      _buildPlatformCard(
                        platform: 'messenger',
                        isPublished: _publishConfig.containsKey('messenger'),
                        configData: _publishConfig['messenger'],
                      ),
                      
                      // Web Widget
                      _buildPlatformCard(
                        platform: 'web',
                        isPublished: _publishConfig.containsKey('web'),
                        configData: _publishConfig['web'],
                      ),
                      
                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 16),
                      
                      const Text(
                        'Documentation & Tips',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.help_outline),
                        title: const Text('How to publish your bot'),
                        subtitle: const Text('Step-by-step guide for all platforms'),
                        trailing: const Icon(Icons.open_in_new),
                        onTap: () {
                          // Open documentation URL
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.verified_user),
                        title: const Text('Verify your bot'),
                        subtitle: const Text('Increase visibility and trust'),
                        trailing: const Icon(Icons.open_in_new),
                        onTap: () {
                          // Open verification documentation
                        },
                      ),
                    ],
                  ),
                ),
    );
  }
  
  Widget _buildPlatformCard({
    required String platform,
    required bool isPublished,
    dynamic configData,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              _platformIcons[platform] ?? Icons.integration_instructions,
              color: theme.primaryColor,
              size: 32,
            ),
            title: Text(
              _platformNames[platform] ?? platform,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            subtitle: Text(
              isPublished ? 'Published' : 'Not published',
              style: TextStyle(
                color: isPublished ? Colors.green : Colors.grey,
              ),
            ),
            trailing: isPublished
                ? IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _unpublishFromPlatform(platform),
                    tooltip: 'Unpublish',
                  )
                : IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.green),
                    onPressed: () => _publishToPlatform(platform),
                    tooltip: 'Publish',
                  ),
          ),
          if (isPublished && configData != null) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Integration URL:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed: () => _copyToClipboard(
                          platform,
                          configData['url'] ?? '',
                        ),
                        tooltip: 'Copy to clipboard',
                      ),
                    ],
                  ),
                  Text(
                    configData['url'] ?? 'URL not available',
                    style: TextStyle(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
