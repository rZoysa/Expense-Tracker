import 'package:flutter/material.dart';

class AnimatedExtendedFab extends StatefulWidget {
  const AnimatedExtendedFab({
    required this.heroTag,
    required this.isExtended,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.tooltip,
    super.key,
  });

  final Object heroTag;
  final bool isExtended;
  final VoidCallback onPressed;
  final Widget icon;
  final Widget label;
  final String? tooltip;

  @override
  State<AnimatedExtendedFab> createState() => _AnimatedExtendedFabState();
}

class _AnimatedExtendedFabState extends State<AnimatedExtendedFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 240),
      value: widget.isExtended ? 1 : 0,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedExtendedFab oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isExtended == widget.isExtended) {
      return;
    }

    if (widget.isExtended) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final progress = _animation.value;

        return FloatingActionButton.extended(
          heroTag: widget.heroTag,
          // Keep the FAB in extended layout mode and animate the label width
          // ourselves. This produces a smooth transition in both directions.
          isExtended: true,
          tooltip: widget.tooltip,
          onPressed: widget.onPressed,
          icon: widget.icon,
          extendedIconLabelSpacing: 8 * progress,
          extendedPadding: EdgeInsetsDirectional.only(
            start: 16,
            end: 16 + (4 * progress),
          ),
          label: ClipRect(
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Opacity(opacity: progress, child: widget.label),
            ),
          ),
        );
      },
    );
  }
}
