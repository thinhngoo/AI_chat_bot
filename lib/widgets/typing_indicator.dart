import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  final bool isTyping;

  const TypingIndicator({
    super.key,
    required this.isTyping,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _appearanceController;
  late Animation<double> _indicatorSpaceAnimation;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _appearanceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
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
    return SizeTransition(
      sizeFactor: _indicatorSpaceAnimation,
      axisAlignment: -1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                // Calculate a delay for each dot
                final delay = index * 0.2;

                // Use the controller's value to calculate opacity and scale
                final value = _calculateAnimationValue(delay);

                return Transform.scale(
                  scale: 0.8 + (value * 0.4),
                  child: Opacity(
                    opacity: 0.4 + (value * 0.6),
                    child: Container(
                      width: 12.0,
                      height: 8.0,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(204),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }

  double _calculateAnimationValue(double delay) {
    // Calculate a value between 0 and 1 for each dot based on the delay
    final progress = _controller.value;
    final value = (progress - delay) % 1.0;

    // Ensure the value is between 0 and 1
    return value < 0 ? value + 1.0 : value;
  }
}
