import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../../core/utils/validators/input_validator.dart';
import '../services/bot_service.dart';
import '../../../widgets/text_field.dart';
import '../../../widgets/information.dart';
import '../../../widgets/button.dart';

class CreateBotScreen extends StatefulWidget {
  const CreateBotScreen({super.key});

  @override
  State<CreateBotScreen> createState() => _CreateBotScreenState();
}

class _CreateBotScreenState extends State<CreateBotScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _promptController = TextEditingController();
  final Logger _logger = Logger();
  final BotService _botService = BotService();
  
  String _selectedModel = 'gpt-4o-mini';
  bool _isLoading = false;
  
  // Error states
  String? _nameError;
  String? _descriptionError;
  String? _promptError;
  
  final List<Map<String, String>> _availableModels = [
    {'id': 'gpt-4o-mini', 'name': 'GPT-4o mini'},
    {'id': 'gpt-4o', 'name': 'GPT-4o'},
    {'id': 'gemini-1.5-flash-latest', 'name': 'Gemini 1.5 Flash'},
    {'id': 'gemini-1.5-pro-latest', 'name': 'Gemini 1.5 Pro'},
    {'id': 'claude-3-haiku-20240307', 'name': 'Claude 3 Haiku'},
    {'id': 'claude-3-sonnet-20240229', 'name': 'Claude 3 Sonnet'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _promptController.dispose();
    super.dispose();
  }
  
  Future<void> _createBot() async {
    // Validate form using InputValidator
    bool isValid = true;
    
    setState(() {
      // Reset errors
      _nameError = null;
      _descriptionError = null;
      _promptError = null;
      
      // Validate name
      final nameValidation = InputValidator.validateMinLength(
        _nameController.text, 
        2, 
        'Bot name'
      );
      if (nameValidation != null) {
        _nameError = nameValidation;
        isValid = false;
      }
    });
    
    if (!isValid) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _botService.createBot(
        name: _nameController.text,
        description: _descriptionController.text,
        model: _selectedModel,
        prompt: _promptController.text,
      );
      
      if (!mounted) return;
      
      GlobalSnackBar.show(
        context: context,
        message: 'Bot created successfully',
        variant: SnackBarVariant.success,
      );
      
      Navigator.of(context).pop();
    } catch (e) {
      _logger.e('Error creating bot: $e');
      
      if (!mounted) return;
      
      GlobalSnackBar.show(
        context: context,
        message: 'Failed to create bot: ${e.toString()}',
        variant: SnackBarVariant.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create AI Bot'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FloatingLabelTextField(
                controller: _nameController,
                label: 'Bot Name',
                hintText: 'Enter a name for your bot',
                darkMode: isDarkMode,
                errorText: _nameError,
              ),
              const SizedBox(height: 16),
              
              StyledDropdown<String>(
                label: 'AI Model',
                hintText: 'Select an AI model',
                value: _selectedModel,
                darkMode: isDarkMode,
                prefixIcon: Icons.smart_toy,
                items: _availableModels.map((model) {
                  return DropdownMenuItem<String>(
                    value: model['id'],
                    child: Text(model['name']!),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedModel = value;
                    });
                  }
                },
                errorText: _selectedModel.isEmpty ? 'Please select an AI model' : null,
              ),
              const SizedBox(height: 16),
              
              FloatingLabelTextField(
                controller: _descriptionController,
                label: 'Description',
                hintText: 'Describe what this bot does',
                maxLines: 2,
                darkMode: isDarkMode,
                errorText: _descriptionError,
              ),
              const SizedBox(height: 16),
              
              FloatingLabelTextField(
                controller: _promptController,
                label: 'Initial Prompt',
                hintText: 'Examples:\n• You are a helpful customer service agent for a tech company...\n• You are an expert in JavaScript programming...\n• You are a travel guide that helps people plan trips to Vietnam...',
                maxLines: 8,
                keyboardType: TextInputType.multiline,
                darkMode: isDarkMode,
                errorText: _promptError,
              ),
              
              const SizedBox(height: 32),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Button(
                    label: 'Cancel',
                    onPressed: () => Navigator.of(context).pop(),
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
                  const SizedBox(width: 8),
                  Button(
                    label: 'Create',
                    onPressed: _createBot,
                    icon: Icons.add,
                    variant: ButtonVariant.primary,
                    isDarkMode: isDarkMode,
                    fullWidth: false,
                    size: ButtonSize.medium,
                    radius: ButtonRadius.small,
                    fontWeight: FontWeight.bold,
                    isLoading: _isLoading,
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
