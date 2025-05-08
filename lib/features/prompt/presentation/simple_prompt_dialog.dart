import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../services/prompt_service.dart';
import '../../../core/utils/validators/input_validator.dart';
import '../models/prompt.dart';

class SimplePromptDialog extends StatefulWidget {
  final Function(String content)? onPromptCreated;
  final Prompt? prompt;

  const SimplePromptDialog({
    Key? key,
    this.onPromptCreated,
    this.prompt,
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

  static Future<void> showEdit(
    BuildContext context,
    Prompt prompt,
    Function(String content)? onPromptUpdated,
  ) {
    return showDialog(
      context: context,
      builder: (context) => SimplePromptDialog(
        prompt: prompt,
        onPromptCreated: onPromptUpdated,
      ),
    );
  }

  static Future<void> showWithContent({
    required BuildContext context,
    String initialTitle = '',
    String initialContent = '',
    String initialDescription = '',
    Function(Prompt)? callback,
  }) {
    return showDialog(
      context: context,
      builder: (context) => _SimplePromptDialogWithContent(
        initialTitle: initialTitle,
        initialContent: initialContent,
        initialDescription: initialDescription,
        callback: callback,
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
  bool _isFavorite = false;
  bool get _isEditMode => widget.prompt != null;

  @override
  void initState() {
    super.initState();
    _initializeFormData();
  }

  void _initializeFormData() {
    if (_isEditMode) {
      _nameController.text = widget.prompt!.title;
      _promptController.text = widget.prompt!.content;
      _isFavorite = widget.prompt!.isFavorite;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _savePrompt() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() {
        _isSaving = true;
      });

      final name = _nameController.text.trim();
      final content = _promptController.text.trim();

      if (_isEditMode) {
        await _promptService.updatePrompt(
          promptId: widget.prompt!.id,
          title: name,
          content: content,
          description: widget.prompt!.description,
          category: widget.prompt!.category,
          isPublic: widget.prompt!.isPublic,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prompt updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await _promptService.createPrompt(
          title: name,
          content: content,
          description: "Created from quick prompt dialog",
          category: "other",
          isPublic: false,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prompt created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      if (widget.onPromptCreated != null) {
        widget.onPromptCreated!(content);
      }
    } catch (e) {
      _logger.e('Error saving prompt: $e');

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleFavorite() async {
    if (!_isEditMode) return;

    try {
      setState(() {
        _isSaving = true;
      });

      bool success;
      if (_isFavorite) {
        success = await _promptService.removePromptFromFavorites(widget.prompt!.id);
      } else {
        success = await _promptService.addPromptToFavorites(widget.prompt!.id);
      }

      if (!mounted) return;

      if (success) {
        setState(() {
          _isFavorite = !_isFavorite;
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFavorite ? 'Added to favorites' : 'Removed from favorites'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _logger.e('Error toggling favorite: $e');

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deletePrompt() async {
    if (!_isEditMode) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Prompt'),
        content: Text('Are you sure you want to delete "${widget.prompt!.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() {
        _isSaving = true;
      });

      final success = await _promptService.deletePrompt(widget.prompt!.id);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prompt deleted'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      _logger.e('Error deleting prompt: $e');

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditMode ? 'Edit Prompt' : 'New Prompt',
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (_isEditMode) ...[
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: _isSaving ? null : _deletePrompt,
                          tooltip: 'Delete prompt',
                        ),
                        IconButton(
                          icon: Icon(
                            _isFavorite ? Icons.star : Icons.star_border,
                            color: _isFavorite ? Colors.amber : null,
                          ),
                          onPressed: _isSaving ? null : _toggleFavorite,
                          tooltip: _isFavorite ? 'Remove from favorites' : 'Add to favorites',
                        ),
                      ],
                    ],
                  ),
                  Row(
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
                        onPressed: _isSaving ? null : _savePrompt,
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
                            : Text(_isEditMode ? 'Update' : 'Create'),
                      ),
                    ],
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

// Custom dialog for pre-filling content
class _SimplePromptDialogWithContent extends StatefulWidget {
  final String initialTitle;
  final String initialContent;
  final String initialDescription;
  final Function(Prompt)? callback;

  const _SimplePromptDialogWithContent({
    required this.initialTitle,
    required this.initialContent,
    required this.initialDescription,
    this.callback,
  });

  @override
  State<_SimplePromptDialogWithContent> createState() => _SimplePromptDialogWithContentState();
}

class _SimplePromptDialogWithContentState extends State<_SimplePromptDialogWithContent> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _promptController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _logger = Logger();
  final _promptService = PromptService();

  bool _useSquareBrackets = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialTitle;
    _promptController.text = widget.initialContent;
    _descriptionController.text = widget.initialDescription;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _promptController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _savePrompt() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() {
        _isSaving = true;
      });

      final title = _nameController.text.trim();
      final content = _promptController.text.trim();
      final description = _descriptionController.text.isEmpty 
          ? "Created from existing prompt" 
          : _descriptionController.text.trim();

      // Always create a new prompt (since the original had an empty ID)
      final prompt = await _promptService.createPrompt(
        title: title,
        content: content,
        description: description,
        category: "other",
        isPublic: false,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prompt created successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
      
      // Call the callback with the created prompt
      if (widget.callback != null) {
        widget.callback!(prompt);
      }
    } catch (e) {
      _logger.e('Error creating prompt: $e');

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Create New Prompt',
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
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter a title for your prompt',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => InputValidator.validateRequired(value, 'title'),
                enabled: !_isSaving,
              ),
              const SizedBox(height: 16),
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
              Expanded(
                child: TextFormField(
                  controller: _promptController,
                  decoration: const InputDecoration(
                    labelText: 'Prompt Content',
                    hintText: 'e.g: Write an article about [TOPIC], make sure to include these keywords: [KEYWORDS]',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  validator: (value) => InputValidator.validateRequired(value, 'prompt content'),
                  enabled: !_isSaving,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'This prompt will be saved as a new prompt in your private collection.',
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
              ),
              const SizedBox(height: 16),
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
                    onPressed: _isSaving ? null : _savePrompt,
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
                        : const Text('Create New'),
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