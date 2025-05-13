import 'package:flutter/material.dart';

/// Constants for prompt categories seen in the UI
class CategoryConstants {
  // Available categories (from the image)
  static const List<String> categories = [
    'business',
    'career',
    'chatbot',
    'coding',
    'education',
    'fun',
    'marketing',
    'productivity',
    'seo',
    'writing',
    'other',
  ];

  // Get icon for a category
  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'business':
        return Icons.business;
      case 'career':
        return Icons.work;
      case 'chatbot':
        return Icons.chat;
      case 'coding':
        return Icons.code;
      case 'education':
        return Icons.school;
      case 'fun':
        return Icons.emoji_emotions;
      case 'marketing':
        return Icons.campaign;
      case 'productivity':
        return Icons.schedule;
      case 'seo':
        return Icons.trending_up;
      case 'writing':
        return Icons.edit_document;
      case 'other':
      default:
        return Icons.category;
    }
  }

  // Get color for a category
  static Color getCategoryColor(String category, {bool darkMode = false}) {
    final baseColors = {
      'business': Colors.blue,
      'career': Colors.amber,
      'chatbot': Colors.teal,
      'coding': Colors.indigo,
      'education': Colors.green,
      'fun': Colors.orange,
      'marketing': Colors.purple,
      'productivity': Colors.cyan,
      'seo': Colors.deepOrange,
      'writing': Colors.lightBlue,
      'other': Colors.grey,
    };

    final color = baseColors[category.toLowerCase()] ?? Colors.grey;
    return darkMode ? color.shade300 : color.shade700;
  }
} 