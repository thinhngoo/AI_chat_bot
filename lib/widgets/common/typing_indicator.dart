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
  
  late List<AnimationController> _dotControllers;
  
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
    
    _dotControllers = List.generate(
      3,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );
    
    // Start dot animations with staggered delays
    for (int i = 0; i < _dotControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted && widget.isTyping) {
          _dotControllers[i].repeat(reverse: true);
        }
      });
    }
    
    if (widget.isTyping) {
      _appearanceController.forward();
    }
  }
  
  @override
  void didUpdateWidget(TypingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isTyping != oldWidget.isTyping) {
      if (widget.isTyping) {
        _appearanceController.forward();
        
        for (int i = 0; i < _dotControllers.length; i++) {
          Future.delayed(Duration(milliseconds: i * 200), () {
            if (mounted && widget.isTyping) {
              _dotControllers[i].repeat(reverse: true);
            }
          });
        }
      } else {
        _appearanceController.reverse();
        for (final controller in _dotControllers) {
          controller.reset();
        }
      }
    }
  }
  
  @override
  void dispose() {
    _appearanceController.dispose();
    for (final controller in _dotControllers) {
      controller.dispose();
    }
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return SizeTransition(
      sizeFactor: _indicatorSpaceAnimation,
      axisAlignment: -1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.grey[800]?.withOpacity(0.25)
                : Colors.grey[200]?.withOpacity(0.25),
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++)
                AnimatedBuilder(
                  animation: _dotControllers[i],
                  builder: (context, child) {
                    final bounceValue = math.sin(_dotControllers[i].value * math.pi);
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2.0),
                      height: 8.0 + bounceValue * 4.0,
                      width: 8.0 + bounceValue * 4.0,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.6 + (0.4 * bounceValue)),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
