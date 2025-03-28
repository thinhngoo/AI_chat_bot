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
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.model_training),
          const SizedBox(width: 4),
          Text(
            ApiConstants.modelNames[currentModel] ?? 'Unknown Model',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
      tooltip: 'Select AI Model',
      onSelected: onModelChanged,
      itemBuilder: (context) {
        return ApiConstants.modelNames.entries.map((entry) {
          return PopupMenuItem<String>(
            value: entry.key,
            child: Row(
              children: [
                Icon(
                  Icons.check,
                  color: currentModel == entry.key ? Colors.blue : Colors.transparent,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(entry.value),
              ],
            ),
          );
        }).toList();
      },
    );
  }
}
