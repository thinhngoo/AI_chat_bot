import 'package:flutter/material.dart';
import '../../core/services/api/api_service.dart';

class ModelSelectorWidget extends StatelessWidget {
  final String currentModel;
  final Function(String) onModelChanged;

  const ModelSelectorWidget({
    super.key,
    required this.currentModel,
    required this.onModelChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Get available models from API service
    final ApiService apiService = ApiService();
    final models = apiService.getAvailableModels();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentModel,
          icon: const Icon(Icons.arrow_drop_down),
          elevation: 16,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          items: models.map<DropdownMenuItem<String>>((Map<String, String> model) {
            return DropdownMenuItem<String>(
              value: model['id'],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome, size: 16),
                  const SizedBox(width: 8),
                  Text(model['name'] ?? 'Unknown Model'),
                ],
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              onModelChanged(newValue);
            }
          },
        ),
      ),
    );
  }
}
