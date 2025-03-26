import 'package:flutter/material.dart';
import '../../core/services/api/api_service.dart';

class ModelSelectorWidget extends StatelessWidget {
  final String currentModel;
  final Function(String) onModelSelected;
  final bool showDescription;
  final bool showLabel;

  const ModelSelectorWidget({
    super.key,
    required this.currentModel,
    required this.onModelSelected,
    this.showDescription = false,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onModelSelected,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showLabel) ...[
              const Text('AI Model: '),
              const SizedBox(width: 4),
            ],
            Text(
              ApiService.modelNames[currentModel] ?? currentModel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
      itemBuilder: (BuildContext context) {
        // Group models by provider
        final geminiModels = ApiService.availableModels.where(
          (model) => ApiService.modelProviders[model] == ApiService.providerGemini
        ).toList();
        
        final openaiModels = ApiService.availableModels.where(
          (model) => ApiService.modelProviders[model] == ApiService.providerOpenai
        ).toList();
        
        final grokModels = ApiService.availableModels.where(
          (model) => ApiService.modelProviders[model] == ApiService.providerGrok
        ).toList();
        
        return [
          // Gemini header
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
          // Gemini models
          ...geminiModels.map(_buildModelMenuItem),
          
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
          
          // Grok header
          const PopupMenuItem<String>(
            enabled: false,
            child: Text(
              'xAI Grok',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
          ),
          // Grok models
          ...grokModels.map(_buildModelMenuItem),
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
            ApiService.modelNames[model] ?? model,
            style: TextStyle(
              fontWeight: currentModel == model ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (showDescription && ApiService.modelDescriptions.containsKey(model))
            Text(
              ApiService.modelDescriptions[model]!,
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
