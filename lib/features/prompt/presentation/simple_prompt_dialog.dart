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
        // Add validation to check for empty prompt ID
        if (widget.prompt == null || widget.prompt!.id.isEmpty) {
          throw 'Cannot update prompt: ID is empty';
        }

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
    if (!_isEditMode || widget.prompt == null) return;
    
    // Validate that the ID is not empty
    if (widget.prompt!.id.isEmpty) {
      _logger.e('Cannot toggle favorite: prompt ID is empty');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot toggle favorite: prompt ID is empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Log the ID to help debug
    _logger.i('Toggling favorite for prompt with ID: ${widget.prompt!.id}');

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
    if (!_isEditMode || widget.prompt == null) return;

    // Log the ID to help debug
    _logger.i('Attempting to delete prompt with ID: ${widget.prompt!.id}');

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

      if (widget.prompt!.id.isEmpty) {
        throw 'Cannot delete prompt: ID is empty';
      }

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

  Widget _buildPromptSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter your prompt',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _promptController,
          maxLines: null,
          minLines: 3,
          decoration: InputDecoration(
            hintText: 'What would you like to ask?',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => _promptController.clear(),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a prompt';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text('Try to be specific in your prompt'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.sentiment_satisfied_alt,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text('Start with "Write", "Create", or "Explain"'),
          ],
        ),
      ],
    );
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
                child: _buildPromptSection(context),
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