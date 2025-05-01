import 'package:flutter/material.dart';
// Commented out to fix build issues
// import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'core/services/auth/auth_service.dart';
import 'core/constants/app_colors.dart';
import 'features/auth/presentation/auth_check_screen.dart';
import 'features/subscription/services/ad_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the auth service
  await AuthService().initializeService();

  // Initialize MobileAds - Commented out to fix build issues
  // await MobileAds.instance.initialize();

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

  void toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Chat Bot',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(isDark: _isDarkMode),
      initialRoute: '/',
      routes: {
        '/': (context) =>
            AuthCheckScreen(toggleTheme: toggleTheme, isDarkMode: _isDarkMode),
      },
    );
  }

  ThemeData _buildTheme({required bool isDark}) {
    final AppColors colors = isDark ? AppColors.dark : AppColors.light;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,

      // Card theme
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(width: 2),
        ),
        filled: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        ),
      ),

      // Dialog theme
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // Snackbar theme
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),

      // App bar theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Scaffold background color and color scheme
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
