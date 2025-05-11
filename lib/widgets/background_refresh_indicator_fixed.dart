import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// A small indicator widget that shows a rotating refresh icon when
/// a background data refresh is happening
class BackgroundRefreshIndicator extends StatefulWidget {
  final bool isRefreshing;
  final Color? color;
  final double size;
  
  const BackgroundRefreshIndicator({
    super.key,
    required this.isRefreshing,
    this.color,
    this.size = 14,
  });

  @override
  State<BackgroundRefreshIndicator> createState() => _BackgroundRefreshIndicatorState();
}

class _BackgroundRefreshIndicatorState extends State<BackgroundRefreshIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    
    if (widget.isRefreshing) {
      _controller.repeat();
    }
  }
  
  @override
  void didUpdateWidget(BackgroundRefreshIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isRefreshing != oldWidget.isRefreshing) {
      if (widget.isRefreshing) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (!widget.isRefreshing) return const SizedBox.shrink();
    
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final colors = isDarkMode ? AppColors.dark : AppColors.light;
    
    return AnimatedOpacity(
      opacity: widget.isRefreshing ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: RotationTransition(
        turns: _controller,
        child: Icon(
          Icons.refresh,
          size: widget.size,
          color: widget.color ?? colors.muted,
        ),
      ),
    );
  }
}

/// A stream-based version of the background refresh indicator that subscribes
/// to a stream of boolean values indicating whether a refresh is in progress
class StreamBackgroundRefreshIndicator extends StatelessWidget {
  final Stream<bool> refreshStream;
  final Color? color;
  final double size;
  
  const StreamBackgroundRefreshIndicator({
    super.key,
    required this.refreshStream,
    this.color,
    this.size = 14,
  });
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: refreshStream,
      initialData: false,
      builder: (context, snapshot) {
        return BackgroundRefreshIndicator(
          isRefreshing: snapshot.data ?? false,
          color: color,
          size: size,
        );
      },
    );
  }
}
