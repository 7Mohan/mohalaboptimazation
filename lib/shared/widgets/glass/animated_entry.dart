import 'package:flutter/material.dart';

/// A smooth, staggered fade and slide-up entrance animation.
///
/// Designed to introduce cards, charts, and metrics sequentially without visual clutter.
class AnimatedEntry extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double verticalOffset;
  final Curve curve;

  const AnimatedEntry({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 320),
    this.verticalOffset = 18.0,
    this.curve = Curves.easeOutCubic,
  });

  /// Stagger helper where [index] multiplies a base step duration.
  factory AnimatedEntry.staggered({
    Key? key,
    required int index,
    required Widget child,
    Duration step = const Duration(milliseconds: 45),
    Duration duration = const Duration(milliseconds: 320),
    double verticalOffset = 18.0,
    Curve curve = Curves.easeOutCubic,
  }) {
    return AnimatedEntry(
      key: key,
      delay: step * index,
      duration: duration,
      verticalOffset: verticalOffset,
      curve: curve,
      child: child,
    );
  }

  @override
  State<AnimatedEntry> createState() => _AnimatedEntryState();
}

class _AnimatedEntryState extends State<AnimatedEntry> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, widget.verticalOffset / 100),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
