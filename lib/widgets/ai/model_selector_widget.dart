import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/api/jarvis_api_service.dart';

class ModelSelectorWidget extends StatefulWidget {
  final String currentModel;
  final Function(String) onModelChanged;

  const ModelSelectorWidget({
    super.key,
    required this.currentModel,
    required this.onModelChanged,
  });

  @override
  State<ModelSelectorWidget> createState() => _ModelSelectorWidgetState();
}

class _ModelSelectorWidgetState extends State<ModelSelectorWidget> {
  final JarvisApiService _apiService = JarvisApiService();
  List<Map<String, String>> _availableModels = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableModels();
  }

  Future<void> _loadAvailableModels() async {
    try {
      final models = await _apiService.getAvailableModels();
      setState(() {
        _availableModels = models;
      });
    } catch (e) {
      // Fallback to default models if API call fails
      setState(() {
        _availableModels = ApiConstants.modelNames.entries.map((entry) => {
          'id': entry.key,
          'name': entry.value,
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (String modelId) {
        widget.onModelChanged(modelId);
      },
      itemBuilder: (context) {
        return _availableModels.map((model) {
          return PopupMenuItem<String>(
            value: model['id']!,
            child: Row(
              children: [
                if (model['id'] == widget.currentModel)
                  const Icon(Icons.check, size: 16, color: Colors.green),
                if (model['id'] == widget.currentModel)
                  const SizedBox(width: 8),
                Text(model['name'] ?? model['id']!),
              ],
            ),
          );
        }).toList();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getCurrentModelName(),
              style: const TextStyle(fontSize: 12),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  String _getCurrentModelName() {
    final modelName = ApiConstants.modelNames[widget.currentModel];
    if (modelName != null) {
      return modelName;
    }
    
    // Try to find the name in the available models list
    final modelInfo = _availableModels.firstWhere(
      (model) => model['id'] == widget.currentModel,
      orElse: () => {'name': 'Unknown Model'},
    );
    
    return modelInfo['name'] ?? 'Unknown Model';
  }
}
