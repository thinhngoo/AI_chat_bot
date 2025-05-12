import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../services/knowledge_base_service.dart';
import '../../../widgets/button.dart';
import '../../../widgets/text_field.dart';
import '../../../widgets/information.dart';

class CreateKnowledgeBaseDrawer extends StatefulWidget {
  final Function()? onKnowledgeBaseCreated;

  const CreateKnowledgeBaseDrawer({
    super.key,
    this.onKnowledgeBaseCreated,
  });

  static Future<void> show(
    BuildContext context,
    Function()? onKnowledgeBaseCreated,
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
      builder: (context) => CreateKnowledgeBaseDrawer(
        onKnowledgeBaseCreated: onKnowledgeBaseCreated,
      ),
    );
  }

  @override
  State<CreateKnowledgeBaseDrawer> createState() => _CreateKnowledgeBaseDrawerState();
}

class _CreateKnowledgeBaseDrawerState extends State<CreateKnowledgeBaseDrawer> {
  final _logger = Logger();
  final _knowledgeBaseService = KnowledgeBaseService();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  bool _isSaving = false;
  String? _nameError;
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createKnowledgeBase() async {
    // Clear previous errors
    setState(() {
      _nameError = null;
    });

    // Validate form
    bool isValid = true;

    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _nameError = 'Name is required';
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
      final description = _descriptionController.text.trim();

      await _knowledgeBaseService.createKnowledgeBase(
        name: name,
        description: description,
      );

      if (!mounted) return;

      GlobalSnackBar.show(
        context: context,
        message: 'Knowledge base created successfully',
        variant: SnackBarVariant.success,
      );

      Navigator.of(context).pop();
      if (widget.onKnowledgeBaseCreated != null) {
        widget.onKnowledgeBaseCreated!();
      }
    } catch (e) {
      _logger.e('Error creating knowledge base: $e');

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

  Widget _buildForm(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FloatingLabelTextField(
          controller: _nameController,
          label: 'Name',
          hintText: 'Enter knowledge base name',
          onSubmitted: (_) => _createKnowledgeBase(),
          enabled: !_isSaving,
          darkMode: isDarkMode,
          errorText: _nameError,
        ),
        const SizedBox(height: 16),
        FloatingLabelTextField(
          controller: _descriptionController,
          label: 'Description',
          hintText: 'Brief description of the knowledge base',
          maxLines: 3,
          onSubmitted: (_) => _createKnowledgeBase(),
          enabled: !_isSaving,
          darkMode: isDarkMode,
        ),
        const SizedBox(height: 16),
        
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).hintColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'KBs store and organize your data for AI use',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).hintColor),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

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
              Text(
                'You update KBs after creation',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).hintColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Button(
          label: 'Cancel',
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          variant: ButtonVariant.ghost,
          isDarkMode: isDarkMode,
          fullWidth: false,
          size: ButtonSize.medium,
          width: 100,
          color: isDarkMode
              ? Theme.of(context).colorScheme.onSurface
              : Theme.of(context).colorScheme.onSurface.withAlpha(204),
        ),
        const SizedBox(width: 8),
        _isSaving
            ? SizedBox(
                height: 40,
                width: 100,
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
                label: 'Create',
                onPressed: _createKnowledgeBase,
                variant: ButtonVariant.primary,
                isDarkMode: isDarkMode,
                fullWidth: false,
                size: ButtonSize.medium,
                fontWeight: FontWeight.bold,
                width: 100,
              ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height * 0.6;

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
            padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
            child: Row(
              children: [
                // Left side spacer
                const SizedBox(width: 48),

                // Centered title
                Expanded(
                  child: Center(
                    child: Text(
                      'Create Knowledge Base',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),

                // Close button
                IconButton(
                  icon: const Icon(Icons.close, size: 24),
                  color: Theme.of(context).hintColor,
                  onPressed: () => Navigator.pop(context),
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
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Add bottom padding for buttons
                  child: Form(
                    key: _formKey,
                    child: _buildForm(context),
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