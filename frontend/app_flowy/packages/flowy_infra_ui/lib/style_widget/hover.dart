import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:flowy_infra/time/duration.dart';

typedef HoverBuilder = Widget Function(BuildContext context, bool onHover);

class FlowyHover extends StatefulWidget {
  final HoverStyle style;
  final HoverBuilder builder;
  final bool Function()? setSelected;

  const FlowyHover({
    Key? key,
    required this.builder,
    required this.style,
    this.setSelected,
  }) : super(key: key);

  @override
  State<FlowyHover> createState() => _FlowyHoverState();
}

class _FlowyHoverState extends State<FlowyHover> {
  bool _onHover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (p) => setState(() => _onHover = true),
      onExit: (p) => setState(() => _onHover = false),
      child: render(),
    );
  }

  Widget render() {
    var showHover = _onHover;
    if (!showHover && widget.setSelected != null) {
      showHover = widget.setSelected!();
    }

    if (showHover) {
      return FlowyHoverContainer(
        style: widget.style,
        child: widget.builder(context, _onHover),
      );
    } else {
      return widget.builder(context, _onHover);
    }
  }
}

class HoverStyle {
  final Color borderColor;
  final double borderWidth;
  final Color hoverColor;
  final BorderRadius borderRadius;
  final EdgeInsets contentMargin;

  const HoverStyle(
      {this.borderColor = Colors.transparent,
      this.borderWidth = 0,
      this.borderRadius = const BorderRadius.all(Radius.circular(6)),
      this.contentMargin = EdgeInsets.zero,
      required this.hoverColor});
}

class FlowyHoverContainer extends StatelessWidget {
  final HoverStyle style;
  final Widget child;

  const FlowyHoverContainer({
    Key? key,
    required this.child,
    required this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hoverBorder = Border.all(
      color: style.borderColor,
      width: style.borderWidth,
    );

    return Container(
      margin: style.contentMargin,
      decoration: BoxDecoration(
        border: hoverBorder,
        color: style.hoverColor,
        borderRadius: style.borderRadius,
      ),
      child: child,
    );
  }
}
