import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../services/prompt_service.dart';
import '../models/prompt.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/category_constants.dart';
import '../../../widgets/information.dart';
import '../../../widgets/dialog.dart';
import '../../../widgets/text_field.dart';
import '../../../widgets/button.dart';

enum PromptDrawerMode { create, edit, view }

class PromptDrawer extends StatefulWidget {
  final Function(String content)? onPromptCreated;
  final Prompt? prompt;
  final PromptDrawerMode mode;

  const PromptDrawer({
    super.key,
    this.onPromptCreated,
    this.prompt,
    this.mode = PromptDrawerMode.create,
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
      builder: (context) => PromptDrawer(
        onPromptCreated: onPromptCreated,
        mode: PromptDrawerMode.create,
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
      builder: (context) => PromptDrawer(
        prompt: prompt,
        onPromptCreated: onPromptUpdated,
        mode: PromptDrawerMode.edit,
      ),
    );
  }

  static Future<void> showViewOnly(BuildContext context, Prompt prompt,
      {Function(String content)? onFavoriteToggled}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => PromptDrawer(
        prompt: prompt,
        mode: PromptDrawerMode.view,
        onPromptCreated: onFavoriteToggled,
      ),
    );
  }

  @override
  State<PromptDrawer> createState() => _PromptDrawerState();
}

class _PromptDrawerState extends State<PromptDrawer> {
  final _logger = Logger();
  final _promptService = PromptService();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _promptController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();

  bool _useSquareBrackets = true;
  bool _isSaving = false;
  bool _isFavorite = false;
  String? _nameError;
  String? _promptError;
  bool _isPublic = false;

  bool get _isEditMode => widget.mode == PromptDrawerMode.edit;
  bool get _isViewOnly => widget.mode == PromptDrawerMode.view;
  bool get _isCreateMode => widget.mode == PromptDrawerMode.create;

  @override
  void initState() {
    super.initState();
    _initializeFormData();
  }

  void _initializeFormData() {
    if (widget.prompt != null) {
      _nameController.text = widget.prompt!.title;
      _promptController.text = widget.prompt!.content;
      _descriptionController.text = widget.prompt!.description;
      _categoryController.text = widget.prompt!.category;
      _isFavorite = widget.prompt!.isFavorite;
      _isPublic = widget.prompt!.isPublic;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _promptController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _savePrompt() async {
    // Clear previous errors
    setState(() {
      _nameError = null;
      _promptError = null;
    });

    // Validate form
    bool isValid = true;

    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _nameError = 'Name is required';
      });
      isValid = false;
    }

    if (_promptController.text.trim().isEmpty) {
      setState(() {
        _promptError = 'Prompt content is required';
      });
      isValid = false;
    }

    if (!isValid) {
      return;
    }

