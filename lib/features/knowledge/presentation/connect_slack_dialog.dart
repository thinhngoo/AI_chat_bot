import 'package:flutter/material.dart';
import '../services/knowledge_base_service.dart';

class ConnectSlackDialog extends StatefulWidget {
  final String knowledgeBaseId;

  const ConnectSlackDialog({
    super.key,
    required this.knowledgeBaseId,
  });

  @override
  State<ConnectSlackDialog> createState() => _ConnectSlackDialogState();
}

class _ConnectSlackDialogState extends State<ConnectSlackDialog> {
  final _formKey = GlobalKey<FormState>();
  final _channelIdController = TextEditingController();
  final _tokenController = TextEditingController();
  final _workspaceIdController = TextEditingController();
  bool _isLoading = false;
  bool _showAdvancedOptions = false;
  String? _error;

  final KnowledgeBaseService _knowledgeBaseService = KnowledgeBaseService();

  @override
  void dispose() {
    _channelIdController.dispose();
    _tokenController.dispose();
    _workspaceIdController.dispose();
    super.dispose();
  }

  Future<void> _connectSlack() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _knowledgeBaseService.loadDataFromSlack(
        widget.knowledgeBaseId,
        _channelIdController.text.trim(),
        token: _tokenController.text.isNotEmpty ? _tokenController.text.trim() : null,
        workspaceId: _workspaceIdController.text.isNotEmpty ? _workspaceIdController.text.trim() : null,
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to connect Slack: $e';
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
                  'Connect Slack Channel',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Connect a Slack channel to import conversations to your knowledge base.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),                TextFormField(
                  controller: _channelIdController,
                  decoration: const InputDecoration(
                    labelText: 'Slack Channel ID',
                    hintText: 'C0123456789',
                    prefixIcon: Icon(Icons.message),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a channel ID';
                    }
                    // Basic Slack channel ID validation (starts with C and has numbers)
                    if (!value.startsWith('C') || !RegExp(r'C[A-Z0-9]+').hasMatch(value)) {
                      return 'Please enter a valid Slack channel ID (e.g. C0123456789)';
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
                        'Advanced Options',
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
                    controller: _tokenController,
                    decoration: const InputDecoration(
                      labelText: 'Slack API Token (Optional)',
                      hintText: 'xoxb-...',
                      prefixIcon: Icon(Icons.vpn_key),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _workspaceIdController,
                    decoration: const InputDecoration(
                      labelText: 'Workspace ID (Optional)',
                      hintText: 'T0123456789',
                      prefixIcon: Icon(Icons.business),
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                Text(
                  'How to find your Slack Channel ID:',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  '1. Open Slack in a web browser\n'
                  '2. Navigate to the channel\n'
                  '3. The channel ID is in the URL after the "/C" part',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _showAdvancedOptions,
                      onChanged: (value) {
                        setState(() {
                          _showAdvancedOptions = value ?? false;
                        });
                      },
                    ),
                    const Text('Show advanced options'),
                  ],
                ),
                if (_showAdvancedOptions) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _tokenController,
                    decoration: const InputDecoration(
                      labelText: 'Slack Token',
                      hintText: 'xoxb-1234567890-abcdef',
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _workspaceIdController,
                    decoration: const InputDecoration(
                      labelText: 'Workspace ID',
                      hintText: 'T0123456789',
                      prefixIcon: Icon(Icons.business),
                    ),
                  ),
                ],
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
                      onPressed: _isLoading ? null : _connectSlack,
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