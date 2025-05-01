import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Background with synthwave grid and gradient overlay for auth screens
class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final AppColors colors = AppColors.dark;

    return Scaffold(
      backgroundColor: colors.background,
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background grid image
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/synthwave.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Gradient overlay for better visibility
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colors.background.withAlpha(179), // 0.7 opacity
                    colors.background.withAlpha(128), // 0.5 opacity
                  ],
                ),
              ),
            ),
            // Content
            SafeArea(child: child),
          ],
        ),
      ),
    );
  }
}
