import 'package:flutter/material.dart';
import 'core/constants/app_colors.dart';
import 'features/splash/splash_screen.dart';
import 'features/subscription/services/ad_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize AdManager
  await AdManager().initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;
  static const String _isDarkModeKey = 'is_dark_mode';

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDarkMode = prefs.getBool(_isDarkModeKey);

      // If there's a saved preference, use it
      if (savedDarkMode != null) {
        setState(() {
          _isDarkMode = savedDarkMode;
        });
      } else {
        // Otherwise, use the device preference
        final brightness =
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
        setState(() {
          _isDarkMode = brightness == Brightness.dark;
        });
      }
    } catch (e) {
      // If there's an error, default to system preference
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      setState(() {
        _isDarkMode = brightness == Brightness.dark;
      });
    }
  }

  Future<void> _saveThemePreference(bool isDark) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isDarkModeKey, isDark);
    } catch (e) {
      // Silently handle error
    }
  }

  void toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
      _saveThemePreference(_isDarkMode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Chat Bot',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(isDark: _isDarkMode),
      home: SplashScreen(toggleTheme: toggleTheme),
    );
  }

  ThemeData _buildTheme({required bool isDark}) {
    final AppColors colors = isDark ? AppColors.dark : AppColors.light;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: colors.background,

      // Card theme
      cardTheme: CardTheme(
        elevation: 2,
        color: colors.card,
        surfaceTintColor: colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            width: 1,
          ),
        ),
        // enabledBorder: OutlineInputBorder(
        //   borderRadius: BorderRadius.circular(12),
        //   borderSide: BorderSide(
        //     width: 1,
        //   ),
        // ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            width: 1,
          ),
        ),
        filled: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: colors.button,
          foregroundColor: colors.buttonForeground,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.border),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
      ),

      // Dialog theme
      dialogTheme: DialogTheme(
        backgroundColor: colors.card,
        surfaceTintColor: colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: colors.cardForeground,
        ),
        contentTextStyle: TextStyle(
          fontSize: 16,
          color: colors.cardForeground,
        ),
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: colors.card,
        labelStyle: TextStyle(color: colors.cardForeground),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.card,
        contentTextStyle: TextStyle(color: colors.cardForeground),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colors.border),
        ),
      ),

      // App bar theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: colors.background,
        foregroundColor: colors.foreground,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: colors.foreground,
        ),
      ),

      fontFamily: 'Inter',

      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: colors.foreground,
        ),
        displayMedium: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: colors.foreground,
          fontFamily: 'Geist',
        ),
        displaySmall: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: colors.foreground,
          fontFamily: 'Geist',
        ),
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: colors.foreground,
          fontFamily: 'Geist',
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: colors.foreground,
          fontFamily: 'Geist',
        ),
        headlineSmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: colors.foreground,
          fontFamily: 'Geist',
        ),
        titleLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: colors.foreground,
          fontFamily: 'Geist',
        ),
        titleMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: colors.foreground,
          fontFamily: 'Geist',
        ),
        titleSmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: colors.foreground,
          fontFamily: 'Geist',
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: colors.foreground,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: colors.foreground,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: colors.foreground,
        ),
      ),

      dividerColor: colors.border,
      colorScheme: isDark
          ? ColorScheme.dark(
              primary: colors.primary,
              onPrimary: colors.primaryForeground,
              secondary: colors.secondary,
              onSecondary: colors.secondaryForeground,
              surface: colors.card,
              onSurface: colors.cardForeground,
              surfaceTint: colors.background,
              error: colors.error,
              onError: colors.errorForeground,
            )
          : ColorScheme.light(
              primary: colors.primary,
              onPrimary: colors.primaryForeground,
              secondary: colors.secondary,
              onSecondary: colors.secondaryForeground,
              surface: colors.card,
              onSurface: colors.cardForeground,
              surfaceTint: colors.background,
              error: colors.error,
              onError: colors.errorForeground,
            ),
    );
  }
}
