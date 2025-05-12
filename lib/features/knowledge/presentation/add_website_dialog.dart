import 'package:ai_chat_bot/widgets/information.dart';
import 'package:flutter/material.dart';
import '../services/knowledge_base_service.dart';
import '../../../widgets/button.dart';
import '../../../widgets/text_field.dart';

class AddWebsiteDialog extends StatefulWidget {
  final String knowledgeBaseId;

  const AddWebsiteDialog({
    super.key,
    required this.knowledgeBaseId,
  });

  @override
  State<AddWebsiteDialog> createState() => _AddWebsiteDialogState();
}

class _AddWebsiteDialogState extends State<AddWebsiteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  final KnowledgeBaseService _knowledgeBaseService = KnowledgeBaseService();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _addWebsite() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      GlobalSnackBar.show(
        context: context,
        message: 'This feature is under maintenance',
        variant: SnackBarVariant.info,
      );
      
      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }

      return;

      // ignore: dead_code
      await _knowledgeBaseService.uploadWebsite(
        widget.knowledgeBaseId,
        _urlController.text.trim(),
      );
    } catch (e) {
      setState(() {
        _error = 'Failed to add website: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(30),
          width: 1,
        ),
      ),
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
                Icon(
                  Icons.language,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Add Website URL',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the website URL you want to add to your knowledge base.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(204),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _urlController,
                  label: 'Website URL',
                  hintText: 'https://example.com',
                  prefixIcon: Icons.web,
                  keyboardType: TextInputType.url,
                  darkMode: isDarkMode,
                  errorText: _error,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Button(
                        label: 'Cancel',
                        onPressed: _isLoading 
                            ? null 
                            : () => Navigator.of(context).pop(),
                        variant: ButtonVariant.ghost,
                        isDarkMode: isDarkMode,
                        color: isDarkMode
                            ? Theme.of(context).colorScheme.onSurface.withAlpha(180)
                            : Theme.of(context).colorScheme.onSurface.withAlpha(120),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Button(
                        label: 'Add',
                        onPressed: _isLoading ? null : _addWebsite,
                        variant: ButtonVariant.primary,
                        isDarkMode: isDarkMode,
                        fontWeight: FontWeight.bold,
                      ),
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