import 'dart:math';
import 'package:flutter/foundation.dart' show debugPrint;

/// Utility class for formatting various data types
class FormatUtils {
  // Prevent instantiation
  FormatUtils._();
}

/// Format bytes into a human-readable string (KB, MB, GB, etc.)
String formatBytes(int? bytes, {int decimals = 1}) {
  if (bytes == null || bytes <= 0) return '0 B';
  
  const suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
  final i = (log(bytes) / log(1024)).floor();
  
  // If less than 1 KB, show in bytes with no decimal places
  if (i == 0) return '$bytes ${suffixes[i]}';
  
  // Otherwise show with the specified number of decimal places
  return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
}

/// Format a DateTime object as a readable string
String formatDate(DateTime date) {
  // Format: Feb 15, 2023
  final month = _getShortMonthName(date.month);
  return '$month ${date.day}, ${date.year}';
}

/// Format a DateTime object with time as a readable string
String formatDateTime(DateTime dateTime) {
  // Format: Feb 15, 2023, 14:30
  final month = _getShortMonthName(dateTime.month);
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$month ${dateTime.day}, ${dateTime.year}, $hour:$minute';
}

/// Convert a boolean value to a standardized string representation
String formatBooleanStatus(dynamic value, {String trueValue = 'active', String falseValue = 'inactive', String defaultValue = 'pending'}) {
  if (value == null) {
    debugPrint('formatBooleanStatus: input is null, returning "$defaultValue"');
    return defaultValue;
  }
  
  if (value is bool) {
    final result = value ? trueValue : falseValue;
    debugPrint('formatBooleanStatus: converted boolean $value to string "$result"');
    return result;
  } else if (value is String) {
    // If it's already a string, return it as is
    debugPrint('formatBooleanStatus: input is already a string: "$value"');
    return value;
  } else {
    // For any other type, convert to string
    final result = value.toString();
    debugPrint('formatBooleanStatus: converted ${value.runtimeType} to string: "$result"');
    return result;
  }
}

/// Get the short name of the month
String _getShortMonthName(int month) {
  const monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  
  if (month < 1 || month > 12) {
    return '';
  }
  
  return monthNames[month - 1];
}
