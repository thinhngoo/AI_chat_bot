import 'package:flutter/material.dart';
import '../../core/services/chat/jarvis_chat_service.dart';
import '../../core/services/auth/auth_service.dart';
import 'package:logger/logger.dart';

class ModelSelectorWidget extends StatefulWidget {
  final String currentModel;
  final Function(String) onModelChanged;
  final bool isLoading;
  
  const ModelSelectorWidget({
    super.key, 
    required this.currentModel, 
    required this.onModelChanged,
    this.isLoading = false,
  });

  @override
  ModelSelectorWidgetState createState() => ModelSelectorWidgetState();
}

class ModelSelectorWidgetState extends State<ModelSelectorWidget> {
  final JarvisChatService _chatService = JarvisChatService();
  final AuthService _authService = AuthService();
  final Logger _logger = Logger();
  
  late String _selectedModel;
  
  // Model data - hardcoded for now, should ideally come from the API
  final Map<String, String> _modelNames = {
    'gemini-2.0-flash': 'Gemini 2.0 Flash',
    'gemini-2.0-pro': 'Gemini 2.0 Pro',
    'claude-3-5-sonnet': 'Claude 3.5 Sonnet',
    'gpt-4o': 'GPT-4o',
  };
  
  final Map<String, String> _modelDescriptions = {
    'gemini-2.0-flash': 'Fast responses, good for chat',
    'gemini-2.0-pro': 'More powerful, handles complex tasks',
    'claude-3-5-sonnet': 'Balanced performance and speed',
    'gpt-4o': 'Advanced reasoning capabilities',
  };
  
  final Map<String, String> _modelProviders = {
    'gemini-2.0-flash': 'google',
    'gemini-2.0-pro': 'google',
    'claude-3-5-sonnet': 'anthropic',
    'gpt-4o': 'openai',
  };
  
  @override
  void initState() {
    super.initState();
    _selectedModel = widget.currentModel;
  }
  
  @override
  void didUpdateWidget(ModelSelectorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentModel != widget.currentModel) {
      _selectedModel = widget.currentModel;
    }
  }
  
  Future<void> _updateUserModel(String model) async {
    if (model == _selectedModel) return;
    
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final userId = currentUser is String ? currentUser : currentUser.uid;
        final success = await _chatService.updateUserSelectedModel(userId, model);
        
        if (success) {
          setState(() {
            _selectedModel = model;
          });
          
          widget.onModelChanged(model);
        }
      }
    } catch (e) {
      _logger.e('Error updating user model: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: _updateUserModel,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('AI Model: '),
            const SizedBox(width: 4),
            Text(
              _modelNames[_selectedModel] ?? _selectedModel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
      itemBuilder: (BuildContext context) {
        // Group models by provider
        final googleModels = _modelNames.keys.where(
          (model) => _modelProviders[model] == 'google'
        ).toList();
        
        final openaiModels = _modelNames.keys.where(
          (model) => _modelProviders[model] == 'openai'
        ).toList();
        
        final anthropicModels = _modelNames.keys.where(
          (model) => _modelProviders[model] == 'anthropic'
        ).toList();
        
        return [
          // Google header
          const PopupMenuItem<String>(
            enabled: false,
            child: Text(
              'Google Gemini',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          // Google models
          ...googleModels.map(_buildModelMenuItem),
          
          // Divider
          const PopupMenuDivider(),
          
          // OpenAI header
          const PopupMenuItem<String>(
            enabled: false,
            child: Text(
              'OpenAI ChatGPT',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
          // OpenAI models
          ...openaiModels.map(_buildModelMenuItem),
          
          // Divider
          const PopupMenuDivider(),
          
          // Anthropic header
          const PopupMenuItem<String>(
            enabled: false,
            child: Text(
              'Anthropic Claude',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
          ),
          // Anthropic models
          ...anthropicModels.map(_buildModelMenuItem),
        ];
      },
    );
  }
  
  PopupMenuItem<String> _buildModelMenuItem(String model) {
    return PopupMenuItem<String>(
      value: model,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _modelNames[model] ?? model,
            style: TextStyle(
              fontWeight: _selectedModel == model ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (_modelDescriptions.containsKey(model))
            Text(
              _modelDescriptions[model]!,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
        ],
      ),
    );
  }
}
