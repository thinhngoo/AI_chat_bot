import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'dart:async';

class AppTitleWithDescription extends StatefulWidget {
  final String title;
  final String description;
  
  const AppTitleWithDescription({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  State<AppTitleWithDescription> createState() => _AppTitleWithDescriptionState();
}

class _AppTitleWithDescriptionState extends State<AppTitleWithDescription> {
  bool _showCursor = true;
  late Timer _cursorTimer;

  @override
  void initState() {
    super.initState();
    // Start blinking cursor timer
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      setState(() {
        _showCursor = !_showCursor;
      });
    });
  }

  @override
  void dispose() {
    _cursorTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.dark;
    
    return Column(
      children: [
        // App title
        Text(
          widget.title,
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            fontFamily: 'monospace',
            wordSpacing: -4,
            color: colors.foreground,
          ),
        ),

        const SizedBox(height: 6),

        // Description
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colors.muted,
                fontFamily: 'monospace',
              ),
            ),
            SizedBox(
              width: 12,
              child: Text(
                _showCursor ? '_' : ' ',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colors.muted,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
} 