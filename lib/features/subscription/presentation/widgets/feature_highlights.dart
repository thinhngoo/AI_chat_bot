import 'package:flutter/material.dart';

class FeatureHighlights extends StatelessWidget {
  final List<String> features;
  
  const FeatureHighlights({
    super.key,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    // Split features into two columns
    final int halfLength = (features.length / 2).ceil();
    final firstColumn = features.sublist(0, halfLength);
    final secondColumn = features.sublist(halfLength);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Features Include:',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // First column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: firstColumn.map((feature) => _buildFeatureItem(feature, context)).toList(),
                ),
              ),
              const SizedBox(width: 16),
              // Second column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: secondColumn.map((feature) => _buildFeatureItem(feature, context)).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String feature, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              feature,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}