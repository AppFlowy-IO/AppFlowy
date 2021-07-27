import 'package:flutter/material.dart';
import 'package:flowy_infra/time/duration.dart';

typedef HoverBuilder = Widget Function(BuildContext context, bool onHover);

class StyledHover extends StatefulWidget {
  final Color color;
  final Color borderColor;
  final double borderWidth;
  final BorderRadius borderRadius;
  final HoverBuilder builder;

  const StyledHover({
    Key? key,
    required this.color,
    this.borderColor = Colors.transparent,
    this.borderWidth = 0,
    this.borderRadius = BorderRadius.zero,
    required this.builder,
  }) : super(key: key);

  @override
  State<StyledHover> createState() => _StyledHoverState();
}

class _StyledHoverState extends State<StyledHover> {
  bool _onHover = false;

  @override
  Widget build(BuildContext context) {
    final hoverColor =
        _onHover ? widget.color : Theme.of(context).colorScheme.background;

    final hoverBorder = Border.all(
      color: widget.borderColor,
      width: widget.borderWidth,
    );

    final animatedDuration = .1.seconds;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (p) => setOnHover(true),
      onExit: (p) => setOnHover(false),
      child: AnimatedContainer(
        decoration: BoxDecoration(
          border: hoverBorder,
          color: hoverColor,
          borderRadius: widget.borderRadius,
        ),
        duration: animatedDuration,
        child: widget.builder(context, _onHover),
      ),
    );
  }

  void setOnHover(bool value) => setState(() => _onHover = value);
}
