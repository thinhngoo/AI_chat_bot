import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../../core/utils/validators/input_validator.dart';
import '../services/bot_service.dart';

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
    if (!_formKey.currentState!.validate()) return;
    
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
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bot created successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.of(context).pop();
    } catch (e) {
      _logger.e('Error creating bot: $e');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create bot: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create AI Bot'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Bot Name',
                  hintText: 'Enter a name for your bot',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => InputValidator.validateRequired(value, 'bot name'),
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _selectedModel,
                decoration: const InputDecoration(
                  labelText: 'AI Model',
                  border: OutlineInputBorder(),
                ),
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select an AI model';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe what this bot does',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (value) => InputValidator.validateRequired(value, 'description'),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _promptController,
                decoration: const InputDecoration(
                  labelText: 'Initial Prompt',
                  hintText: 'Enter instructions for the bot',
                  border: OutlineInputBorder(),
                ),
                maxLines: 6,
                validator: (value) => InputValidator.validateRequired(value, 'initial prompt'),
              ),
              const SizedBox(height: 32),
              
              Card(
                color: Colors.teal.withAlpha(26),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Prompt Examples:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• You are a helpful customer service agent for a tech company...',
                      ),
                      Text(
                        '• You are an expert in JavaScript programming...',
                      ),
                      Text(
                        '• You are a travel guide that helps people plan trips to Vietnam...',
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _createBot,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Create Bot',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
