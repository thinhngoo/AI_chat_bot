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
  bool _isLoading = false;
  String? _error;

  final KnowledgeBaseService _knowledgeBaseService = KnowledgeBaseService();

  @override
  void dispose() {
    _spaceKeyController.dispose();
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
      await _knowledgeBaseService.connectConfluence(
        widget.knowledgeBaseId,
        _spaceKeyController.text.trim(),
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
                const SizedBox(height: 24),
                TextFormField(
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