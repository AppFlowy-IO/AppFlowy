import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:flowy_infra/time/duration.dart';

typedef HoverBuilder = Widget Function(BuildContext context, bool onHover);

class StyledHover extends StatefulWidget {
  final HoverDisplayConfig config;
  final HoverBuilder builder;

  const StyledHover({
    Key? key,
    required this.builder,
    this.config = const HoverDisplayConfig(),
  }) : super(key: key);

  @override
  State<StyledHover> createState() => _StyledHoverState();
}

class _StyledHoverState extends State<StyledHover> {
  bool _onHover = false;

  @override
  Widget build(BuildContext context) {
    final hoverColor = _onHover
        ? widget.config.hoverColor
        : Theme.of(context).colorScheme.background;
    final config = widget.config.copyWith(hoverColor: hoverColor);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (p) => setOnHover(true),
      onExit: (p) => setOnHover(false),
      child: HoverBackground(
          config: config, child: widget.builder(context, _onHover)),
    );
  }

  void setOnHover(bool value) => setState(() => _onHover = value);
}

class HoverDisplayConfig {
  final Color borderColor;
  final double borderWidth;
  final Color? hoverColor;
  final BorderRadius borderRadius;

  const HoverDisplayConfig(
      {this.borderColor = Colors.transparent,
      this.borderWidth = 0,
      this.borderRadius = const BorderRadius.all(Radius.circular(8)),
      this.hoverColor});

  HoverDisplayConfig copyWith({Color? hoverColor}) {
    return HoverDisplayConfig(
        borderColor: borderColor,
        borderWidth: borderWidth,
        borderRadius: borderRadius,
        hoverColor: hoverColor);
  }
}

class HoverBackground extends StatelessWidget {
  final HoverDisplayConfig config;

  final Widget child;

  const HoverBackground({
    Key? key,
    required this.child,
    this.config = const HoverDisplayConfig(),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = config.hoverColor ?? Theme.of(context).colorScheme.background;
    final hoverBorder = Border.all(
      color: config.borderColor,
      width: config.borderWidth,
    );

    return Container(
      decoration: BoxDecoration(
        border: hoverBorder,
        color: color,
        borderRadius: config.borderRadius,
      ),
      child: child,
    );
  }
}
