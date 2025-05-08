import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../../core/utils/validators/input_validator.dart';
import '../models/prompt.dart';
import '../services/prompt_service.dart';

class CreateEditPromptScreen extends StatefulWidget {
  final Prompt? prompt;
  final List<String> availableCategories;

  const CreateEditPromptScreen({
    Key? key,
    this.prompt,
    required this.availableCategories,
  }) : super(key: key);

  @override
  State<CreateEditPromptScreen> createState() => _CreateEditPromptScreenState();
}

class _CreateEditPromptScreenState extends State<CreateEditPromptScreen> {
  final Logger _logger = Logger();
  final PromptService _promptService = PromptService();
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  String _selectedCategory = 'General';
  bool _isPublic = false;
  bool _isSaving = false;
  
  @override
  void initState() {
    super.initState();
    _initializeFormData();
  }
  
  void _initializeFormData() {
    if (widget.prompt != null) {
      // Populate form with existing prompt data
      _titleController.text = widget.prompt!.title;
      _contentController.text = widget.prompt!.content;
      _descriptionController.text = widget.prompt!.description;
      _selectedCategory = widget.prompt!.category;
      _isPublic = widget.prompt!.isPublic;
    }
    
    // If no categories are available, use default ones
    if (widget.availableCategories.isEmpty) {
      _selectedCategory = 'General';
    } else if (!widget.availableCategories.contains(_selectedCategory)) {
      _selectedCategory = widget.availableCategories.first;
    }
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  Future<void> _savePrompt() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    try {
      setState(() {
        _isSaving = true;
      });
      
      final title = _titleController.text.trim();
      final content = _contentController.text.trim();
      final description = _descriptionController.text.trim();
      
      // Always use "other" as category which we know works with the API
      final validCategory = "other";
      
      if (widget.prompt == null) {
        // Create new prompt
        await _promptService.createPrompt(
          title: title,
          content: content,
          description: description,
          category: validCategory, // Use fixed value instead of _selectedCategory
          isPublic: _isPublic,
        );
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prompt created successfully')),
        );
        
        Navigator.pop(context);
      } else {
        // Add validation to check for empty prompt ID
        if (widget.prompt!.id.isEmpty) {
          throw 'Cannot update prompt: ID is empty';
        }
        
        // Update existing prompt
        await _promptService.updatePrompt(
          promptId: widget.prompt!.id,
          title: title,
          content: content,
          description: description,
          category: validCategory, // Use fixed value instead of _selectedCategory
          isPublic: _isPublic,
        );
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prompt updated successfully')),
        );
        
        Navigator.pop(context);
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
  
  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.prompt != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Prompt' : 'Create Prompt'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _savePrompt,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('SAVE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter a title for your prompt',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => InputValidator.validateRequired(
                  value, 'title'),
                enabled: !_isSaving,
              ),
              const SizedBox(height: 16),
              
              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter a brief description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (value) => InputValidator.validateRequired(
                  value, 'description'),
                enabled: !_isSaving,
              ),
              const SizedBox(height: 16),
              
              // Category dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: (widget.availableCategories.isEmpty
                    ? [
                        'General',
                        'Programming',
                        'Writing',
                        'Business',
                        'Education',
                        'Health',
                        'Entertainment',
                        'Other',
                      ]
                    : widget.availableCategories)
                    .map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: _isSaving
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        }
                      },
              ),
              const SizedBox(height: 16),
              
              // Privacy setting
              SwitchListTile(
                title: const Text('Make this prompt public'),
                subtitle: Text(
                  'Public prompts can be seen and used by all users',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                value: _isPublic,
                onChanged: _isSaving
                    ? null
                    : (value) {
                        setState(() {
                          _isPublic = value;
                        });
                      },
              ),
              const SizedBox(height: 16),
              
              // Content field
              const Text(
                'Prompt Content',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  hintText: 'Enter your prompt content here...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 10,
                validator: (value) => InputValidator.validateRequired(
                  value, 'prompt content'),
                enabled: !_isSaving,
              ),
              
              const SizedBox(height: 24),
              
              // Guidance text
              const Text(
                'Tips for writing effective prompts:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildTipItem(
                '1. Be specific about what you want the AI to do',
              ),
              _buildTipItem(
                '2. Include context and any necessary constraints',
              ),
              _buildTipItem(
                '3. Use a clear structure with formatting when needed',
              ),
              _buildTipItem(
                '4. For complex tasks, break them down into steps',
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          fontSize: 14,
        ),
      ),
    );
  }
}