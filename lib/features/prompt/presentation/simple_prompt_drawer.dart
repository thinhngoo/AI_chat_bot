import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../services/prompt_service.dart';
import '../models/prompt.dart';
import '../../../widgets/information.dart';
import '../../../widgets/dialog.dart';
import '../../../widgets/text_field.dart';
import '../../../widgets/button.dart';

class SimplePromptDrawer extends StatefulWidget {
  final Function(String content)? onPromptCreated;
  final Prompt? prompt;
  const SimplePromptDrawer({
    super.key,
    this.onPromptCreated,
    this.prompt,
  });

  static Future<void> show(
    BuildContext context,
    Function(String content)? onPromptCreated,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SimplePromptDrawer(
        onPromptCreated: onPromptCreated,
      ),
    );
  }

  static Future<void> showEdit(
    BuildContext context,
    Prompt prompt,
    Function(String content)? onPromptUpdated,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SimplePromptDrawer(
        prompt: prompt,
        onPromptCreated: onPromptUpdated,
      ),
    );
  }

  @override
  State<SimplePromptDrawer> createState() => _SimplePromptDrawerState();
}

class _SimplePromptDrawerState extends State<SimplePromptDrawer> {
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

        GlobalSnackBar.show(
          context: context,
          message: 'Prompt updated successfully',
          variant: SnackBarVariant.success,
        );
      } else {
        await _promptService.createPrompt(
          title: name,
          content: content,
          description: 'Created from quick prompt dialog',
          category: 'other',
          isPublic: false,
        );

        if (!mounted) return;

        GlobalSnackBar.show(
          context: context,
          message: 'Prompt created successfully',
          variant: SnackBarVariant.success,
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

      GlobalSnackBar.show(
        context: context,
        message: 'Error: ${e.toString()}',
        variant: SnackBarVariant.error,
      );
    }
  }

  Future<void> _toggleFavorite() async {
    if (!_isEditMode || widget.prompt == null) return;

    // Validate that the ID is not empty
    if (widget.prompt!.id.isEmpty) {
      _logger.e('Cannot toggle favorite: prompt ID is empty');

      if (!mounted) return;

      GlobalSnackBar.show(
        context: context,
        message: 'Cannot toggle favorite: prompt ID is empty',
        variant: SnackBarVariant.error,
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
        success =
            await _promptService.removePromptFromFavorites(widget.prompt!.id);
      } else {
        success = await _promptService.addPromptToFavorites(widget.prompt!.id);
      }

      if (!mounted) return;

      if (success) {
        setState(() {
          _isFavorite = !_isFavorite;
          _isSaving = false;
        });

        GlobalSnackBar.show(
          context: context,
          message:
              _isFavorite ? 'Added to favorites' : 'Removed from favorites',
          variant: SnackBarVariant.success,
        );
      }
    } catch (e) {
      _logger.e('Error toggling favorite: $e');

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      GlobalSnackBar.show(
        context: context,
        message: 'Error: ${e.toString()}',
        variant: SnackBarVariant.error,
      );
    }
  }

  Future<void> _deletePrompt() async {
    if (!_isEditMode || widget.prompt == null) return;

    // Log the ID to help debug
    _logger.i('Attempting to delete prompt with ID: ${widget.prompt!.id}');

    final confirmed = await GlobalDialog.show(
      context: context,
      title: 'Delete Prompt',
      message: 'Are you sure you want to delete "${widget.prompt!.title}"?',
      variant: DialogVariant.warning,
      confirmLabel: 'DELETE',
      cancelLabel: 'CANCEL',
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
        GlobalSnackBar.show(
          context: context,
          message: 'Prompt deleted',
          variant: SnackBarVariant.success,
        );

        Navigator.pop(context);
      }
    } catch (e) {
      _logger.e('Error deleting prompt: $e');

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      GlobalSnackBar.show(
        context: context,
        message: 'Error: ${e.toString()}',
        variant: SnackBarVariant.error,
      );
    }
  }

  Widget _buildPromptSection(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FloatingLabelTextField(
          controller: _promptController,
          label: 'Enter your prompt',
          hintText: 'What would you like to ask?',
          maxLines: 3,
          onSubmitted: (_) => _savePrompt(),
          enabled: !_isSaving,
          darkMode: isDarkMode,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              color: Theme.of(context).hintColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text('Try to be specific in your prompt',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).hintColor)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.sentiment_satisfied_alt,
              color: Theme.of(context).hintColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text('Start with "Write", "Create", or "Explain"',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).hintColor)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: screenWidth,
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Indicator bar
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Theme.of(context).colorScheme.onSurface.withOpacity(0.3)
                    : Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Container(
            height: 56 + MediaQuery.of(context).padding.top,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              left: 8,
              right: 8,
            ),
            child: Row(
              children: [
                const SizedBox(width: 40),
                const Spacer(),
                Text(
                  _isEditMode ? 'Edit Prompt' : 'New Prompt',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 24),
                  color: Theme.of(context).hintColor,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FloatingLabelTextField(
                      controller: _nameController,
                      label: 'Name',
                      hintText: 'Name of the prompt',
                      onSubmitted: (_) => _savePrompt(),
                      enabled: !_isSaving,
                      darkMode: isDarkMode,
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
                        const Expanded(
                          child: Text(
                              'Use square brackets [ ] to specify user input.'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildPromptSection(context),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            if (_isEditMode) ...[
                              Button(
                                label: 'Delete',
                                icon: Icons.delete,
                                onPressed: _isSaving ? null : _deletePrompt,
                                variant: ButtonVariant.delete,
                                isDarkMode: isDarkMode,
                                fullWidth: false,
                                size: ButtonSize.small,
                              ),
                              const SizedBox(width: 8),
                              Button(
                                label: _isFavorite ? 'Unfavorite' : 'Favorite',
                                icon: _isFavorite ? Icons.star : Icons.star_border,
                                onPressed: _isSaving ? null : _toggleFavorite,
                                variant: ButtonVariant.ghost,
                                isDarkMode: isDarkMode,
                                fullWidth: false,
                                size: ButtonSize.small,
                                color: _isFavorite ? Colors.amber : null,
                              ),
                            ],
                          ],
                        ),
                        Row(
                          children: [
                            Button(
                              label: 'Cancel',
                              onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                              variant: ButtonVariant.ghost,
                              isDarkMode: isDarkMode,
                              fullWidth: false,
                              color: isDarkMode ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withAlpha(204),
                            ),
                            const SizedBox(width: 8),
                            _isSaving 
                            ? SizedBox(
                                height: 40,
                                width: 112,
                                child: Center(
                                  child: SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Theme.of(context).hintColor,
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                ),
                              )
                            : Button(
                              label: _isEditMode ? 'Update' : 'Create',
                              onPressed: _savePrompt,
                              variant: ButtonVariant.primary,
                              isDarkMode: isDarkMode,
                              fullWidth: false,
                              icon: Icons.check,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
