import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A typing indicator widget that shows animated dots
/// to indicate the other person is typing
class TypingIndicator extends StatefulWidget {
  final bool isTyping;
  
  /// Creates a typing indicator
  ///
  /// [isTyping] determines whether the typing animation is active
  const TypingIndicator({
    super.key,
    required this.isTyping,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with TickerProviderStateMixin {
  late AnimationController _appearanceController;
  late Animation<double> _indicatorSpaceAnimation;
  
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    
    _appearanceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _indicatorSpaceAnimation = CurvedAnimation(
      parent: _appearanceController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ).drive(Tween<double>(begin: 0.0, end: 1.0));
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    if (widget.isTyping) {
      _appearanceController.forward();
      _controller.repeat(reverse: true);
    }
  }
  
  @override
  void didUpdateWidget(TypingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isTyping != oldWidget.isTyping) {
      if (widget.isTyping) {
        _appearanceController.forward();
        _controller.repeat(reverse: true);
      } else {
        _appearanceController.reverse();
        _controller.reset();
      }
    }
  }
  
  @override
  void dispose() {
    _appearanceController.dispose();
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;
    
    Color dotColor = isDarkTheme 
        ? Colors.white.withAlpha(204) 
        : Colors.black.withAlpha(204);
    
    return SizeTransition(
      sizeFactor: _indicatorSpaceAnimation,
      axisAlignment: -1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: isDarkTheme
                ? Colors.grey[800]?.withValues(alpha: 64)
                : Colors.grey[200]?.withValues(alpha: 64),
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  // Calculate a delay for each dot
                  final delay = index * 0.2;
                  
                  // Use the controller's value to calculate opacity and scale
                  final progress = _calculateProgress(delay);
                  final opacity = _calculateOpacity(progress);
                  final scale = _calculateScale(progress);
                  
                  return Transform.scale(
                    scale: scale,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          width: 8.0,
                          height: 8.0,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ),
    );
  }
  
  // Calculate wave progress for each dot, offset by delay
  double _calculateProgress(double delay) {
    final relativeValue = (_controller.value - delay) % 1.0;
    return relativeValue < 0.0 ? relativeValue + 1.0 : relativeValue;
  }
  
  // Map progress to opacity value
  double _calculateOpacity(double progress) {
    if (progress < 0.5) {
      return 0.5 + progress;
    } else {
      return 1.5 - progress; 
    }
  }
  
  // Map progress to scale value
  double _calculateScale(double progress) {
    return 0.5 + (progress * 0.5);
  }
}
