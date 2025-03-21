import 'dart:io';
import 'package:logger/logger.dart';

final Logger _logger = Logger();

void main() {
  _logger.i('Checking platform compatibility...');
  
  // Check if running on Windows
  if (Platform.isWindows) {
    _logger.i('Windows platform detected. Setting appropriate build flags...');
    
    // Create a file that can be used by build scripts to modify compilation
    File('windows/is_windows_platform.txt').writeAsStringSync('true');
    
    _logger.i('Created flag file for Windows-specific build settings');
    _logger.i('Firebase Auth will be disabled for Windows builds');
  } else {
    _logger.i('Non-Windows platform detected. No special configuration needed.');
  }
}
