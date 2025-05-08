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
  bool _isLoading = false;
  String? _error;

  final KnowledgeBaseService _knowledgeBaseService = KnowledgeBaseService();

  @override
  void dispose() {
    _channelIdController.dispose();
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
      await _knowledgeBaseService.connectSlack(
        widget.knowledgeBaseId,
        _channelIdController.text.trim(),
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
                const SizedBox(height: 24),
                TextFormField(
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