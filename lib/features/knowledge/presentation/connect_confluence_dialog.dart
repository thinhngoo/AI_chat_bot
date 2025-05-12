import 'package:flutter/material.dart';
import '../services/knowledge_base_service.dart';

class ConnectConfluenceDialog extends StatefulWidget {
  final String knowledgeBaseId;

  const ConnectConfluenceDialog({
    super.key,
    required this.knowledgeBaseId,
  });

  @override
  State<ConnectConfluenceDialog> createState() => _ConnectConfluenceDialogState();
}

class _ConnectConfluenceDialogState extends State<ConnectConfluenceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _spaceKeyController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _apiTokenController = TextEditingController();
  bool _isLoading = false;
  bool _showAdvancedOptions = false;
  String? _error;

  final KnowledgeBaseService _knowledgeBaseService = KnowledgeBaseService();

  @override
  void dispose() {
    _spaceKeyController.dispose();
    _baseUrlController.dispose();
    _usernameController.dispose();
    _apiTokenController.dispose();
    super.dispose();
  }

  Future<void> _connectConfluence() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _knowledgeBaseService.loadDataFromConfluence(
        widget.knowledgeBaseId,
        _spaceKeyController.text.trim(),
        baseUrl: _baseUrlController.text.isNotEmpty ? _baseUrlController.text.trim() : null,
        username: _usernameController.text.isNotEmpty ? _usernameController.text.trim() : null,
        apiToken: _apiTokenController.text.isNotEmpty ? _apiTokenController.text.trim() : null,
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to connect Confluence: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Connect Confluence Space',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Connect a Confluence space to import documentation to your knowledge base.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),                TextFormField(
                  controller: _spaceKeyController,
                  decoration: const InputDecoration(
                    labelText: 'Confluence Space Key',
                    hintText: 'TEAM',
                    prefixIcon: Icon(Icons.article),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a space key';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                InkWell(
                  onTap: () {
                    setState(() {
                      _showAdvancedOptions = !_showAdvancedOptions;
                    });
                  },
                  child: Row(
                    children: [
                      Icon(
                        _showAdvancedOptions ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Advanced Authentication',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (_showAdvancedOptions) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _baseUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Confluence Base URL (Optional)',
                      hintText: 'https://yourcompany.atlassian.net',
                      prefixIcon: Icon(Icons.link),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username (Optional)',
                      hintText: 'your.email@example.com',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _apiTokenController,
                    decoration: const InputDecoration(
                      labelText: 'API Token (Optional)',
                      hintText: 'Enter your Confluence API token',
                      prefixIcon: Icon(Icons.vpn_key),
                    ),
                    obscureText: true,
                  ),
                ],
                
                const SizedBox(height: 16),
                if (_showAdvancedOptions) ...[
                  TextFormField(
                    controller: _baseUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Base URL',
                      hintText: 'https://your-domain.atlassian.net',
                      prefixIcon: Icon(Icons.link),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      hintText: 'your-email@example.com',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _apiTokenController,
                    decoration: const InputDecoration(
                      labelText: 'API Token',
                      hintText: 'Your API token',
                      prefixIcon: Icon(Icons.vpn_key),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showAdvancedOptions = !_showAdvancedOptions;
                    });
                  },
                  child: Text(_showAdvancedOptions ? 'Hide Advanced Options' : 'Show Advanced Options'),
                ),
                const SizedBox(height: 16),
                Text(
                  'How to find your Confluence Space Key:',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  '1. Go to your Confluence space\n'
                  '2. Look at the URL, it will contain "/spaces/"\n'
                  '3. The space key is right after "/spaces/" in the URL',
                  style: theme.textTheme.bodyMedium,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _connectConfluence,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Connect'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}