    try {
      setState(() {
        _isSaving = true;
      });

      final name = _nameController.text.trim();
      final content = _promptController.text.trim();
      final description = _descriptionController.text.trim();
      final category = _categoryController.text.trim();

      if (_isEditMode) {
        // Add validation to check for empty prompt ID
        if (widget.prompt == null || widget.prompt!.id.isEmpty) {
          throw 'Cannot update prompt: ID is empty';
        }

        await _promptService.updatePrompt(
          promptId: widget.prompt!.id,
          title: name,
          content: content,
          description: description,
          category: category,
          isPublic: _isPublic,
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
          description: description,
          category: category,
          isPublic: _isPublic,
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
    if (widget.prompt == null) return;

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

        // Don't show snackbar for button in header to avoid distraction
        // Only show snackbar if the button is not in header (detect based on where it was pressed)
        if (widget.onPromptCreated != null) {
          GlobalSnackBar.show(
            context: context,
            message:
                _isFavorite ? 'Added to favorites' : 'Removed from favorites',
            variant: SnackBarVariant.success,
          );
        }
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
    if (widget.prompt == null) return;

    // Log the ID to help debug
    _logger.i('Attempting to delete prompt with ID: ${widget.prompt!.id}');

    final confirmed = await GlobalDialog.show(
      context: context,
      title: 'Delete Prompt',
      message: 'Are you sure you want to delete "${widget.prompt!.title}"?',
      variant: DialogVariant.warning,
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
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

        // Call onPromptCreated callback to notify parent about the deletion
        if (widget.onPromptCreated != null) {
          widget.onPromptCreated!('');
        }
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

  Widget _buildPromptForm(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FloatingLabelTextField(
          controller: _nameController,
          label: 'Name',
          hintText: 'Name of the prompt',
          onSubmitted: (_) => _savePrompt(),
          enabled: !_isSaving && !_isViewOnly,
          darkMode: isDarkMode,
          readOnly: _isViewOnly,
          errorText: _nameError,
        ),
        const SizedBox(height: 16),
        FloatingLabelTextField(
          controller: _descriptionController,
          label: 'Description',
          hintText: 'Brief description of the prompt',
          maxLines: 1,
          onSubmitted: (_) => _savePrompt(),
          enabled: !_isSaving && !_isViewOnly,
          darkMode: isDarkMode,
          readOnly: _isViewOnly,
        ),
        const SizedBox(height: 16),
        FloatingLabelTextField(
          controller: _promptController,
          label: 'Prompt',
          hintText: 'What would you like to ask?',
          maxLines: 3,
          onSubmitted: (_) => _savePrompt(),
          enabled: !_isSaving && !_isViewOnly,
          darkMode: isDarkMode,
          readOnly: _isViewOnly,
          errorText: _promptError,
        ),
        const SizedBox(height: 12),

        // Only show editable fields in non-view-only mode
        if (_isViewOnly) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Row(
              children: [
                Icon(
                  CategoryConstants.getCategoryIcon(_categoryController.text),
                  size: 20,
                  color: CategoryConstants.getCategoryColor(
                    _categoryController.text,
                    darkMode: isDarkMode,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Category: ${_categoryController.text}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                ),
              ],
            ),
          ),
        ] else ...[
          // Category dropdown
          StyledDropdown<String>(
            label: 'Category',
            hintText: 'Select a category',
            value: _categoryController.text.isEmpty
                ? 'other'
                : _categoryController.text,
            onChanged: (String? newValue) {
              setState(() {
                _categoryController.text = newValue ?? 'other';
              });
            },
            darkMode: isDarkMode,
            enabled: !_isSaving && !_isViewOnly,
            items: CategoryConstants.categories
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Row(
                  children: [
                    Icon(
                      CategoryConstants.getCategoryIcon(value),
                      size: 16,
                      color: CategoryConstants.getCategoryColor(
                        value,
                        darkMode: isDarkMode,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      value.substring(0, 1).toUpperCase() +
                          value.substring(1),
                      style: TextStyle(
                        color: isDarkMode
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Row(
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
          ),

          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Row(
              children: [
                Icon(
                  Icons.assignment,
                  color: Theme.of(context).hintColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text('For complex tasks, break them down into steps',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Theme.of(context).hintColor)),
              ],
            ),
          ),
        ],

        if (_isPublic && widget.prompt?.authorName != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Row(
              children: [
                Icon(
                  Icons.person,
                  color: Theme.of(context).hintColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Owner: ${widget.prompt!.authorName}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Row(
            children: [
              Icon(
                _isPublic ? Icons.public : Icons.lock,
                color: Theme.of(context).hintColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _isPublic
                    ? 'Visible and usable by everyone'
                    : 'Private and only usable by you',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
              ),
            ],
          ),
        ),

        // Toggles section
        if (!_isViewOnly) ...[
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Make this prompt public',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: _isPublic,
                  onChanged: _isSaving
                      ? null
                      : (bool value) {
                          setState(() {
                            _isPublic = value;
                          });
                        },
                  activeColor: isDarkMode
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.white,
                  activeTrackColor: Theme.of(context).hintColor,
                ),
              ],
            ),
          ),

          // Square brackets toggle
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Use square brackets to specify user input',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: _useSquareBrackets,
                  onChanged: (value) {
                    setState(() {
                      _useSquareBrackets = value;
                    });
                  },
                  activeColor: isDarkMode
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.white,
                  activeTrackColor: Theme.of(context).hintColor,
                ),
              ],
            ),
          ),
        ]
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (_isEditMode) ...[
              Button(
                label: 'Delete',
                onPressed: _isSaving ? null : _deletePrompt,
                variant: ButtonVariant.delete,
                isDarkMode: isDarkMode,
                fullWidth: false,
                size: ButtonSize.medium,
                fontWeight: FontWeight.bold,
                radius: ButtonRadius.small,
                width: 100,
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
              size: ButtonSize.medium,
              radius: ButtonRadius.small,
              width: 100,
              color: isDarkMode
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.onSurface.withAlpha(204),
            ),
            if (!_isViewOnly) ...[
              const SizedBox(width: 8),
              Button(
                label: _isEditMode ? 'Update' : 'Create',
                onPressed: _savePrompt,
                icon: _isEditMode ? Icons.edit : Icons.add,
                variant: ButtonVariant.primary,
                isDarkMode: isDarkMode,
                fullWidth: false,
                size: ButtonSize.medium,
                fontWeight: FontWeight.bold,
                radius: ButtonRadius.small,
                isLoading: _isSaving,
              ),
            ],
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colors = isDarkMode ? AppColors.dark : AppColors.light;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight =
        MediaQuery.of(context).size.height * (_isViewOnly ? 0.68 : 0.9);

    return Container(
      width: screenWidth,
      height: screenHeight,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Indicator bar
          const DrawerTopIndicator(),
          Container(
            padding: EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
            child: Row(
              children: [
                // Left side with favorite and public/private icons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Only show favorite button in edit and view modes
                    if (!_isCreateMode)
                      IconButton(
                        icon: Icon(
                          _isFavorite ? Icons.star : Icons.star_border,
                          size: 24,
                        ),
                        color: _isFavorite
                            ? colors.yellow
                            : Theme.of(context).hintColor,
                        onPressed: _isSaving ? null : _toggleFavorite,
                      )
                    else
                      const SizedBox(width: 24),

                    // Public/private indicator for edit mode
                    if (_isEditMode || _isViewOnly)
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Icon(
                          _isPublic ? Icons.public : Icons.lock,
                          size: 20,
                          color: Theme.of(context).hintColor,
                        ),
                      )
                    else
                      const SizedBox(width: 24),
                  ],
                ),

                // Centered title
                Expanded(
                  child: Center(
                    child: Text(
                      _isViewOnly
                          ? 'View Prompt'
                          : (_isEditMode ? 'Edit Prompt' : 'New Prompt'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),

                // Right side - close button with equivalent width to left side
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Invisible spacer to balance the public/private icon on left side
                    if ((_isEditMode || _isViewOnly) && !_isCreateMode)
                      const SizedBox(width: 24),

                    // Close button
                    IconButton(
                      icon: const Icon(Icons.close, size: 24),
                      color: Theme.of(context).hintColor,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Content area
          Expanded(
            child: Stack(
              children: [
                // Scrollable form area
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                      16, 16, 16, 80), // Add bottom padding for buttons
                  child: Form(
                    key: _formKey,
                    child: _buildPromptForm(context),
                  ),
                ),
                // Fixed bottom action buttons
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    child: _buildActionButtons(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
