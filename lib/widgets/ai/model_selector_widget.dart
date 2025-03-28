import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';

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
    return PopupMenuButton<String>(
      tooltip: 'Select AI Model',
      icon: const Icon(Icons.auto_awesome),
      onSelected: onModelChanged,
      itemBuilder: (context) {
        return ApiConstants.modelNames.entries.map((entry) {
          final modelId = entry.key;
          final modelName = entry.value;
          return PopupMenuItem<String>(
            value: modelId,
            child: Row(
              children: [
                Icon(
                  modelId == currentModel 
                      ? Icons.check_circle
                      : Icons.circle_outlined,
                  color: modelId == currentModel 
                      ? Theme.of(context).primaryColor
                      : Colors.grey,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(modelName),
              ],
            ),
          );
        }).toList();
      },
    );
  }
}
