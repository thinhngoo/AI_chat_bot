import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../services/prompt_service.dart';
import '../../../core/utils/validators/input_validator.dart';

class SimplePromptDialog extends StatefulWidget {
  final Function(String content)? onPromptCreated;

  const SimplePromptDialog({
    Key? key,
    this.onPromptCreated,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context,
    Function(String content)? onPromptCreated,
  ) {
    return showDialog(
      context: context,
      builder: (context) => SimplePromptDialog(
        onPromptCreated: onPromptCreated,
      ),
    );
  }

  @override
  State<SimplePromptDialog> createState() => _SimplePromptDialogState();
}

class _SimplePromptDialogState extends State<SimplePromptDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _promptController = TextEditingController();
  final _logger = Logger();
  final _promptService = PromptService();
  
  bool _useSquareBrackets = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _createPrompt() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() {
        _isSaving = true;
      });

      final name = _nameController.text.trim();
      final content = _promptController.text.trim();

      // Create prompt with minimal required fields
      await _promptService.createPrompt(
        title: name,
        content: content,
        // Set standard values for other required fields
        description: "Created from quick prompt dialog",
        category: "other", // Using the known working value
        isPublic: false,
      );

      if (!mounted) return;

      // Close dialog and execute callback if provided
      Navigator.of(context).pop();
      if (widget.onPromptCreated != null) {
        widget.onPromptCreated!(content);
      }
    } catch (e) {
      _logger.e('Error creating prompt: $e');

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(
          maxWidth: 500,
          maxHeight: 500,
        ),
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'New Prompt',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Name of the prompt',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => InputValidator.validateRequired(value, 'name'),
                enabled: !_isSaving,
              ),
              const SizedBox(height: 16),

              // Square brackets checkbox
              Row(
                children: [
                  Checkbox(
                    value: _useSquareBrackets,
                    onChanged: (value) {
                      setState(() {
                        _useSquareBrackets = value ?? true;
                      });
                    },
                  ),
                  const Text('Use square brackets [ ] to specify user input.'),
                ],
              ),
              const SizedBox(height: 16),

              // Prompt content field
              Expanded(
                child: TextFormField(
                  controller: _promptController,
                  decoration: const InputDecoration(
                    hintText: 'e.g: Write an article about [TOPIC], make sure to include these keywords: [KEYWORDS]',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  validator: (value) => InputValidator.validateRequired(value, 'prompt'),
                  enabled: !_isSaving,
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _createPrompt,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Create'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}