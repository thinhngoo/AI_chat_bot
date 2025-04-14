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
  bool _isBatchProcessing = false;
  
  final Map<String, String> _platformNames = {
    'slack': 'Slack',
    'telegram': 'Telegram',
    'messenger': 'Facebook Messenger',
    'discord': 'Discord',
    'web': 'Website Widget',
    'whatsapp': 'WhatsApp',
  };
  
  final Map<String, IconData> _platformIcons = {
    'slack': Icons.chat_bubble_outline,
    'telegram': Icons.send,
    'messenger': Icons.facebook,
    'discord': Icons.headset_mic,
    'web': Icons.public,
    'whatsapp': Icons.message,
  };

  final Map<String, Color> _platformColors = {
    'slack': const Color(0xFF4A154B),
    'telegram': const Color(0xFF0088CC),
    'messenger': const Color(0xFF0084FF),
    'discord': const Color(0xFF5865F2),
    'web': const Color(0xFF424242),
    'whatsapp': const Color(0xFF25D366),
  };
  
  // Selected platforms for batch operations
  final Set<String> _selectedPlatforms = {};
  
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
      
      final configs = await _botService.getPublishingConfigurations(widget.botId);
      
      if (!mounted) return;
      
      setState(() {
        _publishConfig = configs;
        _isLoading = false;
      });
    } catch (e) {
      _logger.e('Error fetching publishing configurations: $e');
      
      if (!mounted) return;
      
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
  
  Future<void> _publishToPlatform(String platform) async {
    try {
      setState(() {
        if (!_isBatchProcessing) {
          _isLoading = true;
        }
      });
      
      // Get configuration for the platform, may be empty for first-time publish
      final platformConfig = _publishConfig[platform] ?? {};
      
      // If we need additional configuration, show dialog to get it
      Map<String, dynamic>? additionalConfig;
      if (!_isBatchProcessing && 
          (!platformConfig.containsKey('configured') || 
           platformConfig['configured'] != true)) {
        // Use await to pause execution until dialog is closed
        additionalConfig = await _showConfigDialog(platform);
        
        // If user canceled, abort publish
        if (additionalConfig == null) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }
      
      // Publish to platform with configs
      final result = await _botService.publishBot(
        botId: widget.botId,
        platform: platform,
        config: additionalConfig ?? {},
      );
      
      if (!mounted) return;
      
      // Update config with result
      setState(() {
        if (_publishConfig.containsKey(platform)) {
          _publishConfig[platform]!.addAll(result);
        } else {
          _publishConfig[platform] = result;
        }
        
        if (!_isBatchProcessing) {
          _isLoading = false;
        }
      });
      
      if (!_isBatchProcessing) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bot published to ${_platformNames[platform] ?? platform}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _logger.e('Error publishing to $platform: $e');
      
      if (!mounted) return;
      
      if (!_isBatchProcessing) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to publish to ${_platformNames[platform] ?? platform}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _unpublishFromPlatform(String platform) async {
    try {
      setState(() {
        if (!_isBatchProcessing) {
          _isLoading = true;
        }
      });
      
      await _botService.unpublishBot(
        botId: widget.botId,
        platform: platform,
      );
      
      if (!mounted) return;
      
      // Update config
      setState(() {
        if (_publishConfig.containsKey(platform)) {
          _publishConfig[platform]!['published'] = false;
        }
        
        if (!_isBatchProcessing) {
          _isLoading = false;
        }
      });
      
      if (!_isBatchProcessing) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bot unpublished from ${_platformNames[platform] ?? platform}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      _logger.e('Error unpublishing from $platform: $e');
      
      if (!mounted) return;
      
      if (!_isBatchProcessing) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to unpublish from ${_platformNames[platform] ?? platform}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<Map<String, dynamic>?> _showConfigDialog(String platform) async {
    final platformName = _platformNames[platform] ?? platform;
    
    // Define field controllers for different platforms
    final TextEditingController tokenController = TextEditingController();
    final TextEditingController channelController = TextEditingController();
    final TextEditingController apiKeyController = TextEditingController();
    
    // Different fields for different platforms
    Widget configFields;
    switch (platform) {
      case 'slack':
        configFields = Column(
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
          ],
        );
        break;
      
      case 'telegram':
        configFields = TextField(
          controller: tokenController,
          decoration: const InputDecoration(
            labelText: 'Telegram Bot Token',
            hintText: '123456789:AAHn...',
            border: OutlineInputBorder(),
          ),
        );
        break;
      
      case 'messenger':
        configFields = Column(
          children: [
            TextField(
              controller: tokenController,
              decoration: const InputDecoration(
                labelText: 'Page Access Token',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: apiKeyController,
              decoration: const InputDecoration(
                labelText: 'App Secret',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        );
        break;
      
      case 'web':
        configFields = const Column(
          children: [
            Text(
              'Web integration không yêu cầu cấu hình. Nhấn Xác nhận để tiếp tục.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 16),
            Text(
              'Sau khi xuất bản, bạn sẽ nhận được mã nhúng (embed code) để thêm vào website của bạn.',
            ),
          ],
        );
        break;
      
      default:
        configFields = const Text(
          'Integration này đang trong quá trình phát triển và sẽ sớm được hỗ trợ.',
        );
    }
    
    try {
      // Return result from dialog
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
              Text('Configure $platformName Integration'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Please provide the necessary information to publish your bot to $platformName',
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
            ),
            ElevatedButton(
              onPressed: () {
                // Collect values from controllers
                final config = <String, dynamic>{
                  'configured': true,
                };
                
                if (tokenController.text.isNotEmpty) {
                  config['token'] = tokenController.text;
                }
                
                if (channelController.text.isNotEmpty) {
                  config['channel'] = channelController.text;
                }
                
                if (apiKeyController.text.isNotEmpty) {
                  config['api_key'] = apiKeyController.text;
                }
                
                Navigator.of(context).pop(config);
              },
              child: const Text('CONFIRM'),
            ),
          ],
        ),
      );
      
      // Dispose controllers
      tokenController.dispose();
      channelController.dispose();
      apiKeyController.dispose();
      
      return result;
    } finally {
      // Ensure controllers are disposed in case of exceptions
      tokenController.dispose();
      channelController.dispose();
      apiKeyController.dispose();
    }
  }

  // Copy integration code to clipboard
  void _copyIntegrationCode(String platform) {
    if (!_publishConfig.containsKey(platform) || 
        !_publishConfig[platform].containsKey('embed_code')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không có mã nhúng cho nền tảng này'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final embedCode = _publishConfig[platform]['embed_code'];
    Clipboard.setData(ClipboardData(text: embedCode));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép mã nhúng vào clipboard'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Perform batch operations on selected platforms
  Future<void> _batchPublish() async {
    if (_selectedPlatforms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất một nền tảng'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    try {
      setState(() {
        _isBatchProcessing = true;
        _isLoading = true;
      });
      
      // Process each platform sequentially
      for (final platform in _selectedPlatforms) {
        await _publishToPlatform(platform);
      }
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xuất bản bot trên ${_selectedPlatforms.length} nền tảng'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _logger.e('Error in batch publishing: $e');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi xuất bản hàng loạt: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBatchProcessing = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _batchUnpublish() async {
    if (_selectedPlatforms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất một nền tảng'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Confirm before unpublishing
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hủy xuất bản'),
        content: Text(
          'Bạn có chắc chắn muốn hủy xuất bản bot trên ${_selectedPlatforms.length} nền tảng đã chọn?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('HỦY'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('XÁC NHẬN'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    try {
      setState(() {
        _isBatchProcessing = true;
        _isLoading = true;
      });
      
      // Process each platform sequentially
      for (final platform in _selectedPlatforms) {
        await _unpublishFromPlatform(platform);
      }
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã hủy xuất bản bot trên ${_selectedPlatforms.length} nền tảng'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      _logger.e('Error in batch unpublishing: $e');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi hủy xuất bản hàng loạt: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBatchProcessing = false;
          _isLoading = false;
          _selectedPlatforms.clear();
        });
      }
    }
  }

  // Check connectivity to platform
  Future<void> _testConnection(String platform) async {
    if (!_publishConfig.containsKey(platform) || 
        !_publishConfig[platform].containsKey('published') ||
        _publishConfig[platform]['published'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bot chưa được xuất bản trên ${_platformNames[platform] ?? platform}'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    try {
      setState(() {
        _isLoading = true;
      });
      
      final result = await _botService.testBotConnection(
        botId: widget.botId,
        platform: platform,
      );
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      if (result['status'] == 'connected') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kết nối thành công đến ${_platformNames[platform] ?? platform}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể kết nối đến ${_platformNames[platform] ?? platform}: ${result['message'] ?? 'Unknown error'}'),
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
          content: Text('Lỗi kiểm tra kết nối: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Open the documentation for a platform
  void _openDocumentation(String platform) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tài liệu hướng dẫn cho ${_platformNames[platform] ?? platform} sẽ mở trong trình duyệt'),
        backgroundColor: Colors.blue,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  // Toggle selection of a platform for batch operations
  void _togglePlatformSelection(String platform) {
    setState(() {
      if (_selectedPlatforms.contains(platform)) {
        _selectedPlatforms.remove(platform);
      } else {
        _selectedPlatforms.add(platform);
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // Get all platforms from config plus some default ones
    final allPlatforms = {
      ..._platformNames.keys,
      ...(_publishConfig.keys),
    }.toList();
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Publish: ${widget.botName}'),
            Text(
              'Manage Publishing',
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
            onPressed: _fetchPublishingConfigurations,
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
              : Column(
                  children: [
                    // Header with instructions
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(127),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Xuất bản bot của bạn',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Xuất bản bot của bạn trên nhiều nền tảng khác nhau để người dùng có thể tương tác.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (_selectedPlatforms.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Text(
                                  '${_selectedPlatforms.length} nền tảng đã chọn',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                const Spacer(),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.upload),
                                  label: const Text('Xuất bản hàng loạt'),
                                  onPressed: _batchPublish,
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.cancel),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  label: const Text('Hủy xuất bản'),
                                  onPressed: _batchUnpublish,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Platform list
                    Expanded(
                      child: ListView.builder(
                        itemCount: allPlatforms.length,
                        itemBuilder: (context, index) {
                          final platform = allPlatforms[index];
                          final platformConfig = _publishConfig[platform];
                          final isPublished = platformConfig != null && 
                                           platformConfig['published'] == true;
                          final isConfigured = platformConfig != null && 
                                           platformConfig['configured'] == true;
                          final isSelected = _selectedPlatforms.contains(platform);
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: isSelected
                                ? BorderSide(
                                    color: Theme.of(context).colorScheme.primary,
                                    width: 2,
                                  )
                                : BorderSide.none,
                            ),
                            elevation: isSelected ? 4 : 1,
                            child: InkWell(
                              onTap: () => _togglePlatformSelection(platform),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        // Platform icon and name
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: _platformColors[platform]?.withAlpha(25) ?? 
                                                   Colors.grey.withAlpha(25),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            _platformIcons[platform] ?? Icons.integration_instructions,
                                            color: _platformColors[platform] ?? Colors.grey,
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _platformNames[platform] ?? platform.toUpperCase(),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            // Status chip
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isPublished 
                                                  ? Colors.green.withAlpha(25) 
                                                  : isConfigured
                                                    ? Colors.orange.withAlpha(25)
                                                    : Colors.grey.withAlpha(25),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    isPublished 
                                                      ? Icons.check_circle 
                                                      : isConfigured
                                                        ? Icons.settings
                                                        : Icons.circle_outlined,
                                                    size: 12,
                                                    color: isPublished 
                                                      ? Colors.green
                                                      : isConfigured
                                                        ? Colors.orange
                                                        : Colors.grey,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    isPublished 
                                                      ? 'Đã xuất bản' 
                                                      : isConfigured
                                                        ? 'Đã cấu hình'
                                                        : 'Chưa xuất bản',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: isPublished 
                                                        ? Colors.green
                                                        : isConfigured
                                                          ? Colors.orange
                                                          : Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Spacer(),
                                        Checkbox(
                                          value: isSelected,
                                          onChanged: (value) => _togglePlatformSelection(platform),
                                          activeColor: Theme.of(context).colorScheme.primary,
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 16),
                                    
                                    // Status and actions
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        OutlinedButton.icon(
                                          icon: Icon(
                                            isPublished ? Icons.cancel : Icons.publish,
                                            size: 16,
                                          ),
                                          label: Text(
                                            isPublished ? 'Hủy xuất bản' : 'Xuất bản',
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: isPublished ? Colors.red : null,
                                          ),
                                          onPressed: isPublished
                                            ? () => _unpublishFromPlatform(platform)
                                            : () => _publishToPlatform(platform),
                                        ),
                                        
                                        if (isConfigured)
                                          OutlinedButton.icon(
                                            icon: const Icon(
                                              Icons.settings,
                                              size: 16,
                                            ),
                                            label: const Text('Cấu hình'),
                                            onPressed: () => _showConfigDialog(platform),
                                          ),
                                        
                                        if (isPublished)
                                          OutlinedButton.icon(
                                            icon: const Icon(
                                              Icons.sync,
                                              size: 16,
                                            ),
                                            label: const Text('Kiểm tra kết nối'),
                                            onPressed: () => _testConnection(platform),
                                          ),
                                        
                                        if (isPublished && platform == 'web')
                                          OutlinedButton.icon(
                                            icon: const Icon(
                                              Icons.content_copy,
                                              size: 16,
                                            ),
                                            label: const Text('Sao chép mã nhúng'),
                                            onPressed: () => _copyIntegrationCode(platform),
                                          ),
                                        
                                        OutlinedButton.icon(
                                          icon: const Icon(
                                            Icons.help_outline,
                                            size: 16,
                                          ),
                                          label: const Text('Hướng dẫn'),
                                          onPressed: () => _openDocumentation(platform),
                                        ),
                                      ],
                                    ),
                                    
                                    // Integration details if published
                                    if (isPublished && platformConfig != null && platformConfig.containsKey('details')) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(127),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Chi tiết tích hợp:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(platformConfig['details'] ?? 'Không có thông tin chi tiết'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
