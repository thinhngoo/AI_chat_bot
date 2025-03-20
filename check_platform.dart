// This script checks if running on Windows and sets up appropriate build flags
import 'dart:io';

void main() {
  // Check if running on Windows
  if (Platform.isWindows) {
    print('Windows platform detected. Setting appropriate build flags...');
    
    // Create a file that can be used by build scripts to modify compilation
    File('windows/is_windows_platform.txt').writeAsStringSync('true');
    
    print('Created flag file for Windows-specific build settings');
    print('Firebase Auth will be disabled for Windows builds');
  } else {
    print('Non-Windows platform detected. No special configuration needed.');
  }
}